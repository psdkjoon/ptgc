import 'tl.dart' as t;

/// Base class for every exception this package throws.
///
/// Catch this to handle any `ptgc` failure generically, or catch one of the
/// more specific subtypes ([FloodWaitException], [RpcException],
/// [AuthRequiredException], [TwoFactorRequiredException],
/// [PeerNotFoundException]) to react to a particular failure mode.
sealed class PtgcException implements Exception {
  /// A human-readable explanation of what went wrong.
  final String message;

  const PtgcException(this.message);

  @override
  String toString() => '$runtimeType: $message';
}

/// Telegram rejected a request with an RPC error that isn't one of the more
/// specific cases below (flood wait, auth, etc).
///
/// [code] and [description] mirror Telegram's own `error_code` /
/// `error_message` fields exactly (e.g. `400`, `'PEER_ID_INVALID'`), so you
/// can pattern-match on [description] for errors this package doesn't have
/// a dedicated type for yet.
class RpcException extends PtgcException {
  /// The numeric error code Telegram returned (e.g. `400`, `403`).
  final int code;

  /// Telegram's raw error string (e.g. `'PEER_ID_INVALID'`, `'CHAT_ADMIN_REQUIRED'`).
  final String description;

  /// The raw [t.RpcError] this exception was built from, for anything not
  /// exposed above.
  final t.RpcError raw;

  RpcException(this.raw)
      : code = raw.errorCode,
        description = raw.errorMessage,
        super('Telegram RPC error ${raw.errorCode}: ${raw.errorMessage}');
}

/// Telegram is rate-limiting this request. Wait [duration] before retrying.
///
/// Thrown for `FLOOD_WAIT_*` and `FLOOD_PREMIUM_WAIT_*` errors, with
/// [duration] parsed out of the error string for you.
class FloodWaitException extends PtgcException {
  /// How long to wait before retrying the request that triggered this.
  final Duration duration;

  FloodWaitException(this.duration)
      : super('Flood wait: retry after ${duration.inSeconds}s');
}

/// A method that requires an active login (e.g. sending a message) was
/// called before [signIn]/[checkPassword] completed successfully, or the
/// session was revoked server-side.
class AuthRequiredException extends PtgcException {
  AuthRequiredException(
      [String message =
          'Not authorized. Call auth.sendCode / auth.signIn first.'])
      : super(message);
}

/// [AuthNamespace.signIn] succeeded up to the point of needing the
/// account's Two-Factor Authentication password, but [checkPassword] hasn't
/// been called (or the password call itself was never attempted).
///
/// This is informational — [SignInResult.status] already tells you this;
/// the exception exists for the rare case you call [checkPassword] without
/// a pending challenge.
class TwoFactorRequiredException extends PtgcException {
  TwoFactorRequiredException([
    String message = 'A 2FA password is required; call auth.signIn first '
        'to obtain the pending password challenge.',
  ]) : super(message);
}

/// A username, phone number, or ID could not be resolved to a Telegram peer.
class PeerNotFoundException extends PtgcException {
  PeerNotFoundException(String who) : super('Could not resolve peer: $who');
}

/// Converts a raw [t.RpcError] into the most specific [PtgcException]
/// subtype available.
PtgcException exceptionFromRpcError(t.RpcError error) {
  final msg = error.errorMessage;

  if (msg.startsWith('FLOOD_WAIT_') || msg.startsWith('FLOOD_PREMIUM_WAIT_')) {
    final seconds = int.tryParse(msg.split('_').last) ?? 0;
    return FloodWaitException(Duration(seconds: seconds));
  }

  if (msg == 'AUTH_KEY_UNREGISTERED' ||
      msg == 'SESSION_REVOKED' ||
      msg == 'SESSION_EXPIRED' ||
      msg == 'AUTH_KEY_INVALID') {
    return AuthRequiredException('Session is no longer valid ($msg). '
        'Delete the session file and log in again.');
  }

  return RpcException(error);
}

/// Whether [error] is one of the `*_MIGRATE_*` errors Telegram uses to
/// redirect a client to a different data center.
bool isMigrateError(t.RpcError error) {
  final msg = error.errorMessage;
  return error.errorCode == 303 &&
      (msg.startsWith('PHONE_MIGRATE_') ||
          msg.startsWith('NETWORK_MIGRATE_') ||
          msg.startsWith('USER_MIGRATE_'));
}

/// Extracts the target data center id out of a `*_MIGRATE_*` error message.
int migrateTargetDcId(t.RpcError error) =>
    int.parse(error.errorMessage.split('_').last);
