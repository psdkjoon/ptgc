part of 'mtp.dart';

bool _constantTimeEquals(List<int> a, List<int> b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a[i] ^ b[i];
  }
  return diff == 0;
}

class _Frame {
  const _Frame(
    this.message,
    this.messageId,
    this.authKeyId,
    this.seqno,
  );

  /// Parse from [Uint8List].
  factory _Frame.parse(
    Uint8List data,
    Obfuscation? obfuscation,
    List<int> authKey,
  ) {
    obfuscation?.recv.encryptDecrypt(data, data.length);

    final br = BinaryReader(data);

    final authKeyId = br.readInt64();

    if (authKeyId == 0) {
      final messageId = br.readInt64();
      final msgLength = br.readInt32(); // Message Length.

      final messageBuffer = br.readRawBytes(msgLength);
      final br2 = BinaryReader(messageBuffer);
      final message = br2.readObject();

      return _Frame(message, messageId, authKeyId, null);
    }

    //

    final decryptedData = _encryptDecryptMessage(
      Uint8List.fromList(data.skip(24).toList()),
      false,
      8,
      authKey,
      data,
      8,
    );

    // Verify msg_key: recompute SHA256(substr(auth_key, 96, 32) + plaintext)
    // and check it matches the msg_key the server sent us (bytes 8..24 of
    // the frame). Without this, a corrupted or tampered frame would be
    // silently decrypted and processed instead of rejected.
    final expectedMsgKeyFull =
        sha256([...authKey.skip(96).take(32), ...decryptedData]);
    final expectedMsgKey = expectedMsgKeyFull.skip(8).take(16).toList();
    final actualMsgKey = data.skip(8).take(16).toList();

    if (!_constantTimeEquals(expectedMsgKey, actualMsgKey)) {
      throw Exception(
          'Mismatch between msg_key and decrypted SHA256 — the frame may be corrupted or tampered with.');
    }

    final reader = BinaryReader(decryptedData);

    {
      final serverSalt = reader.readInt64(); // int64 salt
      final _ = serverSalt;
    }

    {
      final sessionId = reader.readInt64(); // int64 session_id
      final _ = sessionId;
    }

    final msgId = reader.readInt64(); // int64 message_id
    final seqno = reader.readInt32(); // int32 msg_seqno

    {
      final length = reader.readInt32(); // int32 message_data_length
      final _ = length;
    }

    final message = reader.readObject();

    return _Frame(message, msgId, authKeyId, seqno);
  }

  final TlObject message;
  final int messageId;
  final int authKeyId;
  final int? seqno;

  Uint8List toUint8List(Obfuscation? obfuscation) {
    final messageBuffer = message.asUint8List();

    final data = <int>[
      ...(messageBuffer.length + 20).asUint32List(),
      ...authKeyId.asUint64List(),
      ...messageId.asUint64List(),
      ...messageBuffer.length.asUint32List(),
      ...messageBuffer,
    ];

    obfuscation?.send.encryptDecrypt(data, data.length);

    return Uint8List.fromList(data);
  }

  Map<String, dynamic> toJson() {
    return {
      'authKeyId': authKeyId,
      'messageId': messageId,
      'message': message.runtimeType.toString(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
