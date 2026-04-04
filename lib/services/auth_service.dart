import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';

class AuthService {
  AuthService(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isCurrentUserAdmin {
    final email = _auth.currentUser?.email;
    return email != null &&
        email.toLowerCase() == AppConstants.adminEmail.toLowerCase();
  }

  Future<void> signInAdmin({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final signedEmail = credential.user?.email;
    final isAdmin = signedEmail != null &&
        signedEmail.toLowerCase() == AppConstants.adminEmail.toLowerCase();
    if (!isAdmin) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'not-admin',
        message: 'هذا الحساب لا يملك صلاحيات الأدمن.',
      );
    }
  }

  Future<void> signOut() => _auth.signOut();
}
