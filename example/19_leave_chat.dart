// ignore_for_file: file_names, avoid_print

// ============================================================================
// 19 — LEAVE A CHAT
// ============================================================================
//
// Leaves a chat without deleting it or affecting anyone else in it. Works
// the same way for basic groups and supergroups/channels — ptgc picks the
// right raw call for you.
//
// HOW TO RUN:
//   1. Edit chatUsername below to something you're fine leaving.
//   2. dart run example/19_leave_chat.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const chatUsername = 'your_group_or_channel_here';

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

  await client.chats.leave(chat.id);
  print('Left ${chat.title}.');

  await client.disconnect();
}
