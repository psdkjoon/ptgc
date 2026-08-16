// ignore_for_file: file_names, avoid_print

// ============================================================================
// 13 — CREATE A SUPERGROUP
// ============================================================================
//
// Unlike a basic group (see 12), a supergroup scales past 200 members,
// supports a proper admin hierarchy, and can have a public @username. It's
// what most large "groups" you see on Telegram actually are under the
// hood — a `channel` with `megagroup` set. Unlike createGroup, you don't
// need to name any members up front; you're the sole member until you
// invite people (see 06_invite_members.dart).
//
// HOW TO RUN:
//   dart run example/13_create_supergroup.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const supergroupTitle = 'ptgc test supergroup';
const supergroupAbout =
    'Created by the ptgc 13_create_supergroup.dart example.';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final chatId = await client.chats
      .createSupergroup(supergroupTitle, about: supergroupAbout);
  if (chatId == null) {
    print('Supergroup creation did not return a chat id.');
    await client.disconnect();
    return;
  }

  print('Created "$supergroupTitle" — id: $chatId');

  // You're automatically the creator/owner.
  final me = await client.members.get(chatId, client.userId!);
  print('Your role: ${me?.role}');

  // Grab an invite link right away so you have something to share.
  final link = await client.chats.exportInviteLink(chatId);
  print('Invite link: $link');

  await client.disconnect();
}
