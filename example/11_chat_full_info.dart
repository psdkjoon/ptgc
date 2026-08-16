// ignore_for_file: file_names, avoid_print

// ============================================================================
// 11 — CHAT FULL INFO
// ============================================================================
//
// listDialogs and Members.list give you a PtgcChat already, but a few
// fields — the "about" description in particular — only come back from
// Chats.getFullInfo, a separate round-trip Telegram requires for the
// heavier chat/channel metadata.
//
// HOW TO RUN:
//   1. Edit chatUsername below.
//   2. dart run example/11_chat_full_info.dart
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
    print('Could not resolve @$chatUsername.');
    await client.disconnect();
    return;
  }

  final full = await client.chats.getFullInfo(chat.id);
  if (full.isForbidden) {
    print('${full.title.isEmpty ? chatUsername : full.title}: no longer '
        'accessible (you may have been removed).');
    await client.disconnect();
    return;
  }

  print('${full.title} (${full.kind})');
  print('Members: ${full.participantsCount ?? 'unknown'}');
  print(
      'Verified: ${full.isVerified}, Scam: ${full.isScam}, Fake: ${full.isFake}');
  if (full.username != null) print('Public link: t.me/${full.username}');

  await client.disconnect();
}
