// ignore_for_file: file_names, avoid_print

// ============================================================================
// 12 — CREATE A BASIC GROUP
// ============================================================================
//
// Basic groups are the simplest chat type Telegram has — capped at 200
// members, no admin hierarchy beyond "admin or not". Telegram requires at
// least one other member to create one; you can't make an empty group.
//
// HOW TO RUN:
//   1. Edit founderUsernames below to one or more accounts you can add
//      (contacts, or anyone whose privacy settings allow it).
//   2. dart run example/12_create_basic_group.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupTitle = 'ptgc test group';
const founderUsernames = ['someone_here'];

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final userIds = <int>[];
  for (final username in founderUsernames) {
    final user = await client.contacts.resolveUsername(username);
    if (user != null) userIds.add(user.id);
  }

  if (userIds.isEmpty) {
    print('Could not resolve any of $founderUsernames — a basic group needs '
        'at least one other member to create.');
    await client.disconnect();
    return;
  }

  final chatId = await client.chats.createGroup(groupTitle, userIds);
  if (chatId == null) {
    print('Group creation did not return a chat id.');
  } else {
    print('Created "$groupTitle" — id: $chatId');
    // Basic groups don't page/filter server-side (see Members.list docs) —
    // this just confirms everyone landed in the new group.
    final members = await client.members.list(chatId);
    print('Members: ${members.map((p) => p.user.displayName).join(', ')}');
  }

  await client.disconnect();
}
