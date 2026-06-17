import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Auth surface used by the auth controller / router.
///
/// Real path: Supabase Auth (email/password + Google OAuth). Fallback path:
/// local-only mock session in flutter_secure_storage so the app runs end-to-end
/// before infra exists. Both paths expose the same `authStateChanges`.
class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  static const _mockEmailKey = 'mock_user_email';
  static const _mockUsernameKey = 'mock_user_username';
  final _storage = const FlutterSecureStorage();
  final _mockController = StreamController<AuthEvent>.broadcast();

  String? _mockUserId;
  String? _mockEmail;
  String? _mockUsername;

  /// Deep link Supabase redirects back to after the Google OAuth browser flow.
  /// Must be registered in AndroidManifest and in Supabase's allowed redirects.
  static const _oauthRedirect = 'applymate://login-callback';

  Stream<AuthEvent> get authStateChanges {
    if (SupabaseService.isConfigured) {
      return SupabaseService.instance.client.auth.onAuthStateChange.map((e) {
        final user = e.session?.user;
        return AuthEvent(
          userId: user?.id,
          email: user?.email,
          username: user?.userMetadata?['username'] as String?,
        );
      });
    }
    return _mockController.stream;
  }

  Future<void> restoreSession() async {
    if (SupabaseService.isConfigured) return; // Supabase restores via its own persistence
    final email = await _storage.read(key: _mockEmailKey);
    if (email != null) {
      _mockEmail = email;
      _mockUsername = await _storage.read(key: _mockUsernameKey);
      _mockUserId = 'mock-${email.hashCode.toUnsigned(32)}';
      _mockController.add(AuthEvent(userId: _mockUserId, email: email, username: _mockUsername));
    }
  }

  String? get currentUserId {
    if (SupabaseService.isConfigured) {
      return SupabaseService.instance.client.auth.currentUser?.id;
    }
    return _mockUserId;
  }

  String? get currentEmail {
    if (SupabaseService.isConfigured) {
      return SupabaseService.instance.client.auth.currentUser?.email;
    }
    return _mockEmail;
  }

  String? get currentUsername {
    if (SupabaseService.isConfigured) {
      return SupabaseService.instance.client.auth.currentUser?.userMetadata?['username'] as String?;
    }
    return _mockUsername;
  }

  bool get isSignedIn => currentUserId != null;

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    if (SupabaseService.isConfigured) {
      final res = await SupabaseService.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          if (fullName != null) 'full_name': fullName,
          if (username != null) 'username': username,
        },
      );
      if (res.user == null) {
        throw const AuthFailure('Sign up failed. Try again.');
      }
      return;
    }
    await _mockSignIn(email, username: username);
  }

  Future<void> signIn({required String email, required String password}) async {
    if (SupabaseService.isConfigured) {
      try {
        await SupabaseService.instance.client.auth.signInWithPassword(email: email, password: password);
      } on AuthException catch (e) {
        throw AuthFailure(e.message);
      }
      return;
    }
    await _mockSignIn(email);
  }

  /// Google sign-in via Supabase OAuth. The resulting session arrives through
  /// [authStateChanges] once the browser redirects back to [_oauthRedirect].
  Future<void> signInWithGoogle() async {
    if (!SupabaseService.isConfigured) {
      throw const AuthFailure(
        'Google sign-in needs Supabase + the Google provider enabled. See supabase/README.md.',
      );
    }
    try {
      await SupabaseService.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _oauthRedirect,
      );
    } on AuthException catch (e) {
      throw AuthFailure(e.message);
    }
  }

  Future<void> signOut() async {
    if (SupabaseService.isConfigured) {
      await SupabaseService.instance.client.auth.signOut();
      return;
    }
    await _storage.delete(key: _mockEmailKey);
    await _storage.delete(key: _mockUsernameKey);
    _mockUserId = null;
    _mockEmail = null;
    _mockUsername = null;
    _mockController.add(const AuthEvent(userId: null, email: null, username: null));
  }

  Future<void> sendPasswordReset(String email) async {
    if (SupabaseService.isConfigured) {
      await SupabaseService.instance.client.auth.resetPasswordForEmail(email);
      return;
    }
    if (kDebugMode) {
      // ignore: avoid_print
      print('[mock] password reset link sent to $email');
    }
  }

  Future<void> _mockSignIn(String email, {String? username}) async {
    await _storage.write(key: _mockEmailKey, value: email);
    if (username != null) await _storage.write(key: _mockUsernameKey, value: username);
    _mockEmail = email;
    _mockUsername = username ?? _mockUsername;
    _mockUserId = 'mock-${email.hashCode.toUnsigned(32)}';
    _mockController.add(AuthEvent(userId: _mockUserId, email: email, username: _mockUsername));
  }
}

class AuthEvent {
  final String? userId;
  final String? email;
  final String? username;
  const AuthEvent({required this.userId, required this.email, this.username});
  bool get isSignedIn => userId != null;
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}
