part of 'mtp.dart';

/// Obfuscation.
class Obfuscation {
  const Obfuscation._(this.send, this.recv, this.preamble);

  /// Generate a random obfuscator.
  ///
  /// Regenerates the random buffer if it would produce a preamble that
  /// could be mistaken for another protocol (plain HTTP, TLS, etc.) by
  /// middleboxes doing protocol sniffing -- required by the obfuscated
  /// transport spec.
  factory Obfuscation.random(bool padded, int dcId, [Uint8List? secret]) {
    final random = Uint8List(58);

    while (true) {
      _rng.getBytes(random);

      final firstByte = random[0];
      final firstUint32 =
          ByteData.sublistView(random).getUint32(0, Endian.little);
      final secondInt32 =
          ByteData.sublistView(random).getInt32(4, Endian.little);

      const forbiddenFirstUint32 = {
        0x44414548, // 'HEAD'
        0x54534f50, // 'POST'
        0x20544547, // 'GET '
        0x4954504f, // 'OPTI'
        0x02010316,
        0xdddddddd,
        0xeeeeeeee,
      };

      if (firstByte == 0xef ||
          forbiddenFirstUint32.contains(firstUint32) ||
          secondInt32 == 0) {
        continue;
      }

      break;
    }

    return Obfuscation.preamble(random, padded, dcId, secret);
  }

  /// Generate an obfuscator from a pre-computed preamble.
  ///
  /// [random] Must be 58 bytes random.
  factory Obfuscation.preamble(
    Uint8List random,
    bool padded,
    int dcId, [
    Uint8List? secret,
  ]) {
    final protocolId = padded ? 0xDD : 0xEE;
    final preamble = Uint8List(64);

    preamble.setRange(0, 58, random);

    preamble[62] = preamble[56];
    preamble[63] = preamble[57];

    preamble[56] = preamble[57] = preamble[58] = preamble[59] = protocolId;

    preamble[60] = dcId;
    preamble[61] = dcId >> 8;

    var recvKey = Uint8List.fromList(preamble.sublist(8, 40).toList());
    final recvIV = Uint8List.fromList(preamble.sublist(40, 56).toList());

    preamble.reverse(8, 48);

    var sendKey = Uint8List.fromList(preamble.sublist(8, 40).toList());
    final sendIV = Uint8List.fromList(preamble.sublist(40, 56).toList());

    final sec = secret;
    if (sec != null) {
      sendKey = Uint8List.fromList(
        sha256([...sendKey.sublist(0, 32), ...sec.sublist(0, 16)]),
      );

      recvKey = Uint8List.fromList(
        sha256([...recvKey.sublist(0, 32), ...sec.sublist(0, 16)]),
      );
    }

    final sendCtr = AesCtr(sendKey, sendIV);
    final recvCtr = AesCtr(recvKey, recvIV);
    final encrypted = Uint8List.fromList(preamble.toList());

    sendCtr.encryptDecrypt(encrypted, 64);

    for (int i = 56; i < 64; i++) {
      preamble[i] = encrypted[i];
    }

    return Obfuscation._(sendCtr, recvCtr, preamble);
  }

  /// Sender encryption.
  final AesCtr send;

  /// Receiver encryption.
  final AesCtr recv;

  /// Preamble used to generate [send] and [recv].
  final Uint8List preamble;
}

class AesCtr {
  late final pc.StreamCipher _cipher;

  AesCtr(Uint8List key, Uint8List iv) {
    final params = pc.ParametersWithIV(pc.KeyParameter(key), iv);
    _cipher = pc.StreamCipher('AES/CTR')..init(true, params);
  }
  void encryptDecrypt(List<int> input, int length) {
    assert(length <= input.length);

    final copy = Uint8List.fromList(input);
    final processed = _cipher.process(copy);

    for (int i = 0; i < length; i++) {
      input[i] = processed[i];
    }
  }
}
