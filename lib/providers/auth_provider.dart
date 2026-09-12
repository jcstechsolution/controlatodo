import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../core/utils/app_exception.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

/// Expone el estado de autenticación y el perfil del usuario al resto de
/// la aplicación. Es la fuente de verdad usada por el enrutador para
/// decidir a qué pantalla redirigir.
class AuthProvider extends ChangeNotifier {
  final AuthRepository _repository;

  AuthProvider({AuthRepository? repository})
      : _repository = repository ?? AuthRepository() {
    _authSubscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  StreamSubscription<fb_auth.User?>? _authSubscription;

  AuthStatus status = AuthStatus.unknown;
  fb_auth.User? firebaseUser;
  UserModel? userModel;
  bool isBusy = false;
  String? errorMessage;

  bool get isAuthenticated => status == AuthStatus.authenticated;

  Future<void> _onAuthChanged(fb_auth.User? user) async {
    firebaseUser = user;
    if (user == null) {
      userModel = null;
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      userModel = await _repository.fetchUserProfile(user.uid);
    } catch (_) {
      userModel = null;
    }
    status = AuthStatus.authenticated;
    notifyListeners();
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    return _runGuarded(() async {
      userModel = await _repository.registerWithEmail(
        name: name,
        email: email,
        password: password,
      );
    });
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _runGuarded(() async {
      userModel = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
    });
  }

  Future<bool> sendPasswordReset(String email) async {
    return _runGuarded(() async {
      await _repository.sendPasswordResetEmail(email);
    });
  }

  Future<void> logout() async {
    await _repository.signOut();
  }

  Future<void> refreshUserModel() async {
    final uid = firebaseUser?.uid;
    if (uid == null) return;
    userModel = await _repository.fetchUserProfile(uid);
    notifyListeners();
  }

  void clearError() {
    errorMessage = null;
    notifyListeners();
  }

  Future<bool> _runGuarded(Future<void> Function() action) async {
    isBusy = true;
    errorMessage = null;
    notifyListeners();
    try {
      await action();
      isBusy = false;
      notifyListeners();
      return true;
    } on AppException catch (e) {
      isBusy = false;
      errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (_) {
      isBusy = false;
      errorMessage = AppException.generic.message;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
