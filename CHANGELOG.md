# Changelog

## 2.0.0

### Changed
- Rewrote documentation across the whole library to be explanatory rather
  than just descriptive: every public method, class, and field now documents
  what it does, what values are accepted, what's returned, and how it
  relates to the rest of the API — not just a one-liner restatement of the
  signature. Related classes and methods are cross-linked (e.g. `Members.ban`
  links to `Members.kick`/`Members.unban`; `SessionStore` links to
  `AuthNamespace.logOut`), so you can navigate the whole lifecycle for a
  feature from any entry point.
- Added doc comments to the MTProto internals (`mtp_*.dart`): each file now
  has a role comment, and non-obvious classes/methods (`AuthorizationKey`,
  `BadMessageException`, `SocketAbstraction`, `Client`, ...) are explained.
- Cleaned up dead/commented-out code in `mtp_client.dart` (the abandoned
  `MsgContainer` piggyback path) and replaced it with an explanatory
  comment for why that approach was set aside.
- No API surface changes — this release is documentation only.

## 1.0.1

- Added `example/main.dart` as a primary, runnable illustrative example
  (plus `example/README.md` indexing all 41 numbered example scripts) so
  pub.dev can find and display a package example.
- Shortened the `pubspec.yaml` `description` to fit within pub.dev's
  recommended 60–180 character range.
- Fixed all `curly_braces_in_flow_control_structures` lint warnings
  (unbraced single-statement `if`s) in `lib/src/chats.dart`,
  `lib/src/client.dart`, and `lib/src/peer_cache.dart`.

## 1.0.0

Initial release.
