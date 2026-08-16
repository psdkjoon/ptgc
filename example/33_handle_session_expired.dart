// ignore_for_file: file_names, avoid_print

// ============================================================================
// 33 — HANDLING AN EXPIRED SESSION
// ============================================================================
//
// A saved session can stop being valid without any local warning — the
// user revoked it from another device, Telegram logged it out for
// inactivity, etc. Any call that touches the wire can then throw
// AuthRequiredException (see exceptionFromRpcError's AUTH_KEY_UNREGISTERED
// / SESSION_REVOKED / SESSION_EXPIRED / AUTH_KEY_INVALID handling). This
// example shows the standard recovery: clear the stale session and walk
// through 01_login.dart's flow again.
//
// HOW TO RUN:
//   dart run example/33_handle_session_expired.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  try {
    // whoAmI touches the wire, so it's a fine canary for session validity.
    final me = await client.whoAmI();
    print('Session is valid: logged in as ${me.displayName}.');
  } on AuthRequiredException catch (e) {
    print('Session expired: ${e.message}');
    await client.sessionStore.clear();
    print('Cleared the stale session — run 01_login.dart to log in fresh.');
    await client.disconnect();
    return;
  }

  await client.disconnect();
}
