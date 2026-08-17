# ptgc examples

`main.dart` is the quickest way to see the package in action: connect, log
in (or reuse a saved session), and look someone up.

For everything else, this directory has 41 focused, runnable scripts —
numbered in a suggested reading/run order, from logging in through
error handling and advanced setups.

## Setup

Every example reads `API_ID` and `API_HASH` from a `.env` file (via the
[`penv`](https://pub.dev/packages/penv) package). Create one next to the
scripts:

```
API_ID=123456
API_HASH=abcdef0123456789abcdef0123456789
```

Get these from [my.telegram.org](https://my.telegram.org) under
"API development tools".

Then run any script with:

```
dart run example/01_login.dart
```

## Scripts

| # | Script | What it shows |
|---|---|---|
| 01 | `01_login.dart` | Connecting and signing in, including 2FA |
| 02 | `02_whoami_and_dialogs.dart` | Fetching your own user info and dialog list |
| 03 | `03_ban_kick_restrict.dart` | Banning, kicking, and restricting members |
| 04 | `04_promote_demote_admin.dart` | Promoting and demoting admins |
| 05 | `05_list_and_search_members.dart` | Listing and searching chat members |
| 06 | `06_invite_members.dart` | Inviting users to a chat |
| 07 | `07_contacts_and_blocking.dart` | Managing contacts and blocked users |
| 08 | `08_send_and_listen.dart` | Sending messages and listening for updates |
| 09 | `09_raw_invoke_escape_hatch.dart` | Calling raw MTProto methods directly |
| 10 | `10_resolve_chat_by_username.dart` | Resolving a chat from its `@username` |
| 11 | `11_chat_full_info.dart` | Fetching full chat metadata |
| 12 | `12_create_basic_group.dart` | Creating a basic group |
| 13 | `13_create_supergroup.dart` | Creating a supergroup |
| 14 | `14_create_channel.dart` | Creating a broadcast channel |
| 15 | `15_rename_chat.dart` | Renaming a chat |
| 16 | `16_join_public_channel.dart` | Joining a public channel |
| 17 | `17_join_via_invite_link.dart` | Joining via an invite link |
| 18 | `18_export_invite_link.dart` | Creating/exporting an invite link |
| 19 | `19_leave_chat.dart` | Leaving a chat |
| 20 | `20_permanent_and_temporary_ban.dart` | Permanent vs. temporary bans |
| 21 | `21_fine_grained_admin_rights.dart` | Setting specific admin rights |
| 22 | `22_fine_grained_restrictions.dart` | Setting specific member restrictions |
| 23 | `23_banned_vs_restricted_filter.dart` | Filtering banned vs. restricted members |
| 24 | `24_bots_in_chat.dart` | Handling bot accounts in a chat |
| 25 | `25_get_single_member_basic_group.dart` | Looking up one member in a basic group |
| 26 | `26_forward_messages.dart` | Forwarding messages |
| 27 | `27_delete_messages.dart` | Deleting messages |
| 28 | `28_message_every_chat_kind.dart` | Messaging across all chat kinds |
| 29 | `29_filter_events_by_chat.dart` | Filtering update events by chat |
| 30 | `30_handle_flood_wait.dart` | Handling `FLOOD_WAIT` errors |
| 31 | `31_handle_peer_not_found.dart` | Handling peer-not-found errors |
| 32 | `32_handle_rpc_errors.dart` | Handling general RPC errors |
| 33 | `33_handle_session_expired.dart` | Handling an expired session |
| 34 | `34_custom_session_store.dart` | Implementing a custom session store |
| 35 | `35_memory_session_store.dart` | Using an in-memory session store |
| 36 | `36_log_out.dart` | Logging out |
| 37 | `37_custom_bootstrap_data_centers.dart` | Bootstrapping with custom data centers |
| 38 | `38_inspect_peer_cache.dart` | Inspecting the internal peer cache |
| 39 | `39_raw_invoke_pin_message.dart` | Pinning a message via raw invoke |
| 40 | `40_raw_invoke_message_history.dart` | Fetching message history via raw invoke |
| 41 | `41_end_to_end_group_setup.dart` | Full group setup, end to end |
