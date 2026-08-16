// ignore_for_file: file_names, avoid_print

// ============================================================================
// 14 — CREATE A BROADCAST CHANNEL
// ============================================================================
//
// The other `channel` flavor besides a supergroup (see 13): only admins
// can post, everyone else just reads. Good for announcements/newsletters
// rather than discussion.
//
// HOW TO RUN:
//   dart run example/14_create_channel.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const channelTitle = 'ptgc test channel';
const channelAbout = 'Created by the ptgc 14_create_channel.dart example.';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final chatId =
      await client.chats.createChannel(channelTitle, about: channelAbout);
  if (chatId == null) {
    print('Channel creation did not return a chat id.');
    await client.disconnect();
    return;
  }

  print('Created "$channelTitle" — id: $chatId');

  // Post the first message — only admins (you, right now) can do this.
  await client.messages.sendMessage(chatId, 'Hello, this is the first post!');
  print('Posted the first message.');

  await client.disconnect();
}
