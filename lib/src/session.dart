import 'dart:convert';
import 'dart:io';

import 'mtp.dart' as tg;

/// Everything `ptgc` needs to reconnect without going through login again:
/// which data center the auth key was negotiated with, the auth key itself,
/// and (once known) the logged-in user's ID.
///
/// You won't normally construct this yourself — [TelegramClient.connect]
/// creates and updates it for you and hands it to your [SessionStore].
class PtgcSession {
  /// The data center this auth key belongs to. Auth keys are per-DC; you
  /// can't reuse one across data centers.
  final int dcId;

  /// The negotiated [tg.AuthorizationKey], pre-serialized to JSON so this
  /// class stays independent of `tg`'s internal representation.
  final Map<String, dynamic> authorizationKeyJson;

  /// The logged-in user's ID, once known.
  final int? userId;

  const PtgcSession({
    required this.dcId,
    required this.authorizationKeyJson,
    this.userId,
  });

  factory PtgcSession.fromAuthorizationKey({
    required int dcId,
    required tg.AuthorizationKey key,
    int? userId,
  }) {
    return PtgcSession(
      dcId: dcId,
      authorizationKeyJson: key.toJson(),
      userId: userId,
    );
  }

  tg.AuthorizationKey toAuthorizationKey() =>
      tg.AuthorizationKey.fromJson(authorizationKeyJson);

  PtgcSession copyWith({
    int? dcId,
    Map<String, dynamic>? authorizationKeyJson,
    int? userId,
  }) {
    return PtgcSession(
      dcId: dcId ?? this.dcId,
      authorizationKeyJson: authorizationKeyJson ?? this.authorizationKeyJson,
      userId: userId ?? this.userId,
    );
  }

  factory PtgcSession.fromJson(Map<String, dynamic> json) => PtgcSession(
        dcId: json['dc_id'] as int,
        authorizationKeyJson: (json['auth_key'] as Map).cast<String, dynamic>(),
        userId: json['user_id'] as int?,
      );

  Map<String, dynamic> toJson() => {
        'dc_id': dcId,
        'auth_key': authorizationKeyJson,
        'user_id': userId,
      };
}

/// Where [TelegramClient] persists its [PtgcSession] between runs.
///
/// Implement this yourself to store sessions somewhere other than a local
/// file (a database, secrets manager, etc). Treat the contents as sensitive
/// — anyone who has them can act as the logged-in account without a
/// password or code.
abstract class SessionStore {
  /// Returns the saved session, or `null` if none exists yet.
  Future<PtgcSession?> load();

  /// Persists [session], overwriting any previously saved one.
  Future<void> save(PtgcSession session);

  /// Deletes any saved session — called by [AuthNamespace.logOut].
  Future<void> clear();
}

/// The default [SessionStore]: a single JSON file on disk.
class FileSessionStore implements SessionStore {
  final String path;

  const FileSessionStore([this.path = 'ptgc.session.json']);

  /// Reads the session file. Returns `null` if the file doesn't exist yet,
  /// or if its contents can't be parsed (treated as "no saved session"
  /// rather than a hard error, so a corrupt or foreign file doesn't prevent
  /// startup).
  @override
  Future<PtgcSession?> load() async {
    final file = File(path);
    if (!await file.exists()) return null;
    try {
      final json =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      return PtgcSession.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  /// Writes [session] as JSON to [path], creating the file if needed.
  @override
  Future<void> save(PtgcSession session) async {
    await File(path).writeAsString(jsonEncode(session.toJson()));
  }

  /// Deletes the session file if it exists.
  @override
  Future<void> clear() async {
    final file = File(path);
    if (await file.exists()) await file.delete();
  }
}

/// An in-memory [SessionStore] — nothing survives past process exit. Handy
/// for tests, or short-lived scripts where you don't want a session file
/// left behind.
class MemorySessionStore implements SessionStore {
  PtgcSession? _session;

  /// Returns the in-memory session, or `null` if none has been saved yet.
  @override
  Future<PtgcSession?> load() async => _session;

  /// Stores [session] in memory, replacing any previous one.
  @override
  Future<void> save(PtgcSession session) async => _session = session;

  /// Clears the in-memory session.
  @override
  Future<void> clear() async => _session = null;
}
