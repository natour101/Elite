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

class AuthSessionController extends StateNotifier<AdminAuthSession> {
  AuthSessionController() : super(AdminAuthSession.unauthenticated());

  void setSession(AdminAuthSession session) {
    state = session;
  }

  void clear() {
    state = AdminAuthSession.unauthenticated();
  }
}

final authSessionProvider =
    StateNotifierProvider<AuthSessionController, AdminAuthSession>(
  (ref) => AuthSessionController(),
);

final adminStatusProvider = Provider<bool>((ref) {
  return ref.watch(authSessionProvider).isAdmin;
});

class AuthActionController extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final session = await ref.read(authServiceProvider).signInAdmin(
            email: email,
            password: password,
          );
      ref.read(authSessionProvider.notifier).setSession(session);
    });
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authServiceProvider).signOut();
      ref.read(authSessionProvider.notifier).clear();
    });
  }
}

final authActionControllerProvider =
    AsyncNotifierProvider<AuthActionController, void>(AuthActionController.new);
