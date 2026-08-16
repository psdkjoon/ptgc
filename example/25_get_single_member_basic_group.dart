// ignore_for_file: file_names, avoid_print

// ============================================================================
// 25 — LOOKING UP A MEMBER IN A BASIC GROUP
// ============================================================================
//
// Members.get takes a different path server-side depending on chat kind:
// for supergroups/channels it's a single direct lookup
// (channels.getParticipant); for basic groups there's no such call, so
// ptgc fetches the full (≤200-member) list and searches it locally — see
// the "basic groups cap out at 200 members" note in Members.get's doc
// comment. Same public API either way, so your calling code doesn't need
// to branch on chat kind.
//
// HOW TO RUN:
//   1. Edit groupUsername (a *basic*, non-super group — e.g. one made with
//      12_create_basic_group.dart) and memberUsername below.
//   2. dart run example/25_get_single_member_basic_group.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupUsername = 'your_basic_group_here';
const memberUsername = 'someone_here';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  // Basic groups have no username at all, so resolveUsername won't find
  // one — look it up via your dialogs instead.
  final dialogs = await client.chats.listDialogs(limit: 50);
  final group = dialogs
      .where((c) => c.title == groupUsername || c.kind == ChatKind.group)
      .firstOrNull;
  final member = await client.contacts.resolveUsername(memberUsername);

  if (group == null || member == null) {
    print('Could not find a basic group titled "$groupUsername" in your '
        'dialogs, or could not resolve $memberUsername.');
    await client.disconnect();
    return;
  }

  final participant = await client.members.get(group.id, member.id);
  if (participant == null) {
    print('${member.displayName} is not a member of ${group.title}.');
  } else {
    print('${member.displayName} in ${group.title}: role ${participant.role}, '
        'joined ${participant.joinedAt}');
  }

  await client.disconnect();
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
