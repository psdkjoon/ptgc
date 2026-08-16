# ptgc

[![pub package](https://img.shields.io/pub/v/ptgc.svg)](https://pub.dev/packages/ptgc)
[![license: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![docs](https://img.shields.io/badge/docs-doc.psdkjoon.ir-blue.svg)](https://doc.psdkjoon.ir/ptgc)

A high-level client for the [Telegram Client API](https://core.telegram.org/api)
(MTProto). Log in as a real **user account** and control chats and channels
— ban, kick, restrict, promote, invite, and list members — plus contacts,
dialogs, and messaging.

> This is the companion package to [`ptgb`](https://pub.dev/packages/ptgb) (the Bot API client)

```dart
import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv(); // loads API_ID/API_HASH from a .env file
  await client.connect();

  if (!client.isSignedIn) {
    final sent = await client.auth.sendCode('+15551234567');
    final result = await client.auth.signIn(code: '12345', phoneCodeHash: sent.phoneCodeHash);
    if (result.status == SignInStatus.passwordRequired) {
      await client.auth.checkPassword('your 2FA password');
    }
  }

  await client.members.ban(chatId, userId); // control a user
  await client.disconnect();
}
```

## Contents

- [Features](#features)
- [Installation](#installation)
- [Getting API credentials](#getting-api-credentials)
- [Quick start](#quick-start)
- [Examples](#examples)
- [Things to keep in mind](#things-to-keep-in-mind)
- [Contributing](#contributing)
- [License](#license)

## Features

- **Real user-account access** — everything a logged-in Telegram user can
  do that a bot can't: ban/kick/restrict/promote members without the
  target having to interact with a bot first, invite people directly,
  create groups/supergroups/channels, and more.
- **Member management** ([`Members`](lib/src/members.dart)) — [`ban`],
  [`kick`], [`unban`], [`restrict`], [`promote`], [`demote`], [`invite`],
  and [`list`]/[`get`] for inspecting who's in a chat and their role.
- **Chat administration** ([`Chats`](lib/src/chats.dart)) — list dialogs,
  resolve usernames, get full chat info, create basic groups /
  supergroups / channels, rename, join (by username or invite link),
  export invite links, and leave.
- **Contacts** ([`Contacts`](lib/src/contacts.dart)) — resolve/search
  users, add/delete contacts, block/unblock, list blocked users.
- **Messaging** ([`Messages`](lib/src/messages.dart)) — send, forward, and
  delete messages.
- **Typed models**, not raw JSON, for users (`PtgcUser`), chats
  (`PtgcChat`), participants (`Participant`), and permission sets
  (`AdminRights`, `BannedRights`).
- **A live event stream** (`client.events`) — typed `NewMessageEvent` /
  `MemberStatusChangedEvent` over Telegram's raw update feed.
- **Pluggable session storage** — the default `FileSessionStore` persists
  your login to a local JSON file so you don't re-authenticate on every
  run; swap in `MemorySessionStore` or your own `SessionStore` (a
  database, secrets manager, etc).
- **A low-level escape hatch** (`client.invoke` / `client.raw`) for any
  MTProto method that doesn't have a typed wrapper yet.

## Installation

```bash
dart pub add ptgc
```

or add it to `pubspec.yaml` directly:

```yaml
dependencies:
  ptgc: ^1.0.0
```

## Getting API credentials

Unlike a bot token, `ptgc` needs an `api_id` / `api_hash` pair, which
identifies the *application*, not the account — the account itself is
whichever phone number you sign in with.

1. Go to <https://my.telegram.org/apps> and log in with the phone number
   you intend to automate.
2. Create an application (any name/description works) and copy the
   `api_id` and `api_hash` it gives you.
3. Keep `api_hash` somewhere safe — never commit it to source control. See
   Quick Start below for the recommended way to load it.

## Quick start

**Recommended:** put your credentials in a `.env` file next to your script
and let `ptgc` load them for you automatically (via the
[`penv`](https://pub.dev/packages/penv) package):

```
API_ID=1234567
API_HASH=your-api-hash-here
```

```dart
import 'dart:io';
import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final client = TelegramClient.fromEnv(); // reads API_ID/API_HASH from .env
  await client.connect(); // opens the MTProto connection; reuses a saved session if one exists

  if (!client.isSignedIn) {
    stdout.write('Phone number (with country code, e.g. +15551234567): ');
    final phone = stdin.readLineSync()!.trim();

    final sent = await client.auth.sendCode(phone);
    stdout.write('Code Telegram sent you: ');
    final code = stdin.readLineSync()!.trim();

    final result = await client.auth.signIn(code: code, phoneCodeHash: sent.phoneCodeHash);
    switch (result.status) {
      case SignInStatus.success:
        print('Logged in as ${result.user!.displayName}');
      case SignInStatus.passwordRequired:
        stdout.write('2FA password: ');
        final password = stdin.readLineSync()!.trim();
        final user = await client.auth.checkPassword(password);
        print('Logged in as ${user.displayName}');
      case SignInStatus.signUpRequired:
        print('This phone number has no Telegram account yet.');
        await client.disconnect();
        return;
    }
  } else {
    print('Already logged in as user ${client.userId} (from saved session).');
  }

  await client.disconnect();
}
```

Run it again and it skips straight to "already logged in" — `ptgc.session.json`
(the default `FileSessionStore` location) remembers the login for you.

Using a different `.env` filename? Pass `envFile`:

```dart
final client = TelegramClient.fromEnv(envFile: 'secrets.env');
```

Add `.env` and `ptgc.session.json` to your `.gitignore` — the session file
is as sensitive as a password, since anyone with it can act as the logged-in
account without a code or 2FA prompt.

**Alternative:** pass credentials directly if you're managing them
yourself, e.g. from a secrets manager at deploy time:

```dart
final client = TelegramClient(apiId: myApiId, apiHash: myApiHashFromSomewhereElse);
```

Either way works — just never hard-code a real `api_hash` as a literal
string in code that ends up in version control.

## Examples

The [`example/`](example/) folder has a full, numbered set of runnable
programs, from logging in up to creating groups, managing membership,
handling errors (flood waits, RPC errors, expired sessions), and using
custom session stores. Start with
[`01_login.dart`](example/01_login.dart) and work through in order.

## Things to keep in mind

- **Treat your session file like a password.** `ptgc.session.json` (or
  whatever your `SessionStore` persists) lets anyone holding it act as the
  logged-in account, with no code or 2FA needed. Keep it out of version
  control, same as `.env`.
- **This automates a real user account, not a bot.** Telegram's Terms of
  Service and anti-spam systems apply to user accounts differently than to
  bots — aggressive automation (mass messaging, joining many chats
  quickly, etc.) can get the account limited or banned. Pace your requests
  and prefer the Bot API (`ptgb`) where a bot can do the job instead.
- **`ptgc` does not retry or throttle requests for you.** Every failed
  call throws a `PtgcException` subtype — `RpcException` for generic RPC
  errors, `FloodWaitException` when Telegram is rate-limiting you,
  `AuthRequiredException` for a missing/expired login, or
  `PeerNotFoundException` for an unresolved username/ID. Wrap calls in
  `try`/`catch` so one bad call doesn't crash your whole process — see
  `example/30_handle_flood_wait.dart`, `example/31_handle_peer_not_found.dart`,
  `example/32_handle_rpc_errors.dart`, and `example/33_handle_session_expired.dart`.
- **[`chatId`](lib/src/members.dart) needs to have been *seen* first.**
  Most raw Telegram methods need an access hash alongside the ID, which
  `ptgc` caches internally (`PeerCache`) the moment a chat/user shows up
  in a dialog list, search result, or previous call. If you get a
  peer-not-found style error on a chat/user you haven't interacted with
  yet, resolve it first (e.g. `chats.resolveUsername`,
  `chats.listDialogs`) before acting on its ID.
- **`connect()` alone does not log you in.** It just opens the encrypted
  MTProto socket (reusing a saved session if present). Check
  `client.isSignedIn` and drive `client.auth` yourself if not — see
  `example/01_login.dart`.
- Requires Dart SDK `^3.5.0`.

## Documentation

Full docs / wiki: **[doc.psdkjoon.ir/ptgc](https://doc.psdkjoon.ir/ptgc)**
(mirrors: [doc.psdk.space/ptgc](https://doc.psdk.space/ptgc),
[doc.psdk.fun/ptgc](https://doc.psdk.fun/ptgc)).

## Contributing

Bug reports, feature requests, and pull requests are welcome on
[GitHub](https://github.com/psdkjoon/ptgc). If you're filing a bug, a
minimal reproduction and the relevant MTProto method name help a lot.

## License

[MIT](LICENSE) — see the LICENSE file for details.
