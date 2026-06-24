import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_repository.dart';

/// Reactive auth state used by the router for redirects.
class AuthState {
  final String? userId;
  final String? email;
  final String? username;
  final bool initializing;
  const AuthState({this.userId, this.email, this.username, this.initializing = true});

  bool get isSignedIn => userId != null;

  /// Best display name: username → email local part → 'friend'.
  String get displayName {
    if (username != null && username!.trim().isNotEmpty) return username!.trim();
    final local = email?.split('@').first;
    return (local == null || local.isEmpty) ? 'friend' : local;
  }
}

class AuthController extends ChangeNotifier {
  AuthController(this._repo) {
    _init();
  }

  final AuthRepository _repo;
  AuthState _state = const AuthState();
  AuthState get state => _state;

  AuthState _current({bool initializing = false}) => AuthState(
        userId: _repo.currentUserId,
        email: _repo.currentEmail,
        username: _repo.currentUsername,
        initializing: initializing,
      );

  Future<void> _init() async {
    await _repo.restoreSession();
    _state = _current();
    notifyListeners();
    _repo.authStateChanges.listen((event) {
      _state = AuthState(
        userId: event.userId,
        email: event.email,
        username: event.username,
        initializing: false,
      );
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    await _repo.signIn(email: email, password: password);
    if (!_state.isSignedIn) {
      _state = _current();
      notifyListeners();
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    String? fullName,
    String? username,
  }) async {
    await _repo.signUp(email: email, password: password, fullName: fullName, username: username);
    if (!_state.isSignedIn) {
      _state = _current();
      notifyListeners();
    }
  }

  Future<void> signInWithGoogle() => _repo.signInWithGoogle();

  Future<void> signOut() async {
    await _repo.signOut();
    if (kDebugMode) debugPrint('[auth] signed out');
  }

  Future<void> sendPasswordReset(String email) => _repo.sendPasswordReset(email);
}

final authControllerProvider = ChangeNotifierProvider<AuthController>(
  (ref) => AuthController(AuthRepository.instance),
);

final authStateProvider = Provider<AuthState>(
  (ref) => ref.watch(authControllerProvider).state,
);
