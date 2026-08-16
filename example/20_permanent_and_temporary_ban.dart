// ignore_for_file: file_names, avoid_print

// ============================================================================
// 20 — PERMANENT AND TEMPORARY BANS
// ============================================================================
//
// 03_ban_kick_restrict.dart leaves the permanent ban commented out. This
// example runs both forms explicitly: a temporary ban that lifts itself,
// and a permanent one you have to unban() yourself — plus how to tell
// which kind is currently active on a member.
//
// HOW TO RUN:
//   1. Edit groupUsername and memberUsername below.
//   2. dart run example/20_permanent_and_temporary_ban.dart
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

  // Temporary: lifts itself after 5 minutes. Telegram treats anything
  // under 30 seconds as permanent, so this is close to the practical floor.
  final until = DateTime.now().add(const Duration(minutes: 5));
  await client.members.ban(group.id, member.id, until: until);
  var status = await client.members.get(group.id, member.id);
  print('Banned until ${status?.bannedRights?.until} (temporary).');

  await client.members.unban(group.id, member.id);
  print('Unbanned early.');

  // Permanent: no `until` at all — stays banned until you explicitly
  // unban() them, even if they try to rejoin via invite link.
  await client.members.ban(group.id, member.id);
  status = await client.members.get(group.id, member.id);
  print(
      'Banned until: ${status?.bannedRights?.until ?? "forever (permanent)"}.');

  await client.members.unban(group.id, member.id);
  print('Unbanned — reversing the permanent ban.');

  await client.disconnect();
}
