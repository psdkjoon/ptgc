// ignore_for_file: file_names, avoid_print

// ============================================================================
// 40 — RAW INVOKE: FETCHING MESSAGE HISTORY
// ============================================================================
//
// Another escape-hatch example (see 09 and 39): Messages only wraps
// sending/forwarding/deleting (see messages.dart), not reading history —
// so this reaches for messages.getHistory directly. Telegram returns one
// of three response shapes depending on chat size (MessagesMessages,
// MessagesMessagesSlice for a paginated result, or MessagesChannelMessages
// for channels) — this handles all three the same way ptgc's own models.dart
// handles multi-shape responses internally: pattern match, then treat the
// `.messages` field the same regardless of which variant it came back as.
//
// HOW TO RUN:
//   1. Edit chatUsername below.
//   2. dart run example/40_raw_invoke_message_history.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';
import 'package:ptgc/raw.dart' as t;

const chatUsername = 'your_chat_here';

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

  final result = await client.invoke(
    t.MessagesGetHistory(
      peer: client.peers.inputPeer(chat.id),
      offsetId: 0,
      offsetDate: DateTime.fromMillisecondsSinceEpoch(0),
      addOffset: 0,
      limit: 20,
      maxId: 0,
      minId: 0,
      hash: 0,
    ),
  );

  final messages = switch (result) {
    t.MessagesMessages(:final messages) => messages,
    t.MessagesMessagesSlice(:final messages) => messages,
    t.MessagesChannelMessages(:final messages) => messages,
    _ => const <t.MessageBase>[],
  };

  print('Last ${messages.length} message(s) in ${chat.title}:');
  for (final m in messages) {
    if (m is t.Message) {
      final preview =
          m.message.length > 60 ? '${m.message.substring(0, 60)}…' : m.message;
      print('  [${m.id}] ${m.date}: $preview');
    }
  }

  await client.disconnect();
}
