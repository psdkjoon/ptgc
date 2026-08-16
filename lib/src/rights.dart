import 'tl.dart' as t;

/// Which admin privileges a member has, for [Members.promote].
///
/// Every field defaults to `false`; turn on only what you mean to grant.
/// Use [AdminRights.full] as a shortcut for "give every right" and adjust
/// from there with `copyWith`.
class AdminRights {
  /// Can edit the chat's title, photo, and other info.
  final bool changeInfo;

  /// Can post messages (channels only — irrelevant for groups).
  final bool postMessages;

  /// Can edit other members' messages (channels only).
  final bool editMessages;

  /// Can delete other members' messages.
  final bool deleteMessages;

  /// Can ban/kick/restrict other members.
  final bool banUsers;

  /// Can invite new members (needed even for public groups, to generate
  /// invite links).
  final bool inviteUsers;

  /// Can pin messages.
  final bool pinMessages;

  /// Can appoint new admins with a subset of their own rights.
  final bool addAdmins;

  /// Appears as "anonymous admin" — messages are signed by the group, not
  /// the account.
  final bool anonymous;

  /// Can start/manage group calls and live streams.
  final bool manageCall;

  /// Catch-all for miscellaneous rights not covered above.
  final bool other;

  /// Can create, rename, and manage forum topics.
  final bool manageTopics;

  const AdminRights({
    this.changeInfo = false,
    this.postMessages = false,
    this.editMessages = false,
    this.deleteMessages = false,
    this.banUsers = false,
    this.inviteUsers = false,
    this.pinMessages = false,
    this.addAdmins = false,
    this.anonymous = false,
    this.manageCall = false,
    this.other = false,
    this.manageTopics = false,
  });

  /// Every right granted — the equivalent of promoting someone to a
  /// full/co-owner admin (short of ownership itself, which Telegram doesn't
  /// expose over `editAdmin`).
  const AdminRights.full()
      : changeInfo = true,
        postMessages = true,
        editMessages = true,
        deleteMessages = true,
        banUsers = true,
        inviteUsers = true,
        pinMessages = true,
        addAdmins = true,
        anonymous = false,
        manageCall = true,
        other = true,
        manageTopics = true;

  /// No rights at all — combined with [Members.promote], this demotes an
  /// existing admin back to a regular member.
  const AdminRights.none()
      : changeInfo = false,
        postMessages = false,
        editMessages = false,
        deleteMessages = false,
        banUsers = false,
        inviteUsers = false,
        pinMessages = false,
        addAdmins = false,
        anonymous = false,
        manageCall = false,
        other = false,
        manageTopics = false;

  AdminRights copyWith({
    bool? changeInfo,
    bool? postMessages,
    bool? editMessages,
    bool? deleteMessages,
    bool? banUsers,
    bool? inviteUsers,
    bool? pinMessages,
    bool? addAdmins,
    bool? anonymous,
    bool? manageCall,
    bool? other,
    bool? manageTopics,
  }) {
    return AdminRights(
      changeInfo: changeInfo ?? this.changeInfo,
      postMessages: postMessages ?? this.postMessages,
      editMessages: editMessages ?? this.editMessages,
      deleteMessages: deleteMessages ?? this.deleteMessages,
      banUsers: banUsers ?? this.banUsers,
      inviteUsers: inviteUsers ?? this.inviteUsers,
      pinMessages: pinMessages ?? this.pinMessages,
      addAdmins: addAdmins ?? this.addAdmins,
      anonymous: anonymous ?? this.anonymous,
      manageCall: manageCall ?? this.manageCall,
      other: other ?? this.other,
      manageTopics: manageTopics ?? this.manageTopics,
    );
  }

  /// Converts to the raw TL object `channels.editAdmin` expects.
  t.ChatAdminRights toRaw() => t.ChatAdminRights(
        changeInfo: changeInfo,
        postMessages: postMessages,
        editMessages: editMessages,
        deleteMessages: deleteMessages,
        banUsers: banUsers,
        inviteUsers: inviteUsers,
        pinMessages: pinMessages,
        addAdmins: addAdmins,
        anonymous: anonymous,
        manageCall: manageCall,
        other: other,
        manageTopics: manageTopics,
        postStories: false,
        editStories: false,
        deleteStories: false,
        manageDirectMessages: false,
        manageRanks: false,
        manageLinkedPeers: false,
      );

  factory AdminRights.fromRaw(t.ChatAdminRightsBase raw) {
    if (raw is! t.ChatAdminRights) return const AdminRights.none();
    return AdminRights(
      changeInfo: raw.changeInfo,
      postMessages: raw.postMessages,
      editMessages: raw.editMessages,
      deleteMessages: raw.deleteMessages,
      banUsers: raw.banUsers,
      inviteUsers: raw.inviteUsers,
      pinMessages: raw.pinMessages,
      addAdmins: raw.addAdmins,
      anonymous: raw.anonymous,
      manageCall: raw.manageCall,
      other: raw.other,
      manageTopics: raw.manageTopics,
    );
  }
}

/// Which actions a member is *forbidden* from taking, for [Members.restrict],
/// [Members.ban], [Members.kick], and [Members.unban].
///
/// Every field defaults to `false` (i.e. "not restricted"). This mirrors
/// Telegram's own `ChatBannedRights` — turning a field **on** takes that
/// permission **away**. Prefer the named constructors ([BannedRights.banned],
/// [BannedRights.none]) or [Members.restrict]'s convenience parameters over
/// constructing this directly, unless you need fine-grained control.
class BannedRights {
  /// Can't view messages at all — this is what makes a restriction a full
  /// ban/kick rather than a mute.
  final bool viewMessages;

  final bool sendMessages;
  final bool sendMedia;
  final bool sendStickers;
  final bool sendGifs;
  final bool sendGames;
  final bool sendInline;
  final bool embedLinks;
  final bool sendPolls;
  final bool changeInfo;
  final bool inviteUsers;
  final bool pinMessages;
  final bool manageTopics;
  final bool sendPhotos;
  final bool sendVideos;
  final bool sendRoundvideos;
  final bool sendAudios;
  final bool sendVoices;
  final bool sendDocs;
  final bool sendPlain;
  final bool sendReactions;

  /// When this restriction lifts. `null` (the default) means forever.
  final DateTime? until;

  const BannedRights({
    this.viewMessages = false,
    this.sendMessages = false,
    this.sendMedia = false,
    this.sendStickers = false,
    this.sendGifs = false,
    this.sendGames = false,
    this.sendInline = false,
    this.embedLinks = false,
    this.sendPolls = false,
    this.changeInfo = false,
    this.inviteUsers = false,
    this.pinMessages = false,
    this.manageTopics = false,
    this.sendPhotos = false,
    this.sendVideos = false,
    this.sendRoundvideos = false,
    this.sendAudios = false,
    this.sendVoices = false,
    this.sendDocs = false,
    this.sendPlain = false,
    this.sendReactions = false,
    this.until,
  });

  /// A full ban: the member can no longer view or interact with the chat at
  /// all. Pass [until] to make it temporary (Telegram treats anything under
  /// 30 seconds or over 366 days as permanent).
  const BannedRights.banned({DateTime? until})
      : viewMessages = true,
        sendMessages = true,
        sendMedia = true,
        sendStickers = true,
        sendGifs = true,
        sendGames = true,
        sendInline = true,
        embedLinks = true,
        sendPolls = true,
        changeInfo = true,
        inviteUsers = true,
        pinMessages = true,
        manageTopics = true,
        sendPhotos = true,
        sendVideos = true,
        sendRoundvideos = true,
        sendAudios = true,
        sendVoices = true,
        sendDocs = true,
        sendPlain = true,
        sendReactions = true,
        until = until;

  /// No restrictions — lifts a ban or mute entirely.
  const BannedRights.none()
      : viewMessages = false,
        sendMessages = false,
        sendMedia = false,
        sendStickers = false,
        sendGifs = false,
        sendGames = false,
        sendInline = false,
        embedLinks = false,
        sendPolls = false,
        changeInfo = false,
        inviteUsers = false,
        pinMessages = false,
        manageTopics = false,
        sendPhotos = false,
        sendVideos = false,
        sendRoundvideos = false,
        sendAudios = false,
        sendVoices = false,
        sendDocs = false,
        sendPlain = false,
        sendReactions = false,
        until = null;

  /// Converts to the raw TL object `channels.editBanned` expects.
  t.ChatBannedRights toRaw() => t.ChatBannedRights(
        viewMessages: viewMessages,
        sendMessages: sendMessages,
        sendMedia: sendMedia,
        sendStickers: sendStickers,
        sendGifs: sendGifs,
        sendGames: sendGames,
        sendInline: sendInline,
        embedLinks: embedLinks,
        sendPolls: sendPolls,
        changeInfo: changeInfo,
        inviteUsers: inviteUsers,
        pinMessages: pinMessages,
        manageTopics: manageTopics,
        sendPhotos: sendPhotos,
        sendVideos: sendVideos,
        sendRoundvideos: sendRoundvideos,
        sendAudios: sendAudios,
        sendVoices: sendVoices,
        sendDocs: sendDocs,
        sendPlain: sendPlain,
        editRank: false,
        sendReactions: sendReactions,
        manageLinkedPeers: false,
        // Epoch zero is Telegram's convention for "forever".
        untilDate: until ?? DateTime.fromMillisecondsSinceEpoch(0),
      );

  factory BannedRights.fromRaw(t.ChatBannedRightsBase raw) {
    if (raw is! t.ChatBannedRights) return const BannedRights.none();
    final forever = raw.untilDate.millisecondsSinceEpoch == 0;
    return BannedRights(
      viewMessages: raw.viewMessages,
      sendMessages: raw.sendMessages,
      sendMedia: raw.sendMedia,
      sendStickers: raw.sendStickers,
      sendGifs: raw.sendGifs,
      sendGames: raw.sendGames,
      sendInline: raw.sendInline,
      embedLinks: raw.embedLinks,
      sendPolls: raw.sendPolls,
      changeInfo: raw.changeInfo,
      inviteUsers: raw.inviteUsers,
      pinMessages: raw.pinMessages,
      manageTopics: raw.manageTopics,
      sendPhotos: raw.sendPhotos,
      sendVideos: raw.sendVideos,
      sendRoundvideos: raw.sendRoundvideos,
      sendAudios: raw.sendAudios,
      sendVoices: raw.sendVoices,
      sendDocs: raw.sendDocs,
      sendPlain: raw.sendPlain,
      sendReactions: raw.sendReactions,
      until: forever ? null : raw.untilDate,
    );
  }
}
