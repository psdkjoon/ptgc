// ignore_for_file: file_names, avoid_print

// ============================================================================
// 10 — RESOLVE A CHAT BY USERNAME
// ============================================================================
//
// Contacts.resolveUsername (see 03/07/09) only ever returns a PtgcUser — it
// hands back null for a group/channel username. Chats.resolveUsername is
// the counterpart for those: pass a public group/supergroup/channel
// @username and get a full PtgcChat back (title, kind, member count, your
// own admin rights if any, ...), with its access hash cached exactly like
// Contacts.resolveUsername does for users.
//
// HOW TO RUN:
//   1. Edit chatUsername below to a public supergroup/channel you're a
//      member of (or any public one, for the read-only fields).
//   2. dart run example/10_resolve_chat_by_username.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const chatUsername = 'your_group_or_channel_here';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final chat = await client.chats.resolveUsername(chatUsername);
  if (chat == null) {
    print('Could not resolve @$chatUsername to a chat — either it does not '
        'exist, or it belongs to a user (try Contacts.resolveUsername '
        'instead — see 07_contacts_and_blocking.dart).');
    await client.disconnect();
    return;
  }

  print('${chat.title} (${chat.kind}) — id: ${chat.id}');
  if (chat.participantsCount != null) {
    print('${chat.participantsCount} members');
  }
  if (chat.isCreator) print('You created this chat.');
  if (chat.adminRights != null) print('You are an admin here.');

  // The chat's ID is now usable everywhere else in ptgc, same as if you'd
  // seen it via listDialogs or Members.list.
  final admins =
      await client.members.list(chat.id, filter: ParticipantFilter.admins);
  print('${admins.length} admin(s).');

  await client.disconnect();
}
