/// `ptgc` — a client for the Telegram **Client API** (MTProto).
///
/// Where `ptgb` (the companion package) talks to Telegram *as a bot*, this
/// package talks to Telegram *as a real user account*: logging in with a
/// phone number, and — the main reason this package exists — controlling
/// chat membership the way only a user account (or a bot with admin
/// rights) can: [Members.ban], [Members.kick], [Members.restrict],
/// [Members.promote], [Members.invite], and listing/inspecting members
/// with [Members.list] / [Members.get].
///
/// Start with [TelegramClient]:
///
/// ```dart
/// import 'package:ptgc/ptgc.dart';
///
/// void main() async {
///   final client = TelegramClient.fromEnv();
///   await client.connect();
///
///   if (!client.isSignedIn) {
///     final sent = await client.auth.sendCode('+15551234567');
///     final result = await client.auth.signIn(code: '12345', phoneCodeHash: sent.phoneCodeHash);
///     if (result.status == SignInStatus.passwordRequired) {
///       await client.auth.checkPassword('your 2FA password');
///     }
///   }
///
///   final me = await client.contacts.resolveUsername('someone');
///   if (me != null) await client.members.ban(chatId, me.id);
///
///   await client.disconnect();
/// }
/// ```
///
/// See the `example/` directory for complete, runnable scripts covering
/// login, member management, contacts, and dialogs.
library;

export 'src/auth.dart' show AuthNamespace, SentCode, SignInResult, SignInStatus;
export 'src/chats.dart' show Chats;
export 'src/client.dart' show TelegramClient, packageVersion;
export 'src/contacts.dart' show Contacts;
export 'src/enums.dart' show ChatKind, ParticipantFilter, ParticipantRole;
export 'src/exceptions.dart'
    show
        AuthRequiredException,
        FloodWaitException,
        PeerNotFoundException,
        PtgcException,
        RpcException,
        TwoFactorRequiredException;
export 'src/members.dart' show Members;
export 'src/messages.dart' show Messages;
export 'src/models.dart' show Participant, PtgcChat, PtgcUser;
export 'src/peer_cache.dart' show PeerCache, PeerKind;
export 'src/rights.dart' show AdminRights, BannedRights;
export 'src/session.dart'
    show FileSessionStore, MemorySessionStore, PtgcSession, SessionStore;
export 'src/transport.dart' show DataCenter, defaultDataCenters;
export 'src/updates.dart'
    show MemberStatusChangedEvent, NewMessageEvent, TelegramEvent;
