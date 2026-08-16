// ignore_for_file: file_names, avoid_print

// ============================================================================
// 22 — FINE-GRAINED RESTRICTIONS
// ============================================================================
//
// 03_ban_kick_restrict.dart mutes with a single `sendMessages: true`
// restriction. BannedRights has a lot more granularity than that — you can
// let someone keep texting while blocking just media, or just stickers/
// GIFs, or just their ability to invite others. Remember: every field here
// is something being *taken away*, same as Telegram's own ChatBannedRights.
//
// HOW TO RUN:
//   1. Edit groupUsername and memberUsername below.
//   2. dart run example/22_fine_grained_restrictions.dart
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

  final group = await client.chats.resolveUsername(groupUsername);
  final member = await client.contacts.resolveUsername(memberUsername);
  if (group == null || member == null) {
    print('Could not resolve $groupUsername or $memberUsername.');
    await client.disconnect();
    return;
  }

  // "No media, but you can still chat" — good for a channel/group that's
  // getting spammed with images without silencing the person entirely.
  const mediaOnlyBlock =
      BannedRights(sendMedia: true, sendStickers: true, sendGifs: true);
  await client.members.restrict(group.id, member.id, mediaOnlyBlock);
  print(
      '${member.displayName} can still send text, but no media/stickers/GIFs.');

  var status = await client.members.get(group.id, member.id);
  print(
      'sendMessages restricted: ${status?.bannedRights?.sendMessages} (should be false)');
  print(
      'sendMedia restricted: ${status?.bannedRights?.sendMedia} (should be true)');

  // "Can chat, but can't invite others" — for a member you trust to
  // participate but not to grow the group's membership.
  const noInvitesRestriction = BannedRights(inviteUsers: true);
  await client.members.restrict(group.id, member.id, noInvitesRestriction);
  print('${member.displayName} can no longer invite others.');

  await client.members.unban(group.id, member.id);
  print('All restrictions lifted.');

  await client.disconnect();
}
