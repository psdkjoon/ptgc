// ignore_for_file: file_names, avoid_print

// ============================================================================
// 09 — RAW INVOKE ESCAPE HATCH
// ============================================================================
//
// ptgc wraps a useful subset of the Telegram Client API, not all of it —
// the full schema has thousands of methods. Anything not wrapped yet is
// one `client.invoke(...)` call away, with the same error handling and
// automatic data-center migration as every typed method in this package.
//
// This example calls `users.getFullUser` directly — a real method ptgc
// happens not to wrap yet — to look up someone's bio/about text.
//
// HOW TO RUN:
//   1. Edit username below.
//   2. dart run example/09_raw_invoke_escape_hatch.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';
import 'package:ptgc/raw.dart' as t;

const username = 'someone_here';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final user = await client.contacts.resolveUsername(username);
  if (user == null) {
    print('Could not resolve $username.');
    await client.disconnect();
    return;
  }

  // Any `t.TlMethod` from package:ptgc/raw.dart works here — construct the
  // raw request Telegram's schema defines, and get back the raw typed
  // response object.
  final result = await client
      .invoke(t.UsersGetFullUser(id: client.peers.inputUser(user.id)));

  if (result is t.UsersUserFull && result.fullUser is t.UserFull) {
    final about = (result.fullUser as t.UserFull).about;
    print('${user.displayName}: ${about ?? "(no bio set)"}');
  }

  await client.disconnect();
}
