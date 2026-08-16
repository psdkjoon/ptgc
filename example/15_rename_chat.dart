// ignore_for_file: file_names, avoid_print

// ============================================================================
// 15 — RENAME A CHAT
// ============================================================================
//
// Chats.setTitle works the same way across basic groups and
// supergroups/channels — ptgc picks the right raw call for you (see the
// README's note on basic-group vs. supergroup/channel nuances).
//
// HOW TO RUN:
//   1. Edit chatUsername and newTitle below. You need "change info" rights
//      (see AdminRights.changeInfo) unless you're the creator.
//   2. dart run example/15_rename_chat.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const chatUsername = 'your_group_or_channel_here';
const newTitle = 'Renamed by ptgc';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final chat = await client.chats.resolveUsername(chatUsername);
  if (chat == null) {
    print('Could not resolve @$chatUsername.');
    await client.disconnect();
    return;
  }

  print('Old title: ${chat.title}');
  await client.chats.setTitle(chat.id, newTitle);
  print('Renamed to: $newTitle');

  await client.disconnect();
}
