import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_service.dart';

/// Auth surface used by the auth controller / router.
///
/// Real path: Supabase Auth (email/password). Fallback path: local-only mock
/// session persisted in flutter_secure_storage so the app runs end-to-end
/// before infra exists. Both paths expose the same `authStateChanges`.
class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  static const _mockKey = 'mock_user_email';
  final _storage = const FlutterSecureStorage();
  final _mockController = StreamController<AuthEvent>.broadcast();

  String? _mockUserId;
  String? _mockEmail;

  Stream<AuthEvent> get authStateChanges {
    if (SupabaseService.isConfigured) {
      return SupabaseService.instance.client.auth.onAuthStateChange
          .map((e) => AuthEvent(
                userId: e.session?.user.id,
                email: e.session?.user.email,
              ));
    }
    return _mockController.stream;
  }

  Future<void> restoreSession() async {
    if (SupabaseService.isConfigured) return; // Supabase restores via its own persistence
    final email = await _storage.read(key: _mockKey);
    if (email != null) {
      _mockEmail = email;
      _mockUserId = 'mock-${email.hashCode.toUnsigned(32)}';
      _mockController.add(AuthEvent(userId: _mockUserId, email: email));
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

  bool get isSignedIn => currentUserId != null;

  Future<void> signUp({required String email, required String password, String? fullName}) async {
    if (SupabaseService.isConfigured) {
      final res = await SupabaseService.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {if (fullName != null) 'full_name': fullName},
      );
      if (res.user == null) {
        throw const AuthFailure('Sign up failed. Try again.');
      }
      return;
    }
    await _mockSignIn(email);
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

  Future<void> signOut() async {
    if (SupabaseService.isConfigured) {
      await SupabaseService.instance.client.auth.signOut();
      return;
    }
    await _storage.delete(key: _mockKey);
    _mockUserId = null;
    _mockEmail = null;
    _mockController.add(const AuthEvent(userId: null, email: null));
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

  Future<void> _mockSignIn(String email) async {
    await _storage.write(key: _mockKey, value: email);
    _mockEmail = email;
    _mockUserId = 'mock-${email.hashCode.toUnsigned(32)}';
    _mockController.add(AuthEvent(userId: _mockUserId, email: email));
  }
}

class AuthEvent {
  final String? userId;
  final String? email;
  const AuthEvent({required this.userId, required this.email});
  bool get isSignedIn => userId != null;
}

class AuthFailure implements Exception {
  final String message;
  const AuthFailure(this.message);
  @override
  String toString() => message;
}
