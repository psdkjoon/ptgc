// ignore_for_file: file_names, avoid_print

// ============================================================================
// 37 — CUSTOM BOOTSTRAP DATA CENTERS
// ============================================================================
//
// TelegramClient's default constructor accepts bootstrapDataCenters — the
// addresses used only to establish the very first connection (see
// defaultDataCenters' doc comment: TelegramClient refreshes this table from
// the server afterwards, so these just need to get you *a* working
// connection). You'd override this if the default hardcoded IPs are
// blocked on your network but you have a working proxy/alternate address,
// or in tests where you want to point at a controlled endpoint.
//
// Note: .fromEnv() doesn't expose this parameter, so this example builds a
// TelegramClient directly instead, reading API_ID/API_HASH from the OS
// environment.
//
// HOW TO RUN:
//   1. export API_ID=... API_HASH=...
//   2. dart run example/37_custom_bootstrap_data_centers.dart
// ============================================================================

import 'dart:io';

import 'package:ptgc/ptgc.dart';

Future<void> main() async {
  final apiId = int.tryParse(Platform.environment['API_ID'] ?? '');
  final apiHash = Platform.environment['API_HASH'];
  if (apiId == null || apiHash == null) {
    print('Set API_ID and API_HASH environment variables first.');
    return;
  }

  final client = TelegramClient(
    apiId: apiId,
    apiHash: apiHash,
    // Same address as the default DC 2 entry — swap this for your own
    // known-good endpoint if you actually need one.
    bootstrapDataCenters: const [DataCenter(2, '149.154.167.51', 443)],
  );

  await client.connect();
  print(
    client.isSignedIn
        ? 'Connected and reused a saved session — logged in as user ${client.userId}.'
        : 'Connected. Not logged in — see 01_login.dart for the login flow.',
  );

  await client.disconnect();
}
