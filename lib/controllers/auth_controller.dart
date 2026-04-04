import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/auth_service.dart';

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider));
});

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges();
});

final adminStatusProvider = Provider<bool>((ref) {
  return ref.watch(authServiceProvider).isCurrentUserAdmin;
});

class AuthActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signInAdmin(
            email: email,
            password: password,
          ),
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authServiceProvider).signOut(),
    );
  }
}

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);
