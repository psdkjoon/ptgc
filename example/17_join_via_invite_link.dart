// ignore_for_file: file_names, avoid_print

// ============================================================================
// 17 — JOIN VIA INVITE LINK
// ============================================================================
//
// For chats without a public @username — most private groups — you join
// with an invite link instead (see 16_join_public_channel.dart for the
// public case, and 18_export_invite_link.dart to generate one). Accepts
// either the full https://t.me/... link or just the hash after it.
//
// HOW TO RUN:
//   1. Edit inviteLink below to a real `t.me/+...` or `t.me/joinchat/...`
//      link someone shared with you.
//   2. dart run example/17_join_via_invite_link.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const inviteLink = 'https://t.me/+AAAAAAAAAAAAAAAA';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  await client.chats.joinByInviteLink(inviteLink);
  print('Joined via invite link.');

  // The chat is now in your dialogs — list them to confirm and find its id.
  final dialogs = await client.chats.listDialogs(limit: 5);
  print('Most recent chat: ${dialogs.first.title}');

  await client.disconnect();
}
