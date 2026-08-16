import 'tl.dart' as t;
import 'mtp.dart' as tg;

import 'client.dart';
import 'exceptions.dart';
import 'models.dart';

/// The verification code Telegram sent, returned by [AuthNamespace.sendCode].
class SentCode {
  /// Pass this back to [AuthNamespace.signIn] along with the code.
  final String phoneCodeHash;

  /// True if the code was (or will be) sent as a Telegram app notification
  /// rather than SMS/call.
  final bool viaApp;

  /// How long before the code expires / a different delivery method
  /// becomes available, if Telegram specified one.
  final Duration? timeout;

  const SentCode._(
      {required this.phoneCodeHash, required this.viaApp, this.timeout});
}

/// What [AuthNamespace.signIn] resulted in.
enum SignInStatus {
  /// Logged in — no further steps needed.
  success,

  /// Correct code, but this account has Two-Factor Authentication enabled.
  /// Call [AuthNamespace.checkPassword] next.
  passwordRequired,

  /// This phone number has no Telegram account yet. `ptgc` doesn't wrap
  /// account creation (`auth.signUp`) — most automation should not be
  /// creating fresh accounts — but it's one raw `client.invoke` call away
  /// if you have a genuine need.
  signUpRequired,
}

/// The outcome of [AuthNamespace.signIn].
class SignInResult {
  final SignInStatus status;

  /// Set when [status] is [SignInStatus.success].
  final PtgcUser? user;

  /// Set when [status] is [SignInStatus.passwordRequired] — Telegram's own
  /// hint for the account's 2FA password, if the account owner set one.
  final String? passwordHint;

  const SignInResult._(this.status, {this.user, this.passwordHint});
}

/// Everything needed to log a real user account in: [sendCode], [signIn],
/// and (if the account has Two-Factor Authentication) [checkPassword].
///
/// Reached via [TelegramClient.auth] — don't construct this directly.
class AuthNamespace {
  AuthNamespace(this._client);

  final TelegramClient _client;

  String? _phoneNumber;
  String? _phoneCodeHash;
  t.AccountPassword? _pendingPasswordChallenge;

  /// Requests a login code for [phoneNumber] (international format, e.g.
  /// `'+15551234567'`). Telegram will deliver it via the app if the number
  /// is already registered on another device, otherwise by SMS/call.
  Future<SentCode> sendCode(String phoneNumber) async {
    _phoneNumber = phoneNumber;

    final sent = await _client.callRaw<t.AuthSentCodeBase>(
      () => _client.raw.auth.sendCode(
        phoneNumber: phoneNumber,
        apiId: _client.apiId,
        apiHash: _client.apiHash,
        settings: const t.CodeSettings(
          allowFlashcall: false,
          currentNumber: false,
          allowAppHash: true,
          allowMissedCall: false,
          allowFirebase: false,
          unknownNumber: false,
        ),
      ),
    );

    if (sent is! t.AuthSentCode) {
      throw RpcException(t.RpcError(
          errorCode: 500, errorMessage: 'UNEXPECTED_SENT_CODE_TYPE'));
    }

    _phoneCodeHash = sent.phoneCodeHash;
    return SentCode._(
      phoneCodeHash: sent.phoneCodeHash,
      viaApp: sent.type is t.AuthSentCodeTypeApp,
      timeout: sent.timeout == null ? null : Duration(seconds: sent.timeout!),
    );
  }

  /// Submits the code the user received after [sendCode]. Uses the phone
  /// number and code hash from the last [sendCode] call unless you pass
  /// them explicitly (useful if you're not holding onto the [SentCode]).
  Future<SignInResult> signIn({
    required String code,
    String? phoneNumber,
    String? phoneCodeHash,
  }) async {
    final phone = phoneNumber ?? _phoneNumber;
    final hash = phoneCodeHash ?? _phoneCodeHash;
    if (phone == null || hash == null) {
      throw StateError(
          'Call auth.sendCode first, or pass phoneNumber/phoneCodeHash explicitly.');
    }

    try {
      final auth = await _client.callRaw<t.AuthAuthorizationBase>(
        () => _client.raw.auth
            .signIn(phoneNumber: phone, phoneCodeHash: hash, phoneCode: code),
      );
      return _handleAuthorization(auth);
    } on RpcException catch (e) {
      if (e.description == 'SESSION_PASSWORD_NEEDED') {
        return _requestPasswordChallenge();
      }
      rethrow;
    }
  }

  /// Submits the account's Two-Factor Authentication password after
  /// [signIn] returned [SignInStatus.passwordRequired].
  Future<PtgcUser> checkPassword(String password) async {
    final challenge = _pendingPasswordChallenge;
    if (challenge == null) {
      throw TwoFactorRequiredException();
    }
    final srp = await tg.check2FA(challenge, password);
    final auth = await _client.callRaw<t.AuthAuthorizationBase>(
      () => _client.raw.auth.checkPassword(password: srp),
    );
    final result = await _handleAuthorization(auth);
    return result.user!;
  }

  Future<SignInResult> _requestPasswordChallenge() async {
    final password = await _client.callRaw<t.AccountPasswordBase>(
        () => _client.raw.account.getPassword());
    if (password is! t.AccountPassword) {
      throw RpcException(
          t.RpcError(errorCode: 500, errorMessage: 'UNEXPECTED_PASSWORD_TYPE'));
    }
    _pendingPasswordChallenge = password;
    return SignInResult._(SignInStatus.passwordRequired,
        passwordHint: password.hint);
  }

  Future<SignInResult> _handleAuthorization(
      t.AuthAuthorizationBase auth) async {
    if (auth is t.AuthAuthorizationSignUpRequired) {
      return const SignInResult._(SignInStatus.signUpRequired);
    }
    final authorization = auth as t.AuthAuthorization;
    final user = PtgcUser.fromRaw(authorization.user);
    _client.peers.feed(users: [authorization.user]);
    await _client.rememberSignedInUser(user.id);
    return SignInResult._(SignInStatus.success, user: user);
  }

  /// Logs out and invalidates this session. After this, [TelegramClient]
  /// needs a full [sendCode]/[signIn] to be usable again — consider
  /// [TelegramClient.disconnect] instead if you just want to stop using
  /// the connection for now without revoking it.
  Future<void> logOut() async {
    await _client.callRaw<t.AuthLoggedOutBase>(() => _client.raw.auth.logOut());
    await _client.sessionStore.clear();
  }
}
