// ignore_for_file: file_names, avoid_print

// ============================================================================
// 36 — LOGGING OUT
// ============================================================================
//
// auth.logOut() revokes the session server-side — Telegram invalidates the
// auth key, so it can't be reused even if someone got hold of the saved
// session file. It also clears TelegramClient.sessionStore locally. This is
// different from disconnect(), which just closes the socket without
// revoking anything — see the doc comment on auth.logOut for that
// distinction.
//
// HOW TO RUN:
//   dart run example/36_log_out.dart
//   (you'll need to run 01_login.dart again afterwards — this really does
//   revoke the session)
// ============================================================================

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — nothing to log out of.');
    await client.disconnect();
    return;
  }

  final userId = client.userId;
  await client.auth.logOut();
  print('Logged out user $userId — the session is now revoked server-side, '
      'and the saved session file has been cleared.');

  await client.disconnect();
}
