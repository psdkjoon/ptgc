// ignore_for_file: file_names, avoid_print

// ============================================================================
// 23 — BANNED VS RESTRICTED: THE FILTER GOTCHA
// ============================================================================
//
// Telegram's own naming here is confusing, and it carries straight through
// to ptgc's ParticipantFilter: `ParticipantFilter.banned` does NOT mean
// "everyone who currently has any restriction applied". It means
// "everyone whose restrictions include viewMessages" — i.e. people who are
// fully kicked out and can't even see the chat. Someone who's merely
// muted (restricted from sendMessages but can still read) shows up under
// `ParticipantFilter.restricted`, a *different* filter, not `.banned`.
//
// This example lists both filters side by side so the distinction is
// concrete instead of just a doc comment.
//
// HOW TO RUN:
//   1. Edit groupUsername below to a supergroup where you have both a
//      fully-banned member and a merely-restricted (muted) one — run
//      03_ban_kick_restrict.dart and 22_fine_grained_restrictions.dart
//      first if you need to set that up.
//   2. dart run example/23_banned_vs_restricted_filter.dart
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

  final banned =
      await client.members.list(group.id, filter: ParticipantFilter.banned);
  print('ParticipantFilter.banned (viewMessages revoked — fully kicked out):');
  for (final p in banned) {
    print('  ${p.user.displayName} — role: ${p.role}');
  }

  final restricted =
      await client.members.list(group.id, filter: ParticipantFilter.restricted);
  print(
      'ParticipantFilter.restricted (some other right revoked, can still read):');
  for (final p in restricted) {
    print('  ${p.user.displayName} — role: ${p.role}, sendMessages blocked: '
        '${p.bannedRights?.sendMessages}');
  }

  await client.disconnect();
}
