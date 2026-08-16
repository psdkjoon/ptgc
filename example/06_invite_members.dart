// ignore_for_file: file_names, avoid_print

// ============================================================================
// 06 — INVITE MEMBERS
// ============================================================================
//
// Adds users to a chat directly, without going through an invite link —
// something bots generally can't do at all. Works for public
// groups/channels for any user; for private ones, you need to already be a
// member with invite rights, and the target's own privacy settings can
// still block it (that's what the returned "failed" list is for).
//
// HOW TO RUN:
//   1. Edit groupUsername and the list of usernames to invite below.
//   2. dart run example/06_invite_members.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupUsername = 'your_group_here';
const usernamesToInvite = ['someone_here', 'someone_else_here'];

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final group = await client.chats.resolveUsername(groupUsername);
  if (group == null) {
    print('Could not resolve $groupUsername.');
    await client.disconnect();
    return;
  }
  final groupId = group.id;

  final userIds = <int>[];
  for (final username in usernamesToInvite) {
    final user = await client.contacts.resolveUsername(username);
    if (user != null) userIds.add(user.id);
  }

  final failed = await client.members.invite(groupId, userIds);

  print('Invited ${userIds.length - failed.length}/${userIds.length} users.');
  if (failed.isNotEmpty) {
    print('Could not add (likely privacy settings): $failed');
  }

  await client.disconnect();
}
