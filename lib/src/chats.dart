import 'tl.dart' as t;

import 'client.dart';
import 'enums.dart';
import 'exceptions.dart';
import 'models.dart';
import 'peer_cache.dart';

/// Lists your dialogs and manages chats/channels themselves — creating,
/// joining, leaving, renaming, and fetching full info. For acting on
/// *members* of a chat (ban/kick/promote/list), see [Members] instead.
///
/// Reached via [TelegramClient.chats] — don't construct this directly.
class Chats {
  Chats(this._client);

  final TelegramClient _client;

  /// Lists your open conversations (DMs, groups, channels), most recently
  /// active first. [limit] caps how many come back in one call; page
  /// further by passing the last returned chat's info as [offsetDate] /
  /// [offsetId] / [offsetPeerId].
  Future<List<PtgcChat>> listDialogs({
    int limit = 100,
    DateTime? offsetDate,
    int offsetId = 0,
    int offsetPeerId = 0,
  }) async {
    final offsetPeer = offsetPeerId == 0
        ? const t.InputPeerEmpty()
        : _client.peers.inputPeer(offsetPeerId);

    final result = await _client.callRaw<t.MessagesDialogsBase>(
      () => _client.raw.messages.getDialogs(
        excludePinned: false,
        offsetDate: offsetDate ?? DateTime.fromMillisecondsSinceEpoch(0),
        offsetId: offsetId,
        offsetPeer: offsetPeer,
        limit: limit,
        hash: 0,
      ),
    );

    final List<t.ChatBase> chats;
    final List<t.UserBase> users;
    switch (result) {
      case t.MessagesDialogs():
        chats = result.chats;
        users = result.users;
      case t.MessagesDialogsSlice():
        chats = result.chats;
        users = result.users;
      default:
        return const [];
    }
    _client.peers.feed(users: users, chats: chats);

    // Dialogs with other users (DMs) show up only in `users`, not `chats`
    // — surface those as PtgcChat too so the list is complete.
    final byId = <int, PtgcChat>{
      for (final c in chats) idOfChat(c): PtgcChat.fromRaw(c),
      for (final u in users)
        if (u is t.User) u.id: _dmChatFromUser(u),
    };
    return byId.values.toList();
  }

  PtgcChat _dmChatFromUser(t.User u) => PtgcChat(
        id: u.id,
        title: [u.firstName, u.lastName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' '),
        kind: ChatKind.private,
      );

  /// Resolves `@username` (leading `@` optional) to a [PtgcChat] — the
  /// group/supergroup/channel counterpart to [Contacts.resolveUsername].
  /// Also caches the access hash `ptgc` needs to act on this chat by plain
  /// ID afterwards (e.g. with [Members] or elsewhere in this class).
  ///
  /// Returns `null` if the username doesn't exist, or belongs to a user
  /// rather than a chat — use [Contacts.resolveUsername] for those. Basic
  /// (non-super) groups never have a username, so this only ever resolves
  /// to a [ChatKind.supergroup] or [ChatKind.channel].
  Future<PtgcChat?> resolveUsername(String username) async {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    final resolved = await _client.callRaw<t.ContactsResolvedPeerBase>(
      () => _client.raw.contacts.resolveUsername(username: clean),
    );
    if (resolved is! t.ContactsResolvedPeer) return null;
    _client.peers.feed(users: resolved.users, chats: resolved.chats);
    if (resolved.peer is t.PeerUser) return null;
    final id = idOfPeer(resolved.peer);
    final raw = resolved.chats.where((c) => idOfChat(c) == id).firstOrNull;
    return raw == null ? null : PtgcChat.fromRaw(raw);
  }

  /// Fetches extended info for [chatId] — description ("about"), member
  /// count, etc — beyond what [listDialogs]/[Members.list] already give
  /// you.
  Future<PtgcChat> getFullInfo(int chatId) async {
    if (_client.peers.isChannel(chatId)) {
      final result = await _client.callRaw<t.MessagesChatFullBase>(
        () => _client.raw.channels
            .getFullChannel(channel: _client.peers.inputChannel(chatId)),
      );
      if (result is! t.MessagesChatFull) return _placeholderChat(chatId);
      _client.peers.feed(users: result.users, chats: result.chats);
      final chat = result.chats.where((c) => idOfChat(c) == chatId).firstOrNull;
      return chat == null ? _placeholderChat(chatId) : PtgcChat.fromRaw(chat);
    }
    final result = await _client.callRaw<t.MessagesChatFullBase>(
      () => _client.raw.messages.getFullChat(chatId: chatId),
    );
    if (result is! t.MessagesChatFull) return _placeholderChat(chatId);
    _client.peers.feed(users: result.users, chats: result.chats);
    final chat = result.chats.where((c) => idOfChat(c) == chatId).firstOrNull;
    return chat == null ? _placeholderChat(chatId) : PtgcChat.fromRaw(chat);
  }

  PtgcChat _placeholderChat(int id) =>
      PtgcChat(id: id, title: '', kind: ChatKind.group, isForbidden: true);

  /// Creates a new basic group with [title], starting with [userIds] as
  /// members (Telegram requires at least one). Basic groups cap out at 200
  /// members — for anything bigger, or if you want channel features
  /// (public username, admin hierarchy beyond one level, etc), use
  /// [createSupergroup]/[createChannel] instead.
  Future<int?> createGroup(String title, List<int> userIds) async {
    final result = await _client.callRaw<t.MessagesInvitedUsersBase>(
      () => _client.raw.messages.createChat(
        users: [for (final id in userIds) _client.peers.inputUser(id)],
        title: title,
      ),
    );
    if (result is! t.MessagesInvitedUsers) return null;
    return _extractNewChatId(result.updates);
  }

  /// Creates a new supergroup (a `megagroup` channel) with [title]. Unlike
  /// [createGroup], supergroups scale past 200 members and support a
  /// proper admin hierarchy — most "groups" you see on Telegram are
  /// actually this.
  Future<int?> createSupergroup(String title, {String about = ''}) =>
      _createChannel(
        title,
        about: about,
        broadcast: false,
        megagroup: true,
      );

  /// Creates a new broadcast channel with [title] — only admins can post;
  /// everyone else just reads.
  Future<int?> createChannel(String title, {String about = ''}) =>
      _createChannel(
        title,
        about: about,
        broadcast: true,
        megagroup: false,
      );

  Future<int?> _createChannel(String title,
      {required String about,
      required bool broadcast,
      required bool megagroup}) async {
    final updates = await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.channels.createChannel(
        broadcast: broadcast,
        megagroup: megagroup,
        forImport: false,
        forum: false,
        title: title,
        about: about,
      ),
    );
    return _extractNewChatId(updates);
  }

  int? _extractNewChatId(t.UpdatesBase updates) {
    List<t.ChatBase> chats;
    List<t.UserBase> users;
    switch (updates) {
      case t.Updates():
        chats = updates.chats;
        users = updates.users;
      case t.UpdatesCombined():
        chats = updates.chats;
        users = updates.users;
      default:
        return null;
    }
    _client.peers.feed(users: users, chats: chats);
    return chats.isEmpty ? null : idOfChat(chats.first);
  }

  /// Renames [chatId].
  Future<void> setTitle(int chatId, String title) async {
    if (_client.peers.isChannel(chatId)) {
      await _client.callRaw<t.UpdatesBase>(
        () => _client.raw.channels.editTitle(
            channel: _client.peers.inputChannel(chatId), title: title),
      );
      return;
    }
    await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.messages.editChatTitle(chatId: chatId, title: title),
    );
  }

  /// Joins the public supergroup/channel [chatId] (you must already know
  /// its ID/access hash — resolve a `@username` with [Contacts.resolveUsername]
  /// first if needed). For private chats, use [joinByInviteLink] instead.
  Future<void> join(int chatId) async {
    final result = await _client.callRaw<t.MessagesChatInviteJoinResultBase>(
      () => _client.raw.channels
          .joinChannel(channel: _client.peers.inputChannel(chatId)),
    );
    if (result is t.MessagesChatInviteJoinResultOk)
      _extractNewChatId(result.updates);
  }

  /// Joins a private chat via an invite link or its bare hash (the part
  /// after `t.me/+` or `t.me/joinchat/`).
  Future<void> joinByInviteLink(String linkOrHash) async {
    final hash = _inviteHash(linkOrHash);
    final result = await _client.callRaw<t.MessagesChatInviteJoinResultBase>(
      () => _client.raw.messages.importChatInvite(hash: hash),
    );
    if (result is t.MessagesChatInviteJoinResultOk)
      _extractNewChatId(result.updates);
  }

  String _inviteHash(String linkOrHash) {
    final uri = Uri.tryParse(linkOrHash);
    if (uri == null) return linkOrHash;
    final path =
        uri.path.replaceFirst('/joinchat/', '/').replaceFirst('/+', '/');
    return path.split('/').where((s) => s.isNotEmpty).lastOrNull ?? linkOrHash;
  }

  /// Creates (or refreshes) an invite link for [chatId]. Requires the
  /// [AdminRights.inviteUsers] right if you're not the creator.
  Future<String> exportInviteLink(int chatId) async {
    final result = await _client.callRaw<t.ExportedChatInviteBase>(
      () => _client.raw.messages.exportChatInvite(
        legacyRevokePermanent: false,
        requestNeeded: false,
        peer: _client.peers.inputPeer(chatId),
      ),
    );
    if (result is t.ChatInviteExported) return result.link;
    throw RpcException(
        t.RpcError(errorCode: 500, errorMessage: 'UNEXPECTED_INVITE_TYPE'));
  }

  /// Leaves [chatId]. Does not delete the chat, and (for groups you don't
  /// own) does not affect anyone else in it.
  Future<void> leave(int chatId) async {
    if (_client.peers.isChannel(chatId)) {
      final updates = await _client.callRaw<t.UpdatesBase>(
        () => _client.raw.channels
            .leaveChannel(channel: _client.peers.inputChannel(chatId)),
      );
      _extractNewChatId(updates);
      return;
    }
    await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.messages.deleteChatUser(
        revokeHistory: false,
        chatId: chatId,
        userId: const t.InputUserSelf(),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;
}
