import 'dart:async';
import 'dart:io';

import 'package:penv/penv.dart';
import 'tl.dart' as t;
import 'mtp.dart' as tg;

import 'auth.dart';
import 'chats.dart';
import 'contacts.dart';
import 'exceptions.dart';
import 'members.dart';
import 'messages.dart';
import 'models.dart';
import 'peer_cache.dart';
import 'session.dart';
import 'transport.dart';
import 'updates.dart';

/// The `ptgc` package version, sent to Telegram as this client's app
/// version during the handshake.
const String packageVersion = '1.0.0';

/// A logged-in Telegram **user** connection (MTProto), as opposed to a bot.
///
/// This is the entry point to the whole package. Typical use:
///
/// ```dart
/// final client = TelegramClient.fromEnv();
/// await client.connect();
///
/// if (!client.isSignedIn) {
///   final sent = await client.auth.sendCode('+15551234567');
///   final result = await client.auth.signIn(code: '12345'); // from Telegram
///   if (result.status == SignInStatus.passwordRequired) {
///     await client.auth.checkPassword('your 2FA password');
///   }
/// }
///
/// await client.members.ban(chatId, userId); // control a user
/// await client.disconnect();
/// ```
///
/// Grouped functionality lives on [auth], [members], [contacts], [chats],
/// and [messages]. Anything not wrapped yet is reachable through [invoke]
/// with a raw `t.TlMethod` from the `tl` library.
class TelegramClient {
  TelegramClient({
    required this.apiId,
    required this.apiHash,
    SessionStore? sessionStore,
    List<DataCenter>? bootstrapDataCenters,
  })  : sessionStore = sessionStore ?? const FileSessionStore(),
        _dataCenters = List.of(bootstrapDataCenters ?? defaultDataCenters) {
    auth = AuthNamespace(this);
    members = Members(this);
    contacts = Contacts(this);
    chats = Chats(this);
    messages = Messages(this);
  }

  /// Reads `API_ID` and `API_HASH` (and gives you an easy place to keep
  /// `PHONE_NUMBER`) from a `.env`-style file — see the package README for
  /// how to obtain these from https://my.telegram.org.
  factory TelegramClient.fromEnv({
    String envFile = '.env',
    SessionStore? sessionStore,
  }) {
    final env = penvload(envFile);
    final rawApiId = env['API_ID'];
    final apiHash = env['API_HASH'];
    if (rawApiId == null || apiHash == null) {
      throw StateError(
        'Missing API_ID / API_HASH in $envFile. Get them from '
        'https://my.telegram.org/apps and see the ptgc README for setup.',
      );
    }
    final int apiId;
    apiId = int.parse(rawApiId.toString());
    return TelegramClient(
      apiId: apiId,
      apiHash: apiHash,
      sessionStore: sessionStore,
    );
  }

  /// Your app's `api_id` from https://my.telegram.org/apps.
  final int apiId;

  /// Your app's `api_hash` from https://my.telegram.org/apps.
  final String apiHash;

  /// Where the session (auth key + logged-in user ID) is persisted between
  /// runs. Defaults to a `ptgc.session.json` file next to your script.
  final SessionStore sessionStore;

  List<DataCenter> _dataCenters;

  /// Resolves usernames/IDs seen so far to the access-hash-bearing objects
  /// the raw API requires. Namespace classes use this internally; exposed
  /// publicly in case you're calling [invoke] with raw methods yourself.
  final PeerCache peers = PeerCache();

  tg.Client? _rawClient;
  IoSocket? _socket;
  int _currentDcId = 2;
  StreamSubscription<t.UpdatesBase>? _updateSub;
  final StreamController<TelegramEvent> _events =
      StreamController<TelegramEvent>.broadcast();

  late final AuthNamespace auth;
  late final Members members;
  late final Contacts contacts;
  late final Chats chats;
  late final Messages messages;

  /// The underlying `tg.Client`. Use this (or [invoke]) for any raw API
  /// call `ptgc` doesn't wrap yet — every namespace under it (`.channels`,
  /// `.messages`, `.users`, ...) is generated straight from Telegram's
  /// schema. Throws [StateError] if [connect] hasn't been called yet.
  tg.Client get raw {
    final client = _rawClient;
    if (client == null) {
      throw StateError('Not connected. Call connect() first.');
    }
    return client;
  }

  /// Whether [connect] has established a connection.
  bool get isConnected => _rawClient != null;

  /// Whether a user is logged in on this connection (implies [isConnected]).
  bool get isSignedIn => peers.selfId != null;

  /// The logged-in user's ID, once known.
  int? get userId => peers.selfId;

  /// A stream of chat events (new messages, participant/admin changes) —
  /// see [TelegramEvent] and its subtypes. Only starts producing events
  /// after [connect].
  Stream<TelegramEvent> get events => _events.stream;

  /// Fetches your own account as a full [PtgcUser] — username, phone,
  /// premium status, and so on — the richer counterpart to the bare
  /// [userId] property. Throws [AuthRequiredException] if you're not
  /// signed in.
  Future<PtgcUser> whoAmI() async {
    if (!isSignedIn) throw AuthRequiredException();
    final result = await callRaw<t.Vector<t.UserBase>>(
      () => raw.users.getUsers(id: const [t.InputUserSelf()]),
    );
    if (result.items.isEmpty) throw AuthRequiredException();
    final self = result.items.first;
    peers.feed(users: [self]);
    return PtgcUser.fromRaw(self);
  }

  /// Opens the MTProto connection: reuses a saved [SessionStore] session if
  /// one exists, otherwise negotiates a fresh auth key. Does **not** log
  /// you in by itself — call [auth] methods afterwards if [isSignedIn] is
  /// still `false`.
  Future<void> connect() async {
    final session = await sessionStore.load();
    _currentDcId = session?.dcId ?? _currentDcId;
    peers.selfId = session?.userId;
    await _openConnection(reuseKey: session?.toAuthorizationKey());
  }

  /// Closes the socket. The session file is left in place, so a later
  /// [connect] picks up right where this left off.
  Future<void> disconnect() async {
    await _updateSub?.cancel();
    _updateSub = null;
    await _socket?.close();
    _socket = null;
    _rawClient = null;
  }

  Future<void> _openConnection({tg.AuthorizationKey? reuseKey}) async {
    final dc = dataCenterById(_dataCenters, _currentDcId);
    final socket = await IoSocket.connect(dc.ipAddress, dc.port);
    final obfuscation = tg.Obfuscation.random(false, dc.id);
    final idGenerator = tg.MessageIdGenerator();

    final authorizationKey =
        reuseKey ?? await tg.Client.authorize(socket, obfuscation, idGenerator);

    final client = tg.Client(
      socket: socket,
      obfuscation: obfuscation,
      authorizationKey: authorizationKey,
      idGenerator: idGenerator,
    );

    _socket = socket;
    _rawClient = client;

    await _updateSub?.cancel();
    _updateSub = client.stream.listen(_handleRawUpdate, onError: (_) {});

    // Complete the handshake and fetch config in the same round-trip. A
    // failure here isn't fatal — the bootstrap DC table still works — so
    // we swallow it rather than surfacing a confusing error this early.
    try {
      final config = await callRaw<t.ConfigBase>(
        () => client.initConnection<t.ConfigBase>(
          apiId: apiId,
          deviceModel: 'ptgc',
          systemVersion: _systemVersion(),
          appVersion: packageVersion,
          systemLangCode: 'en',
          langPack: '',
          langCode: 'en',
          query: const t.HelpGetConfig(),
        ),
      );
      if (config is t.Config) _updateDataCenters(config);
    } catch (_) {
      // Non-fatal — see comment above.
    }

    await _persistSession();
  }

  Future<void> _migrateTo(int dcId) async {
    await _updateSub?.cancel();
    await _socket?.close();
    _rawClient = null;
    _currentDcId = dcId;
    // A new DC means a new auth key — there's nothing to reuse.
    await _openConnection();
  }

  void _updateDataCenters(t.Config config) {
    final byId = <int, DataCenter>{};
    for (final option in config.dcOptions) {
      if (option is! t.DcOption) continue;
      if (option.ipv6 || option.mediaOnly || option.cdn || option.tcpoOnly)
        continue;
      // Prefer the first (primary) address seen for each DC id.
      byId.putIfAbsent(
        option.id,
        () => DataCenter(option.id, option.ipAddress, option.port),
      );
    }
    if (byId.isNotEmpty) _dataCenters = byId.values.toList();
  }

  Future<void> _persistSession() async {
    final client = _rawClient;
    if (client == null) return;
    await sessionStore.save(
      PtgcSession.fromAuthorizationKey(
        dcId: _currentDcId,
        key: client.authorizationKey,
        userId: peers.selfId,
      ),
    );
  }

  /// Call this right after a successful login (or after loading a session
  /// that already has [userId]) so the session file remembers who's
  /// signed in.
  Future<void> rememberSignedInUser(int id) async {
    peers.selfId = id;
    await _persistSession();
  }

  /// Runs [action], transparently handling Telegram's `*_MIGRATE_*`
  /// redirects (retrying once against the correct data center) and
  /// translating any remaining [t.RpcError] into a [PtgcException].
  ///
  /// This is what every `ptgc` namespace method is built on. Reach for it
  /// yourself if you're calling [raw] methods directly and want the same
  /// error handling everyone else gets.
  Future<T> callRaw<T extends t.TlObject>(
    Future<t.Result<T>> Function() action,
  ) async {
    var result = await action();
    var error = result.error;
    if (error != null && isMigrateError(error)) {
      await _migrateTo(migrateTargetDcId(error));
      result = await action();
      error = result.error;
    }
    if (error != null) throw exceptionFromRpcError(error);
    return result.result as T;
  }

  /// The low-level escape hatch: invoke any raw `t.TlMethod` (from
  /// the `tl` library) that `ptgc` doesn't have a typed wrapper for yet.
  /// Handles DC migration and error translation just like every other
  /// method in this package.
  Future<t.TlObject> invoke(t.TlMethod method) {
    return callRaw<t.TlObject>(() => raw.invoke(method));
  }

  void _handleRawUpdate(t.UpdatesBase updates) {
    switch (updates) {
      case t.Updates():
        peers.feed(users: updates.users, chats: updates.chats);
      case t.UpdatesCombined():
        peers.feed(users: updates.users, chats: updates.chats);
      default:
        break;
    }
    for (final event in eventsFromRawUpdates(updates, peers)) {
      _events.add(event);
    }
  }

  String _systemVersion() {
    try {
      return Platform.operatingSystemVersion;
    } catch (_) {
      return 'unknown';
    }
  }
}
