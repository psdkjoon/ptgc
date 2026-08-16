// ignore_for_file: file_names, avoid_print

// ============================================================================
// 29 — FILTERING EVENTS BY CHAT AND TYPE
// ============================================================================
//
// 08_send_and_listen.dart listens to everything. In practice you usually
// only care about one chat, or one kind of event — this example shows
// both, using plain Stream methods (.where, and Dart 3 pattern matching on
// the sealed TelegramEvent type) rather than anything ptgc-specific.
//
// HOW TO RUN:
//   1. Edit watchedChatUsername below.
//   2. dart run example/29_filter_events_by_chat.dart
//   3. While it's running, send a message in that chat (from another
//      device/account) and try joining/leaving/getting banned there.
//   4. Ctrl-C to stop.
// ============================================================================

import 'package:ptgc/ptgc.dart';

const watchedChatUsername = 'your_group_here';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final chat = await client.chats.resolveUsername(watchedChatUsername);
  if (chat == null) {
    print('Could not resolve @$watchedChatUsername.');
    await client.disconnect();
    return;
  }

  // Only events from this one chat ...
  final inThisChat = client.events.where(
    (e) => switch (e) {
      NewMessageEvent(:final chatId) => chatId == chat.id,
      MemberStatusChangedEvent(:final chatId) => chatId == chat.id,
    },
  );

  // ... and within those, split by event type.
  inThisChat.listen((event) {
    switch (event) {
      case NewMessageEvent(:final text, :final senderId):
        print('[${chat.title}] new message from $senderId: $text');
      case MemberStatusChangedEvent(:final userId, :final actorId):
        print('[${chat.title}] membership change: user $userId, by $actorId');
    }
  });

  print('Watching ${chat.title} for events. Ctrl-C to stop.');
  await Future<void>.delayed(const Duration(minutes: 10));
  await client.disconnect();
}
