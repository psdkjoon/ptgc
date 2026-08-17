import 'tl.dart' as t;

import 'exceptions.dart';

/// Extracts the plain numeric ID out of any [t.PeerBase] variant.
int idOfPeer(t.PeerBase peer) => switch (peer) {
      t.PeerUser() => peer.userId,
      t.PeerChat() => peer.chatId,
      t.PeerChannel() => peer.channelId,
      _ => 0,
    };

/// Extracts the plain numeric ID out of any [t.UserBase] variant.
///
/// `t`'s generated base classes deliberately declare no shared fields
/// (even `id`), so every call site that only has a `UserBase`/`ChatBase`
/// needs to go through a helper like this rather than accessing `.id`
/// directly.
int idOfUser(t.UserBase user) => switch (user) {
      t.User() => user.id,
      t.UserEmpty() => user.id,
      _ => 0,
    };

/// Extracts the plain numeric ID out of any [t.ChatBase] variant (basic
/// group, supergroup, or channel).
int idOfChat(t.ChatBase chat) => switch (chat) {
      t.Chat() => chat.id,
      t.ChatForbidden() => chat.id,
      t.ChatEmpty() => chat.id,
      t.Channel() => chat.id,
      t.ChannelForbidden() => chat.id,
      _ => 0,
    };

/// Remembers the access hashes and usernames of every user/chat `ptgc` has
/// seen this session, so you can address them by plain integer ID or
/// `@username` afterwards.
///
/// Telegram's raw API requires an `accessHash` (not just an ID) to address
/// most users and channels — a value only ever handed to you as part of a
/// server response. Every high-level `ptgc` call feeds the users/chats it
/// receives into this cache automatically, so as long as you've seen a
/// peer once (via [Members.list], [Chats.listDialogs],
/// [Contacts.resolveUsername], etc.) you can reference it by ID from then
/// on without threading the access hash through your own code.
///
/// A [PeerNotFoundException] means the opposite: `ptgc` has never seen that
/// ID/username, so it has no access hash to use. Resolve it once first —
/// [Contacts.resolveUsername] for usernames, [Members.list] for chat
/// members you want to act on.
class PeerCache {
  final Map<int, int> _userAccessHash = {};
  final Map<int, int> _channelAccessHash = {};
  final Map<int, t.UserBase> _users = {};
  final Map<int, t.ChatBase> _chats = {};
  final Map<String, int> _usernameToId = {};
  int? selfId;

  /// Feeds users/chats from a raw response into the cache. Safe to call
  /// with empty lists.
  void feed(
      {Iterable<t.UserBase> users = const [],
      Iterable<t.ChatBase> chats = const []}) {
    for (final u in users) {
      final id = idOfUser(u);
      _users[id] = u;
      if (u is t.User) {
        if (u.accessHash != null) _userAccessHash[id] = u.accessHash!;
        if (u.username != null) _usernameToId[u.username!.toLowerCase()] = id;
        for (final entry in u.usernames ?? const <t.UsernameBase>[]) {
          if (entry is t.Username) {
            _usernameToId[entry.username.toLowerCase()] = id;
          }
        }
      }
    }
    for (final c in chats) {
      final id = idOfChat(c);
      _chats[id] = c;
      if (c is t.Channel) {
        if (c.accessHash != null) _channelAccessHash[id] = c.accessHash!;
        if (c.username != null) _usernameToId[c.username!.toLowerCase()] = id;
        for (final entry in c.usernames ?? const <t.UsernameBase>[]) {
          if (entry is t.Username) {
            _usernameToId[entry.username.toLowerCase()] = id;
          }
        }
      }
    }
  }

  t.UserBase? cachedUser(int id) => _users[id];
  t.ChatBase? cachedChat(int id) => _chats[id];

  /// Looks up a cached ID by `@username` (leading `@` optional).
  int? idForUsername(String username) {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    return _usernameToId[clean.toLowerCase()];
  }

  t.InputUserBase inputUser(int id) {
    if (id == selfId) return const t.InputUserSelf();
    final hash = _userAccessHash[id];
    if (hash == null) throw PeerNotFoundException('user $id');
    return t.InputUser(userId: id, accessHash: hash);
  }

  t.InputPeerBase inputPeerUser(int id) {
    if (id == selfId) return const t.InputPeerSelf();
    final hash = _userAccessHash[id];
    if (hash == null) throw PeerNotFoundException('user $id');
    return t.InputPeerUser(userId: id, accessHash: hash);
  }

  t.InputChannelBase inputChannel(int id) {
    final hash = _channelAccessHash[id];
    if (hash == null) throw PeerNotFoundException('channel $id');
    return t.InputChannel(channelId: id, accessHash: hash);
  }

  t.InputPeerBase inputPeerChannel(int id) {
    final hash = _channelAccessHash[id];
    if (hash == null) throw PeerNotFoundException('channel $id');
    return t.InputPeerChannel(channelId: id, accessHash: hash);
  }

  /// A basic (non-super) group needs only its ID, never an access hash.
  t.InputPeerBase inputPeerChat(int id) => t.InputPeerChat(chatId: id);

  /// What kind of peer [id] is, based on everything seen so far. Returns
  /// [PeerKind.unknown] if `ptgc` hasn't encountered this ID this session.
  PeerKind kindOf(int id) {
    if (id == selfId ||
        _userAccessHash.containsKey(id) ||
        _users[id] is t.User) {
      return PeerKind.user;
    }
    if (_channelAccessHash.containsKey(id) ||
        _chats[id] is t.Channel ||
        _chats[id] is t.ChannelForbidden) {
      return PeerKind.channel;
    }
    if (_chats[id] is t.Chat || _chats[id] is t.ChatForbidden) {
      return PeerKind.chat;
    }
    return PeerKind.unknown;
  }

  /// Builds the right `InputPeer*` for [id] regardless of whether it's a
  /// user, basic group, or supergroup/channel — used wherever the raw API
  /// takes a generic `InputPeerBase` (e.g. sending a message).
  t.InputPeerBase inputPeer(int id) {
    switch (kindOf(id)) {
      case PeerKind.user:
        return inputPeerUser(id);
      case PeerKind.chat:
        return inputPeerChat(id);
      case PeerKind.channel:
        return inputPeerChannel(id);
      case PeerKind.unknown:
        throw PeerNotFoundException('$id');
    }
  }

  /// Whether [id] is known to be a channel/supergroup (as opposed to a
  /// basic group) — used internally to route calls to the right namespace
  /// (`channels.*` vs `messages.*`).
  bool isChannel(int id) => kindOf(id) == PeerKind.channel;
}

/// What kind of chat/peer an ID refers to, per everything [PeerCache] has
/// seen this session.
enum PeerKind {
  user,
  chat,
  channel,
  unknown,
}
