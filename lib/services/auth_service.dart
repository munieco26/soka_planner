import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Stream of auth state changes
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current user
  static User? get currentUser => _auth.currentUser;

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: Use popup sign-in via Firebase Auth directly
      final provider = GoogleAuthProvider();
      return await _auth.signInWithPopup(provider);
    }

    // Mobile: Use Google Sign-In SDK (v7 API)
    final googleSignIn = GoogleSignIn.instance;
    await googleSignIn.initialize();

    final GoogleSignInAccount? googleUser =
        await googleSignIn.authenticate();

    final idToken = googleUser?.authentication.idToken;
    if (idToken == null) return null;

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return await _auth.signInWithCredential(credential);
  }

  /// Sign out
  static Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
