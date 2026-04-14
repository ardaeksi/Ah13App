import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ascent/auth/auth_manager.dart';

/// Firebase implementation for authentication.
///
/// Uses:
/// - FirebaseAuth for email/password sign-in
/// - Firestore for user profile fields that don't belong in Auth (e.g. Parent PIN hash)
class FirebaseAuthManager extends AuthManager with EmailSignInManager {
  FirebaseAuthManager({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuth get auth => _auth;
  FirebaseFirestore get firestore => _firestore;

  @override
  Future<User?> signInWithEmail(BuildContext context, String email, String password) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase signInWithEmail failed: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Firebase signInWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<User?> createAccountWithEmail(BuildContext context, String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      return cred.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase createAccountWithEmail failed: ${e.code} ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Firebase createAccountWithEmail failed: $e');
      rethrow;
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> deleteUser(BuildContext context) async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase deleteUser failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> updateEmail({required String email, required BuildContext context}) async {
    try {
      // firebase_auth v5+ recommends verify-before-update flows.
      await _auth.currentUser?.verifyBeforeUpdateEmail(email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase updateEmail failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  @override
  Future<void> resetPassword({required String email, required BuildContext context}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      debugPrint('Firebase resetPassword failed: ${e.code} ${e.message}');
      rethrow;
    }
  }

  /// Convenience helper: `users/{uid}` document reference.
  DocumentReference<Map<String, dynamic>> userDoc(String uid) => _firestore.collection('users').doc(uid);
}
