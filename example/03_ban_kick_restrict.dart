// ignore_for_file: file_names, avoid_print

// ============================================================================
// 03 — BAN, KICK, RESTRICT
// ============================================================================
//
// The core reason ptgc exists: controlling chat membership as a user
// account. This example resolves a group by username and a member by
// username, then walks through the main member-control operations.
//
// HOW TO RUN:
//   1. Edit GROUP_USERNAME and MEMBER_USERNAME below.
//   2. Your account needs to already be a member (and, for restrict/ban to
//      actually take effect, an admin with ban rights) of the group.
//   3. dart run example/03_ban_kick_restrict.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupUsername = 'your_group_here';
const memberUsername = 'someone_here';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  // Resolving by username also caches the access hash ptgc needs to act on
  // this chat/user by plain ID afterwards — see PeerCache in the README.
  // Note: Contacts.resolveUsername only returns *users* — a group/channel
  // username needs Chats.resolveUsername instead.
  final group = await client.chats.resolveUsername(groupUsername);
  final member = await client.contacts.resolveUsername(memberUsername);

  if (group == null || member == null) {
    print('Could not resolve $groupUsername or $memberUsername.');
    await client.disconnect();
    return;
  }

  final groupId = group.id;

  print('Current status: ${await client.members.get(groupId, member.id)}');

  // Mute them for an hour without removing them from the chat.
  await client.members.restrict(
    groupId,
    member.id,
    BannedRights(
        sendMessages: true,
        until: DateTime.now().add(const Duration(hours: 1))),
  );
  print('Restricted ${member.displayName} for 1 hour.');

  // Lift that restriction early.
  await client.members.unban(groupId, member.id);
  print('Restriction lifted.');

  // Remove them but let them rejoin later (a "kick" in the everyday sense).
  await client.members.kick(groupId, member.id);
  print('Kicked ${member.displayName} (they can rejoin via invite link).');

  // A permanent ban — they can't rejoin until explicitly unbanned.
  // await client.members.ban(groupId, member.id);
  // await client.members.unban(groupId, member.id); // to reverse it

  await client.disconnect();
}
