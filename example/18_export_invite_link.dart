// ignore_for_file: file_names, avoid_print

// ============================================================================
// 18 — EXPORT AN INVITE LINK
// ============================================================================
//
// Generates (or refreshes) a shareable invite link for a chat — the
// counterpart to 17_join_via_invite_link.dart. Requires
// AdminRights.inviteUsers if you're not the creator.
//
// HOW TO RUN:
//   1. Edit chatUsername below.
//   2. dart run example/18_export_invite_link.dart
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

  try {
    final link = await client.chats.exportInviteLink(chat.id);
    print('Invite link for ${chat.title}: $link');
  } on RpcException catch (e) {
    if (e.description == 'CHAT_ADMIN_REQUIRED') {
      print('You need admin rights (specifically AdminRights.inviteUsers) '
          'in ${chat.title} to export an invite link.');
    } else {
      rethrow;
    }
  }

  await client.disconnect();
}
