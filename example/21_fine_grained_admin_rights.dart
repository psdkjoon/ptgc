// ignore_for_file: file_names, avoid_print

// ============================================================================
// 21 — FINE-GRAINED ADMIN RIGHTS
// ============================================================================
//
// 04_promote_demote_admin.dart grants one fixed set of rights. This example
// shows the rest of AdminRights: starting from `.full()` and dialing
// specific rights back with `copyWith`, and reading rights back off a
// Participant to see exactly what's granted.
//
// HOW TO RUN:
//   1. Edit groupUsername and memberUsername below.
//   2. dart run example/21_fine_grained_admin_rights.dart
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

  // Start from everything, then take back the one right a "trusted mod,
  // not a co-owner" shouldn't have. (AdminRights.full() never grants
  // `anonymous` in the first place — see its doc comment — so the only
  // right actually being dialed back here is addAdmins.)
  const coOwnerRights = AdminRights.full();
  final trustedModRights = coOwnerRights.copyWith(addAdmins: false);

  await client.members
      .promote(group.id, member.id, trustedModRights, rank: 'Senior Mod');
  print('Promoted ${member.displayName} with a broad-but-not-full rights set.');

  final status = await client.members.get(group.id, member.id);
  final rights = status?.adminRights;
  if (rights != null) {
    print('changeInfo: ${rights.changeInfo}');
    print('deleteMessages: ${rights.deleteMessages}');
    print('banUsers: ${rights.banUsers}');
    print('inviteUsers: ${rights.inviteUsers}');
    print('pinMessages: ${rights.pinMessages}');
    print('addAdmins: ${rights.addAdmins} (deliberately withheld)');
    print('anonymous: ${rights.anonymous} (never granted by .full())');
    print('manageTopics: ${rights.manageTopics}');
  }

  await client.members.demote(group.id, member.id);
  print('Demoted ${member.displayName} back to a regular member.');

  await client.disconnect();
}
