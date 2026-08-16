// ignore_for_file: file_names, avoid_print

// ============================================================================
// 08 — SEND AND LISTEN
// ============================================================================
//
// Basic messaging, plus the live event stream — ptgc's typed view over
// Telegram's raw update feed. Sends yourself a message, then listens for
// 60 seconds, printing anything that happens.
//
// HOW TO RUN:
//   dart run example/08_send_and_listen.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  // Message yourself — the "Saved Messages" chat, addressed by your own ID.
  final selfId = client.userId!;
  await client.messages.sendMessage(selfId, 'Hello from ptgc!');
  print('Sent a message to Saved Messages.');

  final subscription = client.events.listen((event) {
    switch (event) {
      case NewMessageEvent():
        print('New message in ${event.chatId}: ${event.text}');
      case MemberStatusChangedEvent():
        print(
            'Member ${event.userId} changed in ${event.chatId} (by ${event.actorId})');
    }
  });

  print(
      'Listening for 60s — send yourself a message on Telegram to see it appear...');
  await Future<void>.delayed(const Duration(seconds: 60));

  await subscription.cancel();
  await client.disconnect();
}
