import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_reminder_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = true;
  StreamSubscription<User?>? _authSub;

  AuthProvider() {
    _authSub = AuthService.authStateChanges.listen(_onAuthStateChanged);
  }

  User? get user => _user;
  bool get isAuthenticated => _user != null;
  bool get isLoading => _isLoading;
  String? get uid => _user?.uid;

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    _isLoading = false;

    if (user != null) {
      await _createOrUpdateUserDoc(user);

      // Now that auth is ready, sync reminders from Firestore
      try {
        await FirestoreReminderService.refreshDeviceIdForReminders();
        await FirestoreReminderService.deactivateRemindersWithInvalidTokens();
        await FirestoreReminderService.syncAndScheduleReminders();
      } catch (e) {
        debugPrint('Error syncing reminders after auth: $e');
      }
    }

    notifyListeners();
  }

  Future<void> _createOrUpdateUserDoc(User user) async {
    try {
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      await docRef.set({
        'displayName': user.displayName,
        'email': user.email,
        'photoUrl': user.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating user doc: $e');
    }
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    notifyListeners();

    try {
      await AuthService.signInWithGoogle();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await AuthService.signOut();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
