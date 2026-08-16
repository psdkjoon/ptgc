// ignore_for_file: file_names, avoid_print

// ============================================================================
// 07 — CONTACTS AND BLOCKING
// ============================================================================
//
// Account-level contact management and blocking — separate from
// chat-specific member control (see 03_ban_kick_restrict.dart). Blocking
// here affects every chat you share with someone, not just one.
//
// HOW TO RUN:
//   1. Edit username below.
//   2. dart run example/07_contacts_and_blocking.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

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

  await client.contacts
      .addContact(user.id, firstName: user.firstName ?? username);
  print('Added ${user.displayName} to contacts.');

  final found = await client.contacts.searchUsers(username);
  print('Search for "$username" found ${found.length} result(s).');

  await client.contacts.block(user.id);
  print('Blocked ${user.displayName} account-wide.');

  final blocked = await client.contacts.getBlockedUsers();
  print('Currently blocked: ${blocked.map((u) => u.displayName).join(', ')}');

  await client.contacts.unblock(user.id);
  print('Unblocked ${user.displayName}.');

  await client.disconnect();
}
