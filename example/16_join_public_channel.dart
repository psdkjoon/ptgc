// ignore_for_file: file_names, avoid_print

// ============================================================================
// 16 — JOIN A PUBLIC CHANNEL/SUPERGROUP
// ============================================================================
//
// Chats.join works for anything with a public @username, no invite link
// needed. For private chats (no username), see
// 17_join_via_invite_link.dart instead.
//
// HOW TO RUN:
//   1. Edit chatUsername below to a public supergroup/channel.
//   2. dart run example/16_join_public_channel.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const chatUsername = 'your_public_group_or_channel_here';

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

  if (chat.kind == ChatKind.group) {
    print('${chat.title} is a basic group — those have no public join, you '
        'need to be added by an existing member (see 06_invite_members.dart).');
    await client.disconnect();
    return;
  }

  await client.chats.join(chat.id);
  print('Joined ${chat.title}.');

  await client.disconnect();
}
