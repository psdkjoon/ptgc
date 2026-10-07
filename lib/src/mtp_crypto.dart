/// Thin wrappers around SHA-256 and SHA-1 used throughout the MTProto layer.
///
/// These are separate from `hashing.dart` (ptgb's standalone SHA-256) because
/// `ptgc` depends on `package:pointycastle`, which already provides both.
library;

import 'dart:typed_data';

import 'package:pointycastle/export.dart';

List<int> sha256(List<int> data) {
  return SHA256Digest().process(Uint8List.fromList(data));
}

List<int> sha1(List<int> data) {
  return SHA1Digest().process(Uint8List.fromList(data));
}
