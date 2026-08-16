import 'tl.dart' as t;

import 'client.dart';
import 'enums.dart';
import 'exceptions.dart';
import 'models.dart';
import 'peer_cache.dart';
import 'rights.dart';

/// Controls chat membership: banning, kicking, restricting, promoting, and
/// listing members of a group, supergroup, or channel.
///
/// This is the core of what `ptgc` adds over the Bot API: acting *as a
/// user account*, including in ways bots often can't (e.g. inviting
/// members to a public channel without them clicking a link).
///
/// [chatId] throughout this class is the same ID you'd get from
/// [Chats.listDialogs] or [Members.list] — `ptgc` figures out on its own
/// whether it's a basic group or a supergroup/channel and calls the right
/// raw method. You do need to have *seen* the chat at least once this
/// session (dialogs, a search, a previous call) so its access hash is
/// cached — see [PeerCache].
///
/// Reached via [TelegramClient.members] — don't construct this directly.
class Members {
  Members(this._client);

  final TelegramClient _client;

  /// Lists members of [chatId].
  ///
  /// [filter] narrows the results for supergroups/channels (ignored for
  /// basic groups, which always return everyone). [query] is required by
  /// [ParticipantFilter.search] and optional for [ParticipantFilter.banned]
  /// / [ParticipantFilter.restricted] (narrows by name there too).
  /// [offset]/[limit] page through large lists — Telegram caps [limit] at
  /// 200 per call.
  Future<List<Participant>> list(
    int chatId, {
    ParticipantFilter filter = ParticipantFilter.recent,
    String query = '',
    int offset = 0,
    int limit = 200,
  }) async {
    if (_client.peers.isChannel(chatId)) {
      final result = await _client.callRaw<t.ChannelsChannelParticipantsBase>(
        () => _client.raw.channels.getParticipants(
          channel: _client.peers.inputChannel(chatId),
          filter: _rawFilter(filter, query),
          offset: offset,
          limit: limit,
          hash: 0,
        ),
      );
      if (result is! t.ChannelsChannelParticipants) return const [];
      _client.peers.feed(users: result.users, chats: result.chats);
      final byId = {
        for (final u in result.users) idOfUser(u): PtgcUser.fromRaw(u)
      };
      return [
        for (final p in result.participants)
          Participant.fromChannelParticipant(p, byId)
      ];
    }

    // Basic groups don't page or filter server-side — Telegram always
    // hands back the full member list via the chat's "full info".
    final fullChatResult = await _client.callRaw<t.MessagesChatFullBase>(
      () => _client.raw.messages.getFullChat(chatId: chatId),
    );
    if (fullChatResult is! t.MessagesChatFull) return const [];
    _client.peers
        .feed(users: fullChatResult.users, chats: fullChatResult.chats);
    final byId = {
      for (final u in fullChatResult.users) idOfUser(u): PtgcUser.fromRaw(u)
    };
    final full = fullChatResult.fullChat;
    if (full is! t.ChatFull) return const [];
    final participants = full.participants;
    if (participants is! t.ChatParticipants) return const [];
    return [
      for (final p in participants.participants)
        Participant.fromChatParticipant(p, byId)
    ];
  }

  /// Looks up a single member's status. Returns `null` if [userId] isn't a
  /// member of [chatId].
  Future<Participant?> get(int chatId, int userId) async {
    if (_client.peers.isChannel(chatId)) {
      try {
        final result = await _client.callRaw<t.ChannelsChannelParticipantBase>(
          () => _client.raw.channels.getParticipant(
            channel: _client.peers.inputChannel(chatId),
            participant: _client.peers.inputPeerUser(userId),
          ),
        );
        if (result is! t.ChannelsChannelParticipant) return null;
        _client.peers.feed(users: result.users, chats: result.chats);
        final byId = {
          for (final u in result.users) idOfUser(u): PtgcUser.fromRaw(u)
        };
        return Participant.fromChannelParticipant(result.participant, byId);
      } on RpcException catch (e) {
        if (e.description == 'USER_NOT_PARTICIPANT') return null;
        rethrow;
      }
    }

    final all = await list(chatId);
    for (final p in all) {
      if (p.user.id == userId) return p;
    }
    return null;
  }

  /// Fully bans [userId] from [chatId] — they're removed immediately and
  /// can't rejoin, even via invite link, until [unban]ned. Pass [until]
  /// for a temporary ban; omit it for permanent.
  ///
  /// If you want them removable-but-rejoinable instead (a "kick" in the
  /// usual sense), use [kick].
  Future<void> ban(int chatId, int userId, {DateTime? until}) async {
    if (_client.peers.isChannel(chatId)) {
      final updates = await _client.callRaw<t.UpdatesBase>(
        () => _client.raw.channels.editBanned(
          channel: _client.peers.inputChannel(chatId),
          participant: _client.peers.inputPeerUser(userId),
          bannedRights: BannedRights.banned(until: until).toRaw(),
        ),
      );
      _feedUpdates(updates);
      return;
    }
    final updates = await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.messages.deleteChatUser(
        revokeHistory: false,
        chatId: chatId,
        userId: _client.peers.inputUser(userId),
      ),
    );
    _feedUpdates(updates);
  }

  /// Removes [userId] from [chatId] without a lasting ban — they can
  /// rejoin later (e.g. via invite link). This is what most people mean by
  /// "kick".
  ///
  /// Supergroups/channels have no separate "kick" RPC, so this bans and
  /// immediately unbans — Telegram's own idiom for the same effect.
  Future<void> kick(int chatId, int userId) async {
    await ban(chatId, userId);
    if (_client.peers.isChannel(chatId)) {
      await unban(chatId, userId);
    }
  }

  /// Lifts a [ban]/[restrict] on [userId] in [chatId]. No-op for basic
  /// groups, which have no persistent banned state — removing a member
  /// there ([ban]) already just ends their membership.
  Future<void> unban(int chatId, int userId) async {
    if (!_client.peers.isChannel(chatId)) return;
    final updates = await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.channels.editBanned(
        channel: _client.peers.inputChannel(chatId),
        participant: _client.peers.inputPeerUser(userId),
        bannedRights: const BannedRights.none().toRaw(),
      ),
    );
    _feedUpdates(updates);
  }

  /// Applies specific restrictions to [userId] in [chatId] (e.g. mute
  /// them, or block them from sending media) without removing them from
  /// the chat. Supergroups/channels only — see [BannedRights] for what you
  /// can restrict.
  Future<void> restrict(int chatId, int userId, BannedRights rights) async {
    if (!_client.peers.isChannel(chatId)) {
      throw StateError(
        'restrict() needs a supergroup/channel; $chatId looks like a basic '
        'group, which only supports full ban()/kick(), not partial '
        'restrictions.',
      );
    }
    final updates = await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.channels.editBanned(
        channel: _client.peers.inputChannel(chatId),
        participant: _client.peers.inputPeerUser(userId),
        bannedRights: rights.toRaw(),
      ),
    );
    _feedUpdates(updates);
  }

  /// Grants [userId] admin rights in [chatId]. [rank] is an optional
  /// custom title shown under their name (e.g. `'Moderator'`).
  ///
  /// You need [AdminRights.addAdmins] yourself to do this. Basic groups
  /// only support an all-or-nothing admin flag — [rights] is ignored there
  /// beyond "grant admin".
  Future<void> promote(int chatId, int userId, AdminRights rights,
      {String rank = ''}) async {
    if (_client.peers.isChannel(chatId)) {
      final updates = await _client.callRaw<t.UpdatesBase>(
        () => _client.raw.channels.editAdmin(
          channel: _client.peers.inputChannel(chatId),
          userId: _client.peers.inputUser(userId),
          adminRights: rights.toRaw(),
          rank: rank,
        ),
      );
      _feedUpdates(updates);
      return;
    }
    await _client.callRaw<t.Boolean>(
      () => _client.raw.messages.editChatAdmin(
        chatId: chatId,
        userId: _client.peers.inputUser(userId),
        isAdmin: true,
      ),
    );
  }

  /// Revokes [userId]'s admin rights in [chatId], back to a regular
  /// member.
  Future<void> demote(int chatId, int userId) async {
    if (_client.peers.isChannel(chatId)) {
      await promote(chatId, userId, const AdminRights.none());
      return;
    }
    await _client.callRaw<t.Boolean>(
      () => _client.raw.messages.editChatAdmin(
        chatId: chatId,
        userId: _client.peers.inputUser(userId),
        isAdmin: false,
      ),
    );
  }

  /// Adds [userIds] to [chatId] directly — no invite link needed, as long
  /// as your account has permission (public channels/supergroups allow
  /// this for anyone; private ones need you to already be a member with
  /// invite rights, and some users' privacy settings will still block it).
  ///
  /// Returns the subset of [userIds] that couldn't be added (e.g. due to
  /// privacy settings) — an empty list means everyone was added.
  Future<List<int>> invite(int chatId, List<int> userIds) async {
    final inputUsers = [for (final id in userIds) _client.peers.inputUser(id)];

    if (_client.peers.isChannel(chatId)) {
      final result = await _client.callRaw<t.MessagesInvitedUsersBase>(
        () => _client.raw.channels.inviteToChannel(
          channel: _client.peers.inputChannel(chatId),
          users: inputUsers,
        ),
      );
      if (result is t.MessagesInvitedUsers) {
        _feedUpdates(result.updates);
        return [
          for (final m in result.missingInvitees)
            if (m is t.MissingInvitee) m.userId,
        ];
      }
      return const [];
    }

    final missing = <int>[];
    for (final id in userIds) {
      try {
        final result = await _client.callRaw<t.MessagesInvitedUsersBase>(
          () => _client.raw.messages.addChatUser(
            chatId: chatId,
            userId: _client.peers.inputUser(id),
            fwdLimit: 100,
          ),
        );
        if (result is t.MessagesInvitedUsers) _feedUpdates(result.updates);
      } on RpcException {
        missing.add(id);
      }
    }
    return missing;
  }

  void _feedUpdates(t.UpdatesBase updates) {
    switch (updates) {
      case t.Updates():
        _client.peers.feed(users: updates.users, chats: updates.chats);
      case t.UpdatesCombined():
        _client.peers.feed(users: updates.users, chats: updates.chats);
      default:
        break;
    }
  }

  t.ChannelParticipantsFilterBase _rawFilter(
      ParticipantFilter filter, String query) {
    switch (filter) {
      case ParticipantFilter.recent:
        return const t.ChannelParticipantsRecent();
      case ParticipantFilter.admins:
        return const t.ChannelParticipantsAdmins();
      case ParticipantFilter.bots:
        return const t.ChannelParticipantsBots();
      case ParticipantFilter.search:
        return t.ChannelParticipantsSearch(q: query);
      // Telegram's own naming is inverted from what you'd guess:
      // `Kicked` is the fully-banned list, `Banned` is "has some active
      // restriction" (mute, etc). ptgc's [ParticipantFilter] uses the
      // intuitive names and maps them to the right raw filter here.
      case ParticipantFilter.banned:
        return t.ChannelParticipantsKicked(q: query);
      case ParticipantFilter.restricted:
        return t.ChannelParticipantsBanned(q: query);
    }
  }
}
