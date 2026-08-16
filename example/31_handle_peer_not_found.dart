// ignore_for_file: file_names, avoid_print

// ============================================================================
// 31 — HANDLING "PEER NOT FOUND"
// ============================================================================
//
// ptgc can only build a request for a user/chat/channel it has an access
// hash cached for (see PeerCache in the README) — which means it has to
// have seen that peer at least once this session, via listDialogs,
// Members.list, a resolveUsername call, an incoming event, etc. Acting on
// a bare numeric ID you got from somewhere else (a database, a log file,
// ...) without having "seen" it in this session throws
// PeerNotFoundException instead of silently failing or guessing.
//
// HOW TO RUN:
//   dart run example/31_handle_peer_not_found.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

// An arbitrary numeric id this fresh session has never actually seen.
const unseenUserId = 999999999999;

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  try {
    await client.messages.sendMessage(unseenUserId, 'hi');
  } on PeerNotFoundException catch (e) {
    print('As expected: ${e.message}');
    print('Fix: resolve the peer first — e.g. '
        'client.contacts.resolveUsername(...), client.chats.resolveUsername(...), '
        'or client.chats.listDialogs() — before acting on its id.');
  }

  await client.disconnect();
}
