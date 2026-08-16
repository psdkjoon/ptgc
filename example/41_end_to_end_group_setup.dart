// ignore_for_file: file_names, avoid_print

// ============================================================================
// 41 — END TO END: STAND UP A MODERATED GROUP
// ============================================================================
//
// A combined walkthrough rather than a single feature: create a supergroup
// (13), invite some people (06), promote one of them to a trusted-mod rights
// set (21), post a welcome message (08), and hand back an invite link (18)
// to share with everyone else. Each step here is documented in depth in its
// own numbered example — this just shows them composed into one script,
// which is closer to how you'd actually use ptgc for a real setup task.
//
// HOW TO RUN:
//   1. Edit groupTitle, memberUsernames, and moderatorUsername below.
//   2. dart run example/41_end_to_end_group_setup.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupTitle = 'ptgc demo — moderated group';
const groupAbout = 'Set up end-to-end by the ptgc 41 example.';
const memberUsernames = ['someone_one', 'someone_two'];
const moderatorUsername = 'someone_one';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  // 1. Create the supergroup.
  final chatId =
      await client.chats.createSupergroup(groupTitle, about: groupAbout);
  if (chatId == null) {
    print('Group creation failed.');
    await client.disconnect();
    return;
  }
  print('1/5 Created "$groupTitle" — id: $chatId');

  // 2. Resolve and invite members.
  final memberIds = <int>[];
  for (final username in memberUsernames) {
    final user = await client.contacts.resolveUsername(username);
    if (user != null) memberIds.add(user.id);
  }
  final failed = await client.members.invite(chatId, memberIds);
  print(
      '2/5 Invited ${memberIds.length - failed.length}/${memberIds.length} member(s)'
      '${failed.isEmpty ? '' : ' (failed: $failed)'}');

  // 3. Promote one of them to a trusted-mod rights set (see 21 for why
  //    addAdmins is withheld here — anonymous is never granted by
  //    AdminRights.full() in the first place).
  final moderator = await client.contacts.resolveUsername(moderatorUsername);
  if (moderator != null && memberIds.contains(moderator.id)) {
    const coOwnerRights = AdminRights.full();
    final trustedModRights = coOwnerRights.copyWith(addAdmins: false);
    await client.members
        .promote(chatId, moderator.id, trustedModRights, rank: 'Mod');
    print('3/5 Promoted ${moderator.displayName} to moderator.');
  } else {
    print(
        '3/5 Skipped promotion — $moderatorUsername was not resolved/invited.');
  }

  // 4. Post a welcome message.
  await client.messages.sendMessage(
    chatId,
    'Welcome! This group is moderated — please keep things on-topic.',
  );
  print('4/5 Posted a welcome message.');

  // 5. Hand back an invite link for anyone else you want to add later.
  final link = await client.chats.exportInviteLink(chatId);
  print('5/5 Invite link: $link');

  await client.disconnect();
}
