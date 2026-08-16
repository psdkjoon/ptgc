/// The raw Telegram TL schema — every generated method and type, plus
/// [TlMethod]/[TlObject] themselves — for use with
/// [TelegramClient.invoke]/[TelegramClient.raw].
///
/// `ptgc` wraps a useful subset of the schema (see `package:ptgc/ptgc.dart`).
/// For anything it doesn't wrap yet, import this alongside it:
///
/// ```dart
/// import 'package:ptgc/ptgc.dart';
/// import 'package:ptgc/raw.dart' as t;
///
/// final result = await client.invoke(t.UsersGetFullUser(id: someInputUser));
/// ```
///
/// This is a separate entrypoint (rather than being folded into
/// `package:ptgc/ptgc.dart`) so that everyday `ptgc` usage doesn't pull the
/// entire generated schema — thousands of types — into scope; only import
/// this when you actually need the escape hatch.
///
/// The generated TL schema lives under `lib/src/`; this entrypoint exports
/// it so those types are reachable from `package:ptgc/raw.dart`.
library;

export 'src/tl.dart';
