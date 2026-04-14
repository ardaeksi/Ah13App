import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ChangeNotifier;

import 'package:ascent/auth/firebase_auth_manager.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider({FirebaseAuthManager? authManager}) : _authManager = authManager ?? FirebaseAuthManager() {
    _sub = _authManager.auth.authStateChanges().listen((u) {
      _currentUser = u;
      notifyListeners();
    });
  }

  final FirebaseAuthManager _authManager;
  late final StreamSubscription<fb.User?> _sub;

  fb.User? _currentUser;
  bool _isLoading = false;
  String? _lastError;

  fb.User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  static String _authMessageFromCode(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'That email is already in use. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is not enabled in Firebase.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  static bool _looksLikeFirestoreNotEnabled(Object e) {
    final msg = e.toString().toLowerCase();
    return msg.contains("database '(default)' not found") || msg.contains('failed-precondition');
  }

  Future<void> _ensureUserProfileExists({required fb.User user, required String name, required String parentsPin}) async {
    final pinHash = _hashParentsPin(uid: user.uid, pin: parentsPin);
    final now = DateTime.now().toUtc();
    final ref = _authManager.userDoc(user.uid);

    // Use a strict timeout so the UI never spins indefinitely.
    await ref
        .set({
          'uid': user.uid,
          'email': user.email,
          'name': name.trim(),
          'parents_pin_hash': pinHash,
          'totalPoints': 0,
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }, SetOptions(merge: true))
        .timeout(const Duration(seconds: 12));

    // Confirm the doc is readable (guards against partial/failed writes on misconfigured projects).
    final snap = await ref.get().timeout(const Duration(seconds: 12));
    if (!snap.exists) {
      throw StateError('User profile document was not created.');
    }
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final cred = await _authManager.auth.signInWithEmailAndPassword(email: email.trim(), password: password);
      final user = cred.user;
      if (user == null) return false;

      // Ensure the profile doc is readable (we sync points to it).
      try {
        await _authManager.userDoc(user.uid).get().timeout(const Duration(seconds: 12));
      } catch (e) {
        debugPrint('Login Firestore profile check failed: $e');
        await _authManager.signOut();
        if (_looksLikeFirestoreNotEnabled(e)) {
          _lastError = 'Firestore is not enabled/configured for this Firebase project. Please enable Firestore Database, then try again.';
        } else {
          _lastError = 'Could not load your profile from the database. Please try again.';
        }
        return false;
      }

      _currentUser = user;
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _lastError = _authMessageFromCode(e.code);
      debugPrint('Login failed: ${e.code} ${e.message}');
      return false;
    } on Exception catch (e) {
      _lastError = 'Login failed. Please try again.';
      debugPrint('Login failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> register(String email, String password, String name, {required String parentsPin}) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();
    try {
      final cred = await _authManager.auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
      final user = cred.user;
      if (user == null) return false;

      // Store display name in Auth profile (optional).
      try {
        await user.updateDisplayName(name.trim());
      } catch (e) {
        debugPrint('Failed to update displayName: $e');
      }

      // HARD requirement: ensure Firestore profile doc exists before proceeding.
      try {
        await _ensureUserProfileExists(user: user, name: name, parentsPin: parentsPin);
      } catch (e) {
        debugPrint('Registration Firestore profile setup failed: $e');

        // Roll back: do not leave an Auth account created if the app cannot function.
        try {
          await user.delete();
        } catch (deleteErr) {
          debugPrint('Failed to delete partially-created user: $deleteErr');
          // If delete fails (requires recent login), at least sign out.
          try {
            await _authManager.signOut();
          } catch (_) {}
        }

        if (_looksLikeFirestoreNotEnabled(e)) {
          _lastError = 'Could not create your profile because Firestore is not enabled/configured for this Firebase project. Enable Firestore Database, then try again.';
        } else if (e is TimeoutException) {
          _lastError = 'Database timed out while creating your profile. Please try again.';
        } else {
          _lastError = 'Could not create your profile in the database. Please try again.';
        }
        return false;
      }

      _currentUser = user;
      return true;
    } on fb.FirebaseAuthException catch (e) {
      _lastError = _authMessageFromCode(e.code);
      debugPrint('Registration failed: ${e.code} ${e.message}');
      return false;
    } on Exception catch (e) {
      _lastError = 'Registration failed. Please try again.';
      debugPrint('Registration failed: $e');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await _authManager.signOut();
    } catch (e) {
      debugPrint('Logout failed: $e');
    }
  }

  /// Returns true if the provided PIN matches the one set during registration.
  Future<bool> verifyParentsPin(String pin) async {
    final user = _authManager.auth.currentUser;
    if (user == null) return false;

    try {
      final snap = await _authManager.userDoc(user.uid).get().timeout(const Duration(seconds: 12));
      final data = snap.data();
      final storedHash = (data?['parents_pin_hash'] as String?)?.trim();
      if (storedHash == null || storedHash.isEmpty) {
        debugPrint('No parents_pin_hash stored for uid=${user.uid}');
        return false;
      }
      final inputHash = _hashParentsPin(uid: user.uid, pin: pin);
      return inputHash == storedHash;
    } catch (e) {
      _lastError = e.toString();
      debugPrint('Failed to verify parent pin: $e');
      return false;
    }
  }

  static String _hashParentsPin({required String uid, required String pin}) {
    final normalized = pin.trim();
    // Salt with uid so identical pins across users don't share the same hash.
    final bytes = utf8.encode('$uid:$normalized');
    return sha256.convert(bytes).toString();
  }
}