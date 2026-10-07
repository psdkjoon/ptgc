part of 'mtp.dart';

/// The negotiated MTProto authorization key: a shared 2048-bit secret
/// derived during the Diffie–Hellman exchange in [_DiffieHellman.exchange].
///
/// Once negotiated, the key is saved in the [SessionStore] and reused across
/// reconnections so the DH exchange only happens once per data center.
class AuthorizationKey {
  /// Creates an [AuthorizationKey] from its component parts.
  ///
  /// [id] is the lower 64 bits of the SHA-1 of [key], used to identify
  /// which key a frame was encrypted with.
  /// [key] must be exactly 256 bytes (2048 bits).
  /// [salt] is the server salt negotiated alongside the key.
  AuthorizationKey(this.id, this.key, this.salt)
      : assert(id != 0, 'Id must not be zero.'),
        assert(key.length == 256, 'Key must be 256 bytes.');

  AuthorizationKey._(this.id, this.key, this.salt)
      : assert(id != 0, 'Id must not be zero.'),
        assert(key.length == 256, 'Key must be 256 bytes.');

  /// Deserializes from the JSON shape produced by [toJson].
  factory AuthorizationKey.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as int;
    final salt = json['salt'] as int;
    final keyHex = json['key'] as String;
    final key = _fromHexToUint8List(keyHex);
    return AuthorizationKey(id, key, salt);
  }

  /// Lower 64 bits of SHA-1(key) — identifies this key in frame headers.
  final int id;

  /// The 2048-bit (256-byte) shared secret.
  final List<int> key;

  /// Current server salt — updated on [BadServerSalt] responses.
  final int salt;

  /// Serializes to a JSON map suitable for storage in a [SessionStore].
  Map<String, dynamic> toJson() => {
        'id': id,
        'key': _hex(key),
        'salt': salt,
      };

  @override
  String toString() => jsonEncode(toJson());
}
