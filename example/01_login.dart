// ignore_for_file: file_names, avoid_print
// (numbered intentionally for reading/run order -- see README.md)

// ============================================================================
// 01 — LOGIN
// ============================================================================
//
// Every ptgc program starts here: connect, then log in if you're not
// already. This example walks through the full flow, including the 2FA
// step, and leaves you logged in with a session file saved for next time.
//
// HOW TO RUN:
//   1. Create a `.env` file next to this script with API_ID and API_HASH
//      (see the README's "Setup" section for how to get these).
//   2. dart run example/01_login.dart
//   3. Enter your phone number, then the code Telegram sends you, then
//      your 2FA password if you have one set.
//   4. Run it again — you'll notice it skips straight to "Logged in as ...",
//      because ptgc.session.json now remembers this login.
// ============================================================================

import 'dart:io';

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  // A `TelegramClient` is your single entry point to the Client API, same
  // role `Bot` plays in ptgb. `.fromEnv()` reads API_ID/API_HASH from a
  // `.env` file via the `penv` package, keeping secrets out of your source.
  final client = TelegramClient.fromEnv();

  // Opens the MTProto connection. This alone does NOT log you in — it just
  // gets you a working, encrypted socket to Telegram, reusing a saved
  // session if one exists.
  await client.connect();

  if (!client.isSignedIn) {
    stdout.write('Phone number (with country code, e.g. +15551234567): ');
    final phone = stdin.readLineSync()!.trim();

    final sent = await client.auth.sendCode(phone);
    stdout.write('Code Telegram sent you: ');
    final code = stdin.readLineSync()!.trim();

    final result =
        await client.auth.signIn(code: code, phoneCodeHash: sent.phoneCodeHash);

    switch (result.status) {
      case SignInStatus.success:
        print('Logged in as ${result.user!.displayName}');
      case SignInStatus.passwordRequired:
        // This account has Two-Factor Authentication enabled — the code
        // alone isn't enough.
        if (result.passwordHint != null)
          print('Password hint: ${result.passwordHint}');
        stdout.write('2FA password: ');
        final password = stdin.readLineSync()!.trim();
        final user = await client.auth.checkPassword(password);
        print('Logged in as ${user.displayName}');
      case SignInStatus.signUpRequired:
        print('This phone number has no Telegram account yet. ptgc is for '
            'automating an existing account, not creating new ones.');
        await client.disconnect();
        return;
    }
  } else {
    print('Already logged in as user ${client.userId} (from saved session).');
  }

  await client.disconnect();
}
