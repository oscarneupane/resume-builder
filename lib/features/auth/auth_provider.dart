import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/auth_repository.dart';

/// Reactive auth state used by the router for redirects.
class AuthState {
  final String? userId;
  final String? email;
  final bool initializing;
  const AuthState({this.userId, this.email, this.initializing = true});

  bool get isSignedIn => userId != null;

  AuthState copyWith({String? userId, String? email, bool? initializing, bool clear = false}) =>
      AuthState(
        userId: clear ? null : (userId ?? this.userId),
        email: clear ? null : (email ?? this.email),
        initializing: initializing ?? this.initializing,
      );
}

class AuthController extends ChangeNotifier {
  AuthController(this._repo) {
    _init();
  }

  final AuthRepository _repo;
  AuthState _state = const AuthState();
  AuthState get state => _state;

  Future<void> _init() async {
    await _repo.restoreSession();
    _state = AuthState(
      userId: _repo.currentUserId,
      email: _repo.currentEmail,
      initializing: false,
    );
    notifyListeners();
    _repo.authStateChanges.listen((event) {
      _state = AuthState(
        userId: event.userId,
        email: event.email,
        initializing: false,
      );
      notifyListeners();
    });
  }

  Future<void> signIn(String email, String password) async {
    await _repo.signIn(email: email, password: password);
    if (!_state.isSignedIn) {
      _state = AuthState(userId: _repo.currentUserId, email: _repo.currentEmail, initializing: false);
      notifyListeners();
    }
  }

  Future<void> signUp({required String email, required String password, String? fullName}) async {
    await _repo.signUp(email: email, password: password, fullName: fullName);
    if (!_state.isSignedIn) {
      _state = AuthState(userId: _repo.currentUserId, email: _repo.currentEmail, initializing: false);
      notifyListeners();
    }
  }

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
