// ignore_for_file: file_names, avoid_print

// ============================================================================
// 24 — LISTING BOTS IN A CHAT
// ============================================================================
//
// ParticipantFilter.bots is a server-side filter — useful for chats with
// hundreds of members where paging through everyone with `.recent` to spot
// the handful of bots yourself would be wasteful.
//
// HOW TO RUN:
//   1. Edit groupUsername below to a group/channel that has at least one
//      bot in it.
//   2. dart run example/24_bots_in_chat.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupUsername = 'your_group_here';

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

  final bots =
      await client.members.list(group.id, filter: ParticipantFilter.bots);
  if (bots.isEmpty) {
    print('No bots in ${group.title}.');
  } else {
    print('${bots.length} bot(s) in ${group.title}:');
    for (final p in bots) {
      final handle =
          p.user.username != null ? '@${p.user.username}' : p.user.displayName;
      print('  $handle — role: ${p.role}');
    }
  }

  await client.disconnect();
}
