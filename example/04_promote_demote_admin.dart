// ignore_for_file: file_names, avoid_print

// ============================================================================
// 04 — PROMOTE / DEMOTE ADMIN
// ============================================================================
//
// Grants and revokes admin rights. AdminRights lets you pick exactly which
// privileges to grant — or use `.full()` for "give everything".
//
// HOW TO RUN:
//   1. Edit groupUsername and memberUsername below. Your account needs
//      admin rights with "add new admins" to promote/demote others.
//   2. dart run example/04_promote_demote_admin.dart
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

  final member = await client.contacts.resolveUsername(memberUsername);
  final group = await client.chats.resolveUsername(groupUsername);

  if (member == null || group == null) {
    print('Could not resolve $memberUsername or $groupUsername.');
    await client.disconnect();
    return;
  }
  final groupId = group.id;

  // Grant a specific, limited set of rights — a moderator who can delete
  // messages and ban users, but can't add other admins or change chat info.
  await client.members.promote(
    groupId,
    member.id,
    const AdminRights(
        deleteMessages: true,
        banUsers: true,
        inviteUsers: true,
        pinMessages: true),
    rank: 'Mod',
  );
  print('Promoted ${member.displayName} to a limited admin.');

  final status = await client.members.get(groupId, member.id);
  print(
      'Now: ${status?.role}, rights: ${status?.adminRights?.banUsers == true ? "can ban" : "cannot ban"}');

  // Revoke it entirely.
  await client.members.demote(groupId, member.id);
  print('Demoted ${member.displayName} back to a regular member.');

  await client.disconnect();
}
