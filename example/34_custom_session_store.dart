// ignore_for_file: file_names, avoid_print

// ============================================================================
// 34 — A CUSTOM SESSION STORE
// ============================================================================
//
// FileSessionStore (the default) and MemorySessionStore (35) cover the two
// common cases. Implement SessionStore yourself when you need something
// else — a database, a secrets manager, or (as here) multiple named
// sessions sharing one file, so you can run several accounts from the same
// script directory without their sessions overwriting each other.
//
// SessionStore is only three methods: load, save, clear. PtgcSession.toJson
// / .fromJson do the (de)serialization for you — you just decide where the
// bytes live.
//
// HOW TO RUN:
//   dart run example/34_custom_session_store.dart
// ============================================================================

import 'dart:convert';
import 'dart:io';

import 'package:ptgc/ptgc.dart';

/// Keeps every named session in one JSON file: `{"alice": {...}, "bob": {...}}`.
class NamedSessionStore implements SessionStore {
  NamedSessionStore(this.name, [this.path = 'ptgc.sessions.json']);

  final String name;
  final String path;

  Future<Map<String, dynamic>> _readAll() async {
    final file = File(path);
    if (!await file.exists()) return {};
    try {
      return jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  @override
  Future<PtgcSession?> load() async {
    final all = await _readAll();
    final entry = all[name];
    if (entry == null) return null;
    return PtgcSession.fromJson((entry as Map).cast<String, dynamic>());
  }

  @override
  Future<void> save(PtgcSession session) async {
    final all = await _readAll();
    all[name] = session.toJson();
    await File(path).writeAsString(jsonEncode(all));
  }

  @override
  Future<void> clear() async {
    final all = await _readAll();
    all.remove(name);
    await File(path).writeAsString(jsonEncode(all));
  }
}

Future<void> main() async {
  final client =
      TelegramClient.fromEnv(sessionStore: NamedSessionStore('alice'));
  await client.connect();

  print(
    client.isSignedIn
        ? 'Reused a saved "alice" session — logged in as user ${client.userId}.'
        : 'No saved "alice" session yet — run the login flow from '
            '01_login.dart, but pass this same sessionStore to TelegramClient.',
  );

  await client.disconnect();
}
