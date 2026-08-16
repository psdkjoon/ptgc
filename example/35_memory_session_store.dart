// ignore_for_file: file_names, avoid_print

// ============================================================================
// 35 — IN-MEMORY SESSION (NO FILE LEFT BEHIND)
// ============================================================================
//
// MemorySessionStore never touches disk — the auth key lives only for the
// life of the process. You'll have to log in from scratch (phone/code/2FA,
// see 01_login.dart) every single run, but nothing persists afterwards.
// Good for CI, one-off scripts, or anywhere you don't want a session file
// with real account access sitting around afterwards.
//
// HOW TO RUN:
//   dart run example/35_memory_session_store.dart
//   (it'll ask for a login code every time — that's expected)
// ============================================================================

import 'dart:io';

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv(sessionStore: MemorySessionStore());
  await client.connect();

  if (!client.isSignedIn) {
    stdout.write('Phone number (with country code): ');
    final phone = stdin.readLineSync()!.trim();
    final sent = await client.auth.sendCode(phone);

    stdout.write('Login code: ');
    final code = stdin.readLineSync()!.trim();
    final result =
        await client.auth.signIn(code: code, phoneCodeHash: sent.phoneCodeHash);

    if (result.status == SignInStatus.passwordRequired) {
      stdout.write('2FA password: ');
      final password = stdin.readLineSync()!.trim();
      await client.auth.checkPassword(password);
    }
  }

  print('Logged in as user ${client.userId}. Nothing was written to disk — '
      'run this again and you\'ll be asked to log in from scratch.');

  await client.disconnect();
}
