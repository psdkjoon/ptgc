import 'tl.dart' as t;

import 'client.dart';
import 'models.dart';
import 'peer_cache.dart';

/// Manages this account's contacts and account-level (not per-chat) user
/// blocking, and resolves usernames to the peers `ptgc` needs to act on
/// them elsewhere.
///
/// Reached via [TelegramClient.contacts] — don't construct this directly.
class Contacts {
  Contacts(this._client);

  final TelegramClient _client;

  /// Resolves `@username` (leading `@` optional) to a [PtgcUser] and caches
  /// its access hash, so you can pass the returned `.id` to [Members] and
  /// elsewhere afterwards.
  ///
  /// Returns `null` if the username doesn't exist. Works for user, group,
  /// and channel usernames alike, but only user results are returned here
  /// — use [Chats] to resolve a chat username instead.
  Future<PtgcUser?> resolveUsername(String username) async {
    final clean = username.startsWith('@') ? username.substring(1) : username;
    final resolved = await _client.callRaw<t.ContactsResolvedPeerBase>(
      () => _client.raw.contacts.resolveUsername(username: clean),
    );
    if (resolved is! t.ContactsResolvedPeer) return null;
    _client.peers.feed(users: resolved.users, chats: resolved.chats);
    if (resolved.peer is! t.PeerUser) return null;
    final id = idOfPeer(resolved.peer);
    final raw = resolved.users.where((u) => idOfUser(u) == id).firstOrNull;
    return raw == null ? null : PtgcUser.fromRaw(raw);
  }

  /// Searches for users/chats by name, both among your contacts and
  /// globally. [limit] caps how many of each category come back.
  Future<List<PtgcUser>> searchUsers(String query, {int limit = 20}) async {
    final found = await _client.callRaw<t.ContactsFoundBase>(
      () => _client.raw.contacts
          .search(broadcasts: false, bots: false, q: query, limit: limit),
    );
    if (found is! t.ContactsFound) return const [];
    _client.peers.feed(users: found.users, chats: found.chats);
    final byId = {
      for (final u in found.users) idOfUser(u): PtgcUser.fromRaw(u)
    };
    final ids = {
      for (final p in found.myResults)
        if (p is t.PeerUser) p.userId,
      for (final p in found.results)
        if (p is t.PeerUser) p.userId,
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!
    ];
  }

  /// Adds [userId] to your contacts. [firstName]/[lastName] are your own
  /// label for them, not pulled from their profile.
  Future<void> addContact(
    int userId, {
    required String firstName,
    String lastName = '',
    String phone = '',
  }) async {
    await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.contacts.addContact(
        addPhonePrivacyException: false,
        id: _client.peers.inputUser(userId),
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      ),
    );
  }

  /// Removes [userIds] from your contacts (doesn't block them — see
  /// [block] for that).
  Future<void> deleteContacts(List<int> userIds) async {
    await _client.callRaw<t.UpdatesBase>(
      () => _client.raw.contacts.deleteContacts(
        id: [for (final id in userIds) _client.peers.inputUser(id)],
      ),
    );
  }

  /// Blocks [userId] account-wide: they can no longer message you or see
  /// your online status, regardless of which chat you're both in. This is
  /// separate from [Members.ban], which only affects one specific chat.
  Future<void> block(int userId) async {
    await _client.callRaw<t.Boolean>(
      () => _client.raw.contacts
          .block(myStoriesFrom: false, id: _client.peers.inputPeerUser(userId)),
    );
  }

  /// Reverses [block].
  Future<void> unblock(int userId) async {
    await _client.callRaw<t.Boolean>(
      () => _client.raw.contacts.unblock(
          myStoriesFrom: false, id: _client.peers.inputPeerUser(userId)),
    );
  }

  /// Lists everyone you've [block]ed.
  Future<List<PtgcUser>> getBlockedUsers(
      {int offset = 0, int limit = 100}) async {
    final result = await _client.callRaw<t.ContactsBlockedBase>(
      () => _client.raw.contacts
          .getBlocked(myStoriesFrom: false, offset: offset, limit: limit),
    );
    final List<t.PeerBlockedBase> blocked;
    final List<t.UserBase> users;
    switch (result) {
      case t.ContactsBlocked():
        blocked = result.blocked;
        users = result.users;
      case t.ContactsBlockedSlice():
        blocked = result.blocked;
        users = result.users;
      default:
        return const [];
    }
    _client.peers.feed(users: users);
    final byId = {for (final u in users) idOfUser(u): PtgcUser.fromRaw(u)};
    final ids = {
      for (final b in blocked)
        if (b is t.PeerBlocked && b.peerId is t.PeerUser) idOfPeer(b.peerId),
    };
    return [
      for (final id in ids)
        if (byId[id] != null) byId[id]!
    ];
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
