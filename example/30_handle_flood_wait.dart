// ignore_for_file: file_names, avoid_print

// ============================================================================
// 30 — HANDLING FLOOD WAITS
// ============================================================================
//
// Telegram rate-limits aggressively, especially for actions like inviting
// members or messaging users you haven't talked to before. Every ptgc call
// that hits the wire can throw FloodWaitException — this example shows the
// standard "wait it out and retry once" pattern. For a loop over many
// items (e.g. inviting a list of users), catch it per-item rather than
// around the whole loop, so one flood wait doesn't abandon the rest.
//
// HOW TO RUN:
//   1. Edit groupUsername and memberUsernames below.
//   2. dart run example/30_handle_flood_wait.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupUsername = 'your_group_here';
const memberUsernames = ['someone_one', 'someone_two', 'someone_three'];

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
    print('Could not resolve @$groupUsername.');
    await client.disconnect();
    return;
  }

  for (final username in memberUsernames) {
    final user = await client.contacts.resolveUsername(username);
    if (user == null) {
      print('Could not resolve $username, skipping.');
      continue;
    }

    // Members.invite already reports individual failures via its return
    // value (see 06_invite_members.dart) — this wraps the whole call
    // instead, since a flood wait is a transport-level failure, not a
    // per-user one.
    try {
      await client.members.invite(group.id, [user.id]);
      print('Invited ${user.displayName}.');
    } on FloodWaitException catch (e) {
      print('Flood wait: sleeping ${e.duration.inSeconds}s before retrying '
          '${user.displayName}...');
      await Future<void>.delayed(e.duration);
      await client.members.invite(group.id, [user.id]);
      print('Invited ${user.displayName} (after waiting).');
    }
  }

  await client.disconnect();
}
