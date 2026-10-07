part of 'mtp.dart';

/// Raised when Telegram rejects a message due to a sequencing or framing
/// error. The [errorMessage] field translates Telegram's numeric error codes
/// into human-readable descriptions.
///
/// This is an internal MTProto-level error, distinct from [RpcException]
/// in `exceptions.dart`, which is the public-API-level error callers see.
class BadMessageException implements Exception {
  const BadMessageException._(this.result);

  final BadMsgNotification result;

  /// Human-readable description of [result]'s numeric error code, as
  /// documented in https://core.telegram.org/mtproto/service_messages_about_messages.
  String get errorMessage {
    final error = result.errorCode;
    switch (error) {
      case 16:
        return 'msg_id too low (most likely, client time is wrong; it would be worthwhile to synchronize it using msg_id notifications and re-send the original message with the "correct" msg_id or wrap it in a container with a new msg_id if the original message had waited too long on the client to be transmitted)';
      case 17:
        return 'msg_id too high (similar to the previous case, the client time has to be synchronized, and the message re-sent with the correct msg_id)';
      case 18:
        return 'incorrect two lower order msg_id bits (the server expects client message msg_id to be divisible by 4)';
      case 19:
        return 'container msg_id is the same as msg_id of a previously received message (this must never happen)';
      case 20:
        return 'message too old, and it cannot be verified whether the server has received a message with this msg_id or not';
      case 32:
        return 'msg_seqno too low (the server has already received a message with a lower msg_id but with either a higher or an equal and odd seqno)';
      case 33:
        return 'msg_seqno too high (similarly, there is a message with a higher msg_id but with either a lower or an equal and odd seqno)';
      case 34:
        return 'an even msg_seqno expected (irrelevant message), but odd received';
      case 35:
        return 'odd msg_seqno expected (relevant message), but even received';
      case 48:
        return 'incorrect server salt (in this case, the bad_server_salt response is received with the correct salt, and the message is to be re-sent with it)';
      case 64:
        return 'invalid container.';
    }
    return error.toString();
  }

  @override
  String toString() => '${result.errorCode}: $errorMessage';
}

/// An RPC-level error returned by Telegram inside an encrypted frame.
///
/// This is the raw MTProto-layer type. [TelegramClient.callRaw] converts it
/// into the public [PtgcException] hierarchy before it reaches callers.
class RpcException {
  const RpcException._(this.errorCode, this.errorMessage);

  /// Telegram's numeric error code (e.g. `400`, `403`, `420`).
  final int errorCode;

  /// Telegram's raw error string (e.g. `'PEER_ID_INVALID'`, `'FLOOD_WAIT_30'`).
  final String errorMessage;

  @override
  String toString() => '$errorCode: $errorMessage';
}
