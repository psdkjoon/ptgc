/// What kind of chat a [PtgcChat] represents.
enum ChatKind {
  /// A one-on-one private chat with a user (not a real "chat" object on the
  /// wire — surfaced here for completeness when working with dialogs).
  private,

  /// A basic (non-super) group, capped at 200 members, created with
  /// `messages.createChat`.
  group,

  /// A supergroup — a [ChatKind.channel] under the hood with `megagroup`
  /// set. This is what most large/public "groups" on Telegram actually are.
  supergroup,

  /// A broadcast channel.
  channel,
}

/// A member's standing within a chat, from [Members.get] / [Members.list].
enum ParticipantRole {
  /// The chat's creator/owner.
  creator,

  /// Has one or more admin rights (see [AdminRights]).
  admin,

  /// A regular member with no special rights or restrictions.
  member,

  /// Has one or more restrictions applied (see [BannedRights]), but has not
  /// left and is not fully banned.
  restricted,

  /// Banned/kicked from the chat.
  banned,

  /// Left the chat on their own.
  left,
}

/// Which subset of participants to fetch with [Members.list].
///
/// Mirrors Telegram's `channels.getParticipants` filters. Only meaningful
/// for supergroups/channels — basic groups always return every member.
enum ParticipantFilter {
  /// Recently active members (the default, and the only filter that works
  /// without search text).
  recent,

  /// Members with at least one admin right, plus the creator.
  admins,

  /// Banned/kicked members.
  banned,

  /// Members with active restrictions (but not fully banned).
  restricted,

  /// Bots in the chat.
  bots,

  /// Search by name/username — use [Members.list]'s `query` parameter
  /// alongside this filter.
  search,
}
