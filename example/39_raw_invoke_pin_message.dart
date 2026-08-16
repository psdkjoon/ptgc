// ignore_for_file: file_names, avoid_print

// ============================================================================
// 39 — RAW INVOKE: PINNING A MESSAGE
// ============================================================================
//
// A second example of the escape hatch from 09_raw_invoke_escape_hatch.dart —
// pinning isn't wrapped by any ptgc namespace, so this goes straight at
// messages.updatePinnedMessage. The pattern is always the same: build the
// InputPeer yourself via client.peers (same helper every ptgc namespace
// method uses internally), then call client.invoke with the raw TL method.
//
// HOW TO RUN:
//   1. Edit chatUsername and messageId below (send yourself a message with
//      08_send_and_listen.dart first if you need a message id).
//   2. dart run example/39_raw_invoke_pin_message.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';
import 'package:ptgc/raw.dart' as t;

const chatUsername = 'your_chat_here';
const messageId = 123;

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

  await client.invoke(
    t.MessagesUpdatePinnedMessage(
      silent: false,
      unpin: false,
      pmOneside: false,
      peer: client.peers.inputPeer(chat.id),
      id: messageId,
    ),
  );
  print('Pinned message $messageId in ${chat.title}.');

  await client.disconnect();
}
