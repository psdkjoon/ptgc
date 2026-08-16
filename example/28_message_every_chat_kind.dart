// ignore_for_file: file_names, avoid_print

// ============================================================================
// 28 — MESSAGING EVERY CHAT KIND
// ============================================================================
//
// Messages.sendMessage takes the same plain chat id no matter what kind of
// chat it is — ptgc's PeerCache resolves the right InputPeer variant
// internally (see the README's "How this package works" section). This
// example walks all four ChatKind values from your dialogs and posts to
// one of each, so the uniformity is visible rather than just asserted.
//
// HOW TO RUN:
//   dart run example/28_message_every_chat_kind.dart
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

  final dialogs = await client.chats.listDialogs(limit: 100);
  final oneOfEach = <ChatKind, PtgcChat>{};
  for (final chat in dialogs) {
    oneOfEach.putIfAbsent(chat.kind, () => chat);
  }

  if (oneOfEach.isEmpty) {
    print('No dialogs found.');
    await client.disconnect();
    return;
  }

  for (final entry in oneOfEach.entries) {
    final kind = entry.key;
    final chat = entry.value;
    final text = switch (kind) {
      ChatKind.private => 'Hey! (sent by the ptgc 28 example)',
      ChatKind.group => 'Hello, basic group! (sent by the ptgc 28 example)',
      ChatKind.supergroup => 'Hello, supergroup! (sent by the ptgc 28 example)',
      ChatKind.channel => 'Announcement test (sent by the ptgc 28 example)',
    };
    try {
      await client.messages.sendMessage(chat.id, text);
      print('Sent to ${chat.title} ($kind).');
    } on RpcException catch (e) {
      // e.g. CHAT_WRITE_FORBIDDEN in a channel you can only read.
      print('Could not send to ${chat.title} ($kind): ${e.description}');
    }
  }

  await client.disconnect();
}
