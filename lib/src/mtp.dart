/// MTProto transport layer for `ptgc`.
///
/// This library is the lowest level of the stack: it owns the encrypted
/// socket connection to a Telegram data center, the Diffie–Hellman key
/// exchange that produces an [AuthorizationKey], and the message framing
/// (serialization, padding, AES-IGE encryption, obfuscation) described in
/// https://core.telegram.org/mtproto.
///
/// It is assembled as a `part` library so the internal helpers (`_Frame`,
/// `_EncryptedTransformer`, `MessageIdGenerator`, ...) can share private
/// state without leaking into the public API. The single entry point for
/// callers is [Client] — everything else here is an implementation detail.
library ptgc_mtp;

import 'dart:async';
import 'dart:convert';

import 'dart:math';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:cryptography/cryptography.dart' as cryptography;
import 'tl.dart';
import 'tl.dart' as t;

import 'mtp_crypto.dart';
import 'mtp_encrypt.dart';

part 'mtp_decoders.dart';
part 'mtp_encoders.dart';
part 'mtp_check2fa.dart';
part 'mtp_exceptions.dart';
part 'mtp_extensions.dart';
part 'mtp_private.dart';
part 'mtp_dh.dart';
part 'mtp_diffie_hellman.dart';
part 'mtp_frame.dart';
part 'mtp_public_keys.dart';
part 'mtp_client.dart';
part 'mtp_constants.dart';
part 'mtp_obfuscation.dart';
part 'mtp_telegram_client.dart';
part 'mtp_auth_key.dart';
part 'mtp_socket_abstraction.dart';
