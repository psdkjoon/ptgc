import 'tl.dart' as t;

import 'enums.dart';
import 'peer_cache.dart';
import 'rights.dart';

/// A Telegram user, as returned throughout `ptgc` (contacts, participants,
/// message senders, `whoAmI`, ...).
class PtgcUser {
  /// The user's numeric ID.
  final int id;

  /// Needed alongside [id] to address this user in most raw API calls.
  /// `null` for [isDeleted] users, which can no longer be addressed at all.
  final int? accessHash;

  final String? firstName;
  final String? lastName;

  /// Without the leading `@`.
  final String? username;

  /// E.164-ish, digits only, no leading `+` (Telegram's own format).
  final String? phone;

  final bool isBot;

  /// Whether this is the account `ptgc` itself is logged in as.
  final bool isSelf;

  final bool isVerified;
  final bool isPremium;
  final bool isScam;
  final bool isFake;

  /// True for a deleted account — most fields will be null and [accessHash]
  /// will always be null.
  final bool isDeleted;

  const PtgcUser({
    required this.id,
    this.accessHash,
    this.firstName,
    this.lastName,
    this.username,
    this.phone,
    this.isBot = false,
    this.isSelf = false,
    this.isVerified = false,
    this.isPremium = false,
    this.isScam = false,
    this.isFake = false,
    this.isDeleted = false,
  });

  factory PtgcUser.fromRaw(t.UserBase raw) {
    if (raw is t.User) {
      return PtgcUser(
        id: raw.id,
        accessHash: raw.accessHash,
        firstName: raw.firstName,
        lastName: raw.lastName,
        username: raw.username,
        phone: raw.phone,
        isBot: raw.bot,
        isSelf: raw.self,
        isVerified: raw.verified,
        isPremium: raw.premium,
        isScam: raw.scam,
        isFake: raw.fake,
      );
    }
    if (raw is t.UserEmpty) {
      // Server knows only the ID (e.g. a deleted account).
      return PtgcUser(id: raw.id, isDeleted: true);
    }
    // UserBase has exactly these two variants; this is unreachable in
    // practice but keeps the factory total.
    return const PtgcUser(id: 0, isDeleted: true);
  }

  /// First and last name joined with a space, skipping whichever is missing.
  /// Falls back to `'@username'`, then the numeric [id], if no name is set.
  String get displayName {
    final name =
        [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    if (name.isNotEmpty) return name;
    if (username != null) return '@$username';
    return '#$id';
  }

  @override
  String toString() =>
      'PtgcUser(id: $id, username: $username, name: $displayName)';

  @override
  bool operator ==(Object other) => other is PtgcUser && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A group, supergroup, or channel, as returned by [Chats] and [Members].
class PtgcChat {
  final int id;

  /// Needed alongside [id] to address this chat in most raw API calls.
  /// Always present for [ChatKind.supergroup]/[ChatKind.channel]; `null`
  /// for plain [ChatKind.group]s, which are addressed by [id] alone.
  final int? accessHash;

  final String title;
  final ChatKind kind;

  /// Without the leading `@`. Only public supergroups/channels have one.
  final String? username;

  /// Best-effort member count. Present on most responses but not all — call
  /// [Chats.getFullInfo] if you need it guaranteed.
  final int? participantsCount;

  final bool isCreator;
  final bool isVerified;
  final bool isScam;
  final bool isFake;

  /// True if you've left this chat, or (for [ChatKind.group]) it was
  /// deactivated/upgraded to a supergroup.
  final bool isLeft;

  /// True if the chat is forbidden to you (e.g. you were banned) — most
  /// other fields will be unavailable in that case.
  final bool isForbidden;

  /// This account's admin rights in the chat, if any.
  final AdminRights? adminRights;

  const PtgcChat({
    required this.id,
    this.accessHash,
    required this.title,
    required this.kind,
    this.username,
    this.participantsCount,
    this.isCreator = false,
    this.isVerified = false,
    this.isScam = false,
    this.isFake = false,
    this.isLeft = false,
    this.isForbidden = false,
    this.adminRights,
  });

  factory PtgcChat.fromRaw(t.ChatBase raw) {
    switch (raw) {
      case t.Channel():
        return PtgcChat(
          id: raw.id,
          accessHash: raw.accessHash,
          title: raw.title,
          kind: raw.megagroup ? ChatKind.supergroup : ChatKind.channel,
          username: raw.username,
          participantsCount: raw.participantsCount,
          isCreator: raw.creator,
          isVerified: raw.verified,
          isScam: raw.scam,
          isFake: raw.fake,
          isLeft: raw.left,
          adminRights: raw.adminRights == null
              ? null
              : AdminRights.fromRaw(raw.adminRights!),
        );
      case t.ChannelForbidden():
        return PtgcChat(
          id: raw.id,
          accessHash: raw.accessHash,
          title: raw.title,
          kind: raw.megagroup ? ChatKind.supergroup : ChatKind.channel,
          isForbidden: true,
        );
      case t.Chat():
        return PtgcChat(
          id: raw.id,
          title: raw.title,
          kind: ChatKind.group,
          participantsCount: raw.participantsCount,
          isCreator: raw.creator,
          isLeft: raw.left || raw.deactivated,
          adminRights: raw.adminRights == null
              ? null
              : AdminRights.fromRaw(raw.adminRights!),
        );
      case t.ChatForbidden():
        return PtgcChat(
            id: raw.id,
            title: raw.title,
            kind: ChatKind.group,
            isForbidden: true);
      case t.ChatEmpty():
        return PtgcChat(
            id: raw.id, title: '', kind: ChatKind.group, isForbidden: true);
      default:
        // ChatBase has exactly these five variants; unreachable in
        // practice, but there's no ID we can safely read off the base
        // type, so surface a clearly-invalid placeholder rather than
        // fail to compile or throw.
        return const PtgcChat(
            id: 0, title: '', kind: ChatKind.group, isForbidden: true);
    }
  }

  @override
  String toString() => 'PtgcChat(id: $id, kind: $kind, title: $title)';

  @override
  bool operator ==(Object other) => other is PtgcChat && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// A single member of a chat, as returned by [Members.list] / [Members.get].
class Participant {
  final PtgcUser user;
  final ParticipantRole role;

  /// This member's admin rights. Only set when [role] is
  /// [ParticipantRole.admin] or [ParticipantRole.creator].
  final AdminRights? adminRights;

  /// This member's active restrictions. Only set when [role] is
  /// [ParticipantRole.restricted] or [ParticipantRole.banned].
  final BannedRights? bannedRights;

  /// A custom admin title ("rank"), if the chat owner set one — e.g. shown
  /// instead of "admin" under their name.
  final String? rank;

  /// Who invited this member, if known.
  final int? invitedBy;

  /// When this member joined, if known.
  final DateTime? joinedAt;

  const Participant({
    required this.user,
    required this.role,
    this.adminRights,
    this.bannedRights,
    this.rank,
    this.invitedBy,
    this.joinedAt,
  });

  /// Builds a [Participant] from a supergroup/channel's raw
  /// `ChannelParticipantBase`, looking [user] up in [users] (already fed
  /// with the response's own `.users` list by the caller).
  factory Participant.fromChannelParticipant(
      t.ChannelParticipantBase raw, Map<int, PtgcUser> users) {
    switch (raw) {
      case t.ChannelParticipantCreator():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.creator,
          adminRights: AdminRights.fromRaw(raw.adminRights),
          rank: raw.rank,
        );
      case t.ChannelParticipantAdmin():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.admin,
          adminRights: AdminRights.fromRaw(raw.adminRights),
          rank: raw.rank,
          invitedBy: raw.inviterId,
          joinedAt: raw.date,
        );
      case t.ChannelParticipantBanned():
        final id = idOfPeer(raw.peer);
        final rights = BannedRights.fromRaw(raw.bannedRights);
        return Participant(
          user: users[id] ?? PtgcUser(id: id),
          role: rights.viewMessages
              ? ParticipantRole.banned
              : ParticipantRole.restricted,
          bannedRights: rights,
          rank: raw.rank,
          invitedBy: raw.kickedBy,
          joinedAt: raw.date,
        );
      case t.ChannelParticipantLeft():
        final id = idOfPeer(raw.peer);
        return Participant(
            user: users[id] ?? PtgcUser(id: id), role: ParticipantRole.left);
      case t.ChannelParticipantSelf():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.member,
          rank: raw.rank,
          invitedBy: raw.inviterId,
          joinedAt: raw.date,
        );
      case t.ChannelParticipant():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.member,
          rank: raw.rank,
          joinedAt: raw.date,
        );
      default:
        return Participant(
            user: const PtgcUser(id: 0), role: ParticipantRole.member);
    }
  }

  /// Builds a [Participant] from a basic group's raw `ChatParticipantBase`.
  factory Participant.fromChatParticipant(
      t.ChatParticipantBase raw, Map<int, PtgcUser> users) {
    switch (raw) {
      case t.ChatParticipantCreator():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.creator,
          rank: raw.rank,
        );
      case t.ChatParticipantAdmin():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.admin,
          rank: raw.rank,
          invitedBy: raw.inviterId,
          joinedAt: raw.date,
        );
      case t.ChatParticipant():
        return Participant(
          user: users[raw.userId] ?? PtgcUser(id: raw.userId),
          role: ParticipantRole.member,
          rank: raw.rank,
          invitedBy: raw.inviterId,
          joinedAt: raw.date,
        );
      default:
        return Participant(
            user: const PtgcUser(id: 0), role: ParticipantRole.member);
    }
  }

  @override
  String toString() => 'Participant(${user.displayName}, role: $role)';
}
