// ignore_for_file: file_names, avoid_print

// ============================================================================
// 05 — LIST AND SEARCH MEMBERS
// ============================================================================
//
// Pages through a chat's member list, and demonstrates the different
// ParticipantFilter values (admins, banned, restricted, bots, search).
//
// HOW TO RUN:
//   1. Edit groupUsername below.
//   2. dart run example/05_list_and_search_members.dart
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
    print('Could not resolve $groupUsername.');
    await client.disconnect();
    return;
  }
  final groupId = group.id;

  print('-- Recent members --');
  final recent = await client.members.list(groupId, limit: 20);
  for (final p in recent) {
    print('${p.user.displayName} (${p.role})');
  }

  print('\n-- Admins --');
  final admins =
      await client.members.list(groupId, filter: ParticipantFilter.admins);
  for (final p in admins) {
    print(
        '${p.user.displayName}${p.rank != null && p.rank!.isNotEmpty ? " [${p.rank}]" : ""}');
  }

  print('\n-- Search for "john" --');
  final results = await client.members
      .list(groupId, filter: ParticipantFilter.search, query: 'john');
  for (final p in results) {
    print(p.user.displayName);
  }

  // Paging: pass the offset of the last page to keep going.
  print('\n-- Next page --');
  final page2 = await client.members.list(groupId, offset: 20, limit: 20);
  print('${page2.length} more members.');

  await client.disconnect();
}
