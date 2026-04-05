import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';

class AdminAuthSession {
  const AdminAuthSession({
    required this.isAuthenticated,
    required this.isAdmin,
    this.email,
    this.user,
  });

  final bool isAuthenticated;
  final bool isAdmin;
  final String? email;
  final User? user;

  factory AdminAuthSession.unauthenticated() {
    return const AdminAuthSession(
      isAuthenticated: false,
      isAdmin: false,
    );
  }

  factory AdminAuthSession.fromUser(User? user) {
    final email = user?.email;
    final isAdmin = email != null &&
        email.toLowerCase() == AppConstants.adminEmail.toLowerCase();
    return AdminAuthSession(
      isAuthenticated: user != null,
      isAdmin: isAdmin,
      email: email,
      user: user,
    );
  }
}

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Future<AdminAuthSession> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final session = AdminAuthSession.fromUser(credential.user);
    if (!session.isAdmin) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'not-admin',
        message: 'هذا الحساب لا يملك صلاحيات الأدمن.',
      );
    }

    return session;
  }

  Future<void> signOut() => _auth.signOut();
}
