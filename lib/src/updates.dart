import 'tl.dart' as t;

import 'peer_cache.dart';

/// Base type for everything delivered on [TelegramClient.events].
///
/// This is a best-effort, high-signal subset of Telegram's update system —
/// new messages and membership/admin changes, the events most automation
/// cares about. For anything else, listen to [TelegramClient.raw]'s
/// `.stream` directly for the full raw `t.UpdatesBase` feed.
sealed class TelegramEvent {
  const TelegramEvent();
}

/// A new message was sent or received.
class NewMessageEvent extends TelegramEvent {
  final int messageId;

  /// The chat (user, group, or channel) this message belongs to.
  final int chatId;

  /// Who sent it, if known (may be null for channel posts, service
  /// messages, etc).
  final int? senderId;

  /// The message text (empty for pure-media messages).
  final String text;

  /// True if this account sent it.
  final bool isOutgoing;

  final DateTime date;

  const NewMessageEvent({
    required this.messageId,
    required this.chatId,
    required this.senderId,
    required this.text,
    required this.isOutgoing,
    required this.date,
  });

  @override
  String toString() => 'NewMessageEvent(chat: $chatId, from: $senderId, text: '
      '${text.length > 40 ? '${text.substring(0, 40)}…' : text})';
}

/// A member's status changed in a basic group or a supergroup/channel —
/// joined, left, was banned/restricted, or had their admin rights changed.
///
/// This fires for the *target* of the change; check [Members.get] if you
/// need the resulting role/rights spelled out as a [Participant].
class MemberStatusChangedEvent extends TelegramEvent {
  final int chatId;

  /// The member whose status changed.
  final int userId;

  /// Who made the change (an admin, or [userId] itself if they left/joined
  /// on their own).
  final int actorId;

  final DateTime date;

  const MemberStatusChangedEvent({
    required this.chatId,
    required this.userId,
    required this.actorId,
    required this.date,
  });

  @override
  String toString() =>
      'MemberStatusChangedEvent(chat: $chatId, user: $userId, by: $actorId)';
}

/// Maps a raw [t.UpdatesBase] envelope into zero or more [TelegramEvent]s.
/// [peers] is consulted (not fed — [TelegramClient] does that separately)
/// to resolve `self` when needed.
List<TelegramEvent> eventsFromRawUpdates(
    t.UpdatesBase envelope, PeerCache peers) {
  switch (envelope) {
    case t.Updates():
      return [for (final u in envelope.updates) ..._fromUpdate(u)];
    case t.UpdatesCombined():
      return [for (final u in envelope.updates) ..._fromUpdate(u)];
    case t.UpdateShort():
      return _fromUpdate(envelope.update);
    case t.UpdateShortMessage():
      return [
        NewMessageEvent(
          messageId: envelope.id,
          chatId: envelope.userId,
          senderId: envelope.out ? peers.selfId : envelope.userId,
          text: envelope.message,
          isOutgoing: envelope.out,
          date: envelope.date,
        ),
      ];
    default:
      return const [];
  }
}

List<TelegramEvent> _fromUpdate(t.UpdateBase update) {
  switch (update) {
    case t.UpdateNewMessage():
      final message = update.message;
      if (message is! t.Message) return const [];
      return [
        NewMessageEvent(
          messageId: message.id,
          chatId: idOfPeer(message.peerId),
          senderId: message.fromId == null ? null : idOfPeer(message.fromId!),
          text: message.message,
          isOutgoing: message.out,
          date: message.date,
        ),
      ];
    case t.UpdateChatParticipant():
      return [
        MemberStatusChangedEvent(
          chatId: update.chatId,
          userId: update.userId,
          actorId: update.actorId,
          date: update.date,
        ),
      ];
    case t.UpdateChannelParticipant():
      return [
        MemberStatusChangedEvent(
          chatId: update.channelId,
          userId: update.userId,
          actorId: update.actorId,
          date: update.date,
        ),
      ];
    default:
      return const [];
  }
}
