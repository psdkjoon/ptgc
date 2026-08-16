// ignore_for_file: file_names, avoid_print

// ============================================================================
// 26 — FORWARDING MESSAGES
// ============================================================================
//
// Forwards one or more messages from one chat into another, preserving the
// "Forwarded from" attribution. Handy for e.g. relaying an announcement
// from a source channel into your own.
//
// HOW TO RUN:
//   1. Edit sourceChatUsername, messageIds (get one from
//      29_filter_events_by_chat.dart or 40_raw_invoke_message_history.dart),
//      and destinationChatUsername below.
//   2. dart run example/26_forward_messages.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const sourceChatUsername = 'source_chat_here';
const messageIds = [123];
const destinationChatUsername = 'destination_chat_here';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final source = await client.chats.resolveUsername(sourceChatUsername);
  final destination =
      await client.chats.resolveUsername(destinationChatUsername);

  if (source == null || destination == null) {
    print('Could not resolve $sourceChatUsername or $destinationChatUsername.');
    await client.disconnect();
    return;
  }

  await client.messages.forwardMessages(source.id, messageIds, destination.id);
  print('Forwarded ${messageIds.length} message(s) from ${source.title} '
      'to ${destination.title}.');

  await client.disconnect();
}
