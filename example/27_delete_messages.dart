// ignore_for_file: file_names, avoid_print

// ============================================================================
// 27 — DELETING MESSAGES
// ============================================================================
//
// `revokeForEveryone` controls whether the message disappears for the
// other participant(s) too (where Telegram allows it), or just from your
// own view of the chat. In channels, deletion is always for everyone —
// there's no "just for me" concept there, so the flag has no effect (see
// Messages.deleteMessages' doc comment).
//
// HOW TO RUN:
//   1. Edit chatUsername and messageIds below (send yourself a throwaway
//      message with 08_send_and_listen.dart first if you need one).
//   2. dart run example/27_delete_messages.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const chatUsername = 'your_chat_here';
const messageIds = [123];

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

  await client.messages
      .deleteMessages(chat.id, messageIds, revokeForEveryone: true);
  print(
      'Deleted ${messageIds.length} message(s) from ${chat.title} for everyone.');

  await client.disconnect();
}
