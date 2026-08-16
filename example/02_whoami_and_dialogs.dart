// ignore_for_file: file_names, avoid_print

// ============================================================================
// 02 — WHOAMI AND DIALOGS
// ============================================================================
//
// Lists your open chats (dialogs) — the same list you'd see scrolling
// Telegram's own chat list. Run 01_login.dart first so a session exists.
//
// HOW TO RUN:
//   dart run example/02_whoami_and_dialogs.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  print('Logged in as user ${client.userId}');
  final me = await client.whoAmI();
  print('${me.displayName} (@${me.username ?? '—'})'
      '${me.isPremium ? ' [Premium]' : ''}\n');

  final dialogs = await client.chats.listDialogs(limit: 30);
  for (final chat in dialogs) {
    final label = switch (chat.kind) {
      ChatKind.private => 'DM',
      ChatKind.group => 'Group',
      ChatKind.supergroup => 'Supergroup',
      ChatKind.channel => 'Channel',
    };
    final members = chat.participantsCount == null
        ? ''
        : ' (${chat.participantsCount} members)';
    print('[$label] ${chat.title}$members — id: ${chat.id}');
  }

  await client.disconnect();
}
