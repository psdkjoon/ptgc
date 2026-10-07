part of 'mtp.dart';

/// Minimal socket interface the MTProto [Client] writes to and reads from.
///
/// The default implementation, [IoSocket] (in `transport.dart`), wraps a
/// plain `dart:io` [Socket] — MTProto's own AES layer makes TLS redundant.
/// Implement this to substitute a different transport (e.g. a WebSocket
/// bridge, or a fake socket for tests).
abstract class SocketAbstraction {
  /// Incoming byte stream — raw bytes from the wire, delivered as chunks
  /// of arbitrary size.
  Stream<Uint8List> get receiver;

  /// Sends [data] to the remote end. Should flush before returning so
  /// callers can sequence sends safely with `await`.
  Future<void> send(List<int> data);
}
