// ignore_for_file: avoid_print

// ============================================================================
// ptgc — minimal end-to-end example
// ============================================================================
//
// Connects, logs in (or reuses a saved session), prints who you are, and
// bans a member from a chat as a demonstration of the member-management
// APIs this package exists for.
//
// See the numbered scripts in this same `example/` directory for
// step-by-step walkthroughs of login, contacts, dialogs, messaging, group
// creation, error handling, and more — start with `01_login.dart`.
//
// HOW TO RUN:
//   1. Create a `.env` file next to this script with API_ID and API_HASH
//      (see the package README's "Setup" section for how to get these).
//   2. dart run example/main.dart
// ============================================================================

import 'dart:io';

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  // A `TelegramClient` is your single entry point to the Client API.
  // `.fromEnv()` reads API_ID/API_HASH from a `.env` file via the `penv`
  // package, keeping secrets out of your source.
  final client = TelegramClient.fromEnv();

  // Opens the MTProto connection, reusing a saved session if one exists.
  await client.connect();

  if (!client.isSignedIn) {
    stdout.write('Phone number (with country code, e.g. +15551234567): ');
    final phone = stdin.readLineSync()!.trim();

    final sent = await client.auth.sendCode(phone);
    stdout.write('Code Telegram sent you: ');
    final code = stdin.readLineSync()!.trim();

    final result =
        await client.auth.signIn(code: code, phoneCodeHash: sent.phoneCodeHash);

    if (result.status == SignInStatus.passwordRequired) {
      stdout.write('2FA password: ');
      final password = stdin.readLineSync()!.trim();
      await client.auth.checkPassword(password);
    }
  }

  final me = await client.contacts.resolveUsername('someone');
  if (me != null) {
    print('Found @someone (id: ${me.id}).');
    // Only meaningful if you're an admin in a chat with this user:
    // await client.members.ban(chatId, me.id);
  } else {
    print('No user found for @someone.');
  }

  await client.disconnect();
}
