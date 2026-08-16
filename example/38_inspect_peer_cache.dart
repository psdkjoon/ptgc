// ignore_for_file: file_names, avoid_print

// ============================================================================
// 38 — INSPECTING THE PEER CACHE DIRECTLY
// ============================================================================
//
// Every namespace (Contacts, Chats, Members, Messages) uses
// TelegramClient.peers internally to turn plain IDs into the access-hash-
// bearing InputPeer/InputUser/InputChannel Telegram's raw API demands (see
// PeerCache's doc comment, and the README's "How this package works"
// section). It's public, so you can query it yourself too — handy for
// debugging "why did I get PeerNotFoundException" (see
// 31_handle_peer_not_found.dart), or for a quick kind-of-this-id check
// without an extra round trip.
//
// This drops to the raw `t.*` types for cachedUser/cachedChat, since those
// return whatever ptgc last saw on the wire, before any PtgcUser/PtgcChat
// wrapping happens.
//
// HOW TO RUN:
//   dart run example/38_inspect_peer_cache.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';
import 'package:ptgc/raw.dart' as raw;

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  // Populate the cache the normal way — listing dialogs feeds every user
  // and chat it sees into PeerCache, same as every other namespace call.
  final dialogs = await client.chats.listDialogs(limit: 20);

  for (final chat in dialogs.take(5)) {
    print(
        '${chat.title}: kindOf(${chat.id}) = ${client.peers.kindOf(chat.id)}, '
        'isChannel: ${client.peers.isChannel(chat.id)}');

    final cached = client.peers.cachedChat(chat.id);
    if (cached is raw.Channel) {
      print(
          '  raw access hash: ${cached.accessHash}, megagroup: ${cached.megagroup}');
    }
  }

  // idForUsername answers "have I already resolved this @username this
  // session" without making a network call.
  const someUsername = 'durov';
  final cachedId = client.peers.idForUsername(someUsername);
  print('idForUsername("$someUsername") before resolving: $cachedId');

  await client.contacts.resolveUsername(someUsername);
  print('idForUsername("$someUsername") after resolving: '
      '${client.peers.idForUsername(someUsername)}');

  await client.disconnect();
}
