import 'dart:math';
import 'dart:typed_data';

import 'tl.dart' as t;

import 'client.dart';

/// Sends and manages messages. Not the focus of `ptgc` (that's [Members]),
/// but included since a user-account client without basic messaging would
/// be of limited use for verifying/exercising the rest of the API.
///
/// Reached via [TelegramClient.messages] — don't construct this directly.
class Messages {
  Messages(this._client);

  final TelegramClient _client;
  final Random _random = Random.secure();

  /// A signed 64-bit random ID, as `random_id` fields throughout the raw
  /// API require (used server-side for per-session deduplication — it
  /// needs the full 64-bit range to keep collisions negligible).
  int _randomId() {
    final bytes = Uint8List(8);
    for (var i = 0; i < 8; i++) {
      bytes[i] = _random.nextInt(256);
    }
    return ByteData.sublistView(bytes).getInt64(0, Endian.little);
  }

  /// Sends a plain-text message to [chatId] (a user, basic group, or
  /// supergroup/channel — resolved automatically). Returns the new
  /// message's ID.
  Future<int> sendMessage(int chatId, String text) async {
    final randomId = _randomId();
    final updates = await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.messages.sendMessage(
        noWebpage: false,
        silent: false,
        background: false,
        clearDraft: false,
        noforwards: false,
        updateStickersetsOrder: false,
        invertMedia: false,
        allowPaidFloodskip: false,
        peer: _client.peers.inputPeer(chatId),
        message: text,
        randomId: randomId,
      ),
    );
    return _messageIdFromUpdates(updates) ?? 0;
  }

  /// Forwards [messageIds] from [fromChatId] to [toChatId], preserving the
  /// "Forwarded from" attribution.
  Future<void> forwardMessages(
      int fromChatId, List<int> messageIds, int toChatId) async {
    await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.messages.forwardMessages(
        silent: false,
        background: false,
        withMyScore: false,
        dropAuthor: false,
        dropMediaCaptions: false,
        noforwards: false,
        allowPaidFloodskip: false,
        fromPeer: _client.peers.inputPeer(fromChatId),
        id: messageIds,
        randomId: [for (final _ in messageIds) _randomId()],
        toPeer: _client.peers.inputPeer(toChatId),
      ),
    );
  }

  /// Deletes [messageIds] from [chatId]. [revokeForEveryone] deletes them
  /// for the other participant(s) too where Telegram allows it (always
  /// true in your own DMs/groups; time-limited elsewhere).
  Future<void> deleteMessages(int chatId, List<int> messageIds,
      {bool revokeForEveryone = true}) async {
    if (_client.peers.isChannel(chatId)) {
      await _client.callRaw<t.MessagesAffectedMessagesBase>(
        () => _client.raw.channels.deleteMessages(
          channel: _client.peers.inputChannel(chatId),
          id: messageIds,
        ),
      );
      return;
    }
    await _client.callRaw<t.MessagesAffectedMessagesBase>(
      () => _client.raw.messages
          .deleteMessages(revoke: revokeForEveryone, id: messageIds),
    );
  }

  int? _messageIdFromUpdates(t.UpdatesBase updates) {
    switch (updates) {
      case t.UpdateShortSentMessage():
        return updates.id;
      case t.Updates():
        _client.peers.feed(users: updates.users, chats: updates.chats);
        for (final u in updates.updates) {
          if (u is t.UpdateMessageID) return u.id;
        }
        for (final u in updates.updates) {
          if (u is t.UpdateNewMessage && u.message is t.Message) {
            return (u.message as t.Message).id;
          }
        }
        return null;
      case t.UpdatesCombined():
        _client.peers.feed(users: updates.users, chats: updates.chats);
        for (final u in updates.updates) {
          if (u is t.UpdateMessageID) return u.id;
        }
        // Same fallback as the [t.Updates] case above — some responses
        // (e.g. messages to a channel) carry the new message only as an
        // UpdateNewMessage, with no separate UpdateMessageID.
        for (final u in updates.updates) {
          if (u is t.UpdateNewMessage && u.message is t.Message) {
            return (u.message as t.Message).id;
          }
        }
        return null;
      default:
        return null;
    }
  }
}
