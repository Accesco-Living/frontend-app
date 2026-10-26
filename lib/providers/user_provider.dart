import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/firebase_service.dart';
import '../services/api_service.dart';

class UserProvider with ChangeNotifier {
  AppUser? _user;
  bool _isLoading = true;

  AppUser? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;
  bool get isPhoneMissing => _user != null && !_user!.phoneVerified;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    // 1. Check VPS session first (from SharedPreferences)
    try {
      final vpsProfile = await ApiService.getUserProfile();
      final token = await ApiService.getToken();
      if (token != null && token.isNotEmpty && vpsProfile != null) {
        _user = AppUser(
          uid: vpsProfile['uid']?.toString() ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
          name: vpsProfile['name']?.toString() ?? 'Accesco Member',
          email: vpsProfile['email']?.toString() ?? '',
          phone: vpsProfile['phone']?.toString(),
          phoneVerified: true,
          householdId: vpsProfile['household_id']?.toString() ?? 'HH-ACCESCO',
          credits: (vpsProfile['credits'] as num?)?.toInt() ?? 500,
          cqsScore: (vpsProfile['cqs_score'] as num?)?.toDouble() ?? 85.0,
          role: vpsProfile['role']?.toString() ?? 'Resident',
        );
        _isLoading = false;
        notifyListeners();
        return;
      }
    } catch (e) {
      debugPrint('VPS profile restore error: $e');
    }

    // 2. Fallback to Firebase Auth if apps are initialized
    if (Firebase.apps.isNotEmpty) {
      FirebaseAuth.instance.authStateChanges().listen((firebaseUser) async {
        if (_user != null) return; // Keep VPS session if active
        if (firebaseUser == null || firebaseUser.isAnonymous) {
          if (firebaseUser?.isAnonymous ?? false) {
            await FirebaseAuth.instance.signOut();
          }
          _user = null;
          _isLoading = false;
          notifyListeners();
        } else {
          await refreshUser(firebaseUser);
        }
      });
    } else {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Sets the active user from VPS signup/login/OTP
  void setVpsUser({
    required String uid,
    required String name,
    required String email,
    String? phone,
    String? householdId,
    int credits = 500,
    double cqsScore = 85.0,
    String role = 'Resident',
  }) {
    _user = AppUser(
      uid: uid,
      name: name,
      email: email,
      phone: phone,
      phoneVerified: true,
      householdId: householdId ?? 'HH-ACCESCO',
      credits: credits,
      cqsScore: cqsScore,
      role: role,
    );
    _isLoading = false;
    notifyListeners();
  }

  /// Refresh user data from Firestore and Backend
  Future<void> refreshUser(User firebaseUser) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Get Firestore profile
      DocumentSnapshot<Map<String, dynamic>> doc =
          await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      
      if (!doc.exists) {
        // Create initial profile if it doesn't exist
        await FirebaseService.syncFirestoreProfile(firebaseUser);
        doc = await FirebaseFirestore.instance.collection('users').doc(firebaseUser.uid).get();
      }

      final userData = doc.data() ?? {};
      var parsedUser = AppUser.fromJson(userData);

      // Fallback: If UID or name is empty, populate from firebaseUser
      if (parsedUser.uid.isEmpty) {
        parsedUser = AppUser(
          uid: firebaseUser.uid,
          name: (firebaseUser.displayName?.isNotEmpty ?? false)
              ? firebaseUser.displayName!
              : (userData['name'] ?? 'Accesco Member'),
          email: firebaseUser.email ?? userData['email'] ?? '',
          phone: firebaseUser.phoneNumber ?? userData['phone'],
          phoneVerified: firebaseUser.phoneNumber != null ||
              (userData['phoneVerified'] ?? true),
          photoUrl: firebaseUser.photoURL,
        );
      }
      _user = parsedUser;

      // 2. Sync with Backend only if phone is verified
      if (_user != null && _user!.phoneVerified) {
        try {
          final idToken = await firebaseUser
              .getIdToken()
              .timeout(const Duration(seconds: 3));
          if (idToken != null) {
            final backendData = await ApiService.syncWithBackend(idToken);
            if (backendData != null && _user != null) {
              _user = _user!.copyWith(
                householdId: backendData['household_id'],
                credits: backendData['credits'],
                cqsScore: (backendData['cqs_score'] ?? 0.0).toDouble(),
                role: backendData['role'],
              );
            }
          }
        } catch (e) {
          debugPrint('Backend sync skipped or timed out: $e');
        }
      }
    } catch (e) {
      debugPrint('Error refreshing user: $e');
      // If Firestore read fails, construct a valid fallback user from Firebase Auth state
      _user ??= AppUser(
        uid: firebaseUser.uid,
        name: firebaseUser.displayName ?? 'Accesco Member',
        email: firebaseUser.email ?? '',
        phone: firebaseUser.phoneNumber,
        phoneVerified: true,
        photoUrl: firebaseUser.photoURL,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.logout();
    } catch (e) {
      debugPrint('VPS logout error: $e');
    }

    try {
      await ApiService.clearUserProfile();
    } catch (_) {}

    try {
      await ApiService.clearToken();
    } catch (_) {}

    try {
      await ApiService.clearHashCache();
    } catch (_) {}

    if (Firebase.apps.isNotEmpty) {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      try {
        await FirebaseService.logout();
      } catch (_) {}
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('accesco_logged_in', false);
      await prefs.remove('accesco_profile_completed');
      await prefs.remove('accesco_phone');
      await prefs.remove('accesco_name');
      await prefs.remove('accesco_email');
      await prefs.remove('vps_last_otp_phone');
      await prefs.remove('vps_last_otp_challenge');
      await prefs.remove('vps_otp_hash_challenge');
    } catch (e) {
      debugPrint('Error clearing prefs on logout: $e');
    }

    _user = null;
    _isLoading = false;
    notifyListeners();
  }
}