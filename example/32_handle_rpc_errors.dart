// ignore_for_file: file_names, avoid_print

// ============================================================================
// 32 — HANDLING RPC ERRORS
// ============================================================================
//
// FloodWaitException, AuthRequiredException, TwoFactorRequiredException,
// and PeerNotFoundException (see 30/31/01) each cover one specific,
// well-known failure. Everything else Telegram can reject a request with —
// CHAT_ADMIN_REQUIRED, USER_ALREADY_PARTICIPANT, USERNAME_NOT_OCCUPIED,
// hundreds of others — surfaces as the catch-all RpcException, with
// Telegram's own error string in [RpcException.description] for you to
// pattern-match on.
//
// HOW TO RUN:
//   1. Edit groupUsername below to a group you are a *member* of but not
//      an admin in, so the ban attempt is guaranteed to be rejected.
//   2. dart run example/32_handle_rpc_errors.dart
// ============================================================================

import 'package:ptgc/ptgc.dart';

const groupUsername = 'a_group_where_you_are_not_admin';

Future<void> main() async {
  final client = TelegramClient.fromEnv();
  await client.connect();

  if (!client.isSignedIn) {
    print('Not logged in — run 01_login.dart first.');
    await client.disconnect();
    return;
  }

  final group = await client.chats.resolveUsername(groupUsername);
  if (group == null) {
    print('Could not resolve @$groupUsername.');
    await client.disconnect();
    return;
  }

  try {
    // You don't have rights here, so Telegram should reject this outright.
    await client.members.ban(group.id, client.userId!);
  } on RpcException catch (e) {
    switch (e.description) {
      case 'CHAT_ADMIN_REQUIRED':
        print('You need admin rights in ${group.title} to do that.');
      case 'USER_NOT_MUTUAL_CONTACT':
        print('Telegram restricts this action to mutual contacts.');
      default:
        // Fall back to the generic message for anything not special-cased —
        // still useful, since it's Telegram's own error string.
        print('Unhandled RPC error ${e.code}: ${e.description}');
    }
  }

  await client.disconnect();
}
