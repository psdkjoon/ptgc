import 'dart:io';
import 'dart:typed_data';

import 'mtp.dart' as tg;

/// A Telegram data center: an id plus a TCP endpoint to reach it at.
class DataCenter {
  final int id;
  final String ipAddress;
  final int port;

  const DataCenter(this.id, this.ipAddress, this.port);

  @override
  String toString() => 'DC$id ($ipAddress:$port)';
}

/// Bootstrap addresses for Telegram's production data centers, used only to
/// establish the very first connection. Once connected, [TelegramClient]
/// refreshes this table from the server's own `help.getConfig` response, so
/// these values just need to get you *a* working connection, not the
/// closest or most current one.
const List<DataCenter> defaultDataCenters = [
  DataCenter(1, '149.154.175.53', 443),
  DataCenter(2, '149.154.167.51', 443),
  DataCenter(3, '149.154.175.100', 443),
  DataCenter(4, '149.154.167.91', 443),
  DataCenter(5, '91.108.56.130', 443),
];

DataCenter dataCenterById(List<DataCenter> table, int id) {
  return table.firstWhere(
    (dc) => dc.id == id,
    orElse: () => throw StateError(
      'Unknown data center $id. This usually means Telegram asked us to '
      'migrate to a DC we have no bootstrap address for; try again, or '
      'open an issue with the DC id.',
    ),
  );
}

/// A [tg.SocketAbstraction] backed by a plain `dart:io` [Socket].
///
/// MTProto layers its own encryption on top, so this deliberately does not
/// use TLS.
class IoSocket implements tg.SocketAbstraction {
  IoSocket._(this._socket);

  final Socket _socket;

  static Future<IoSocket> connect(String host, int port) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 15),
    );
    socket.setOption(SocketOption.tcpNoDelay, true);
    return IoSocket._(socket);
  }

  @override
  Stream<Uint8List> get receiver => _socket.cast<Uint8List>();

  @override
  Future<void> send(List<int> data) async {
    _socket.add(data);
    await _socket.flush();
  }

  Future<void> close() async {
    await _socket.close();
    _socket.destroy();
  }
}
