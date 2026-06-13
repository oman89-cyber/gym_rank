import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'storage_service.dart';
import 'firebase_remote_service.dart';
import '../models/user_profile.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _initialized = false;
  
  final StreamController<void> _dataRestoredController = StreamController<void>.broadcast();
  Stream<void> get onDataRestored => _dataRestoredController.stream;

  // Stream of auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Current user
  User? get currentUser => _auth.currentUser;

  Future<void> _ensureInitialized() async {
    if (!_initialized) {
      await GoogleSignIn.instance.initialize();
      _initialized = true;
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    try {
      await _ensureInitialized();

      // Trigger the V7 authentication flow
      final GoogleSignInAccount user = await GoogleSignIn.instance.authenticate();
      
      // Obtain the authentication details containing the ID Token
      final GoogleSignInAuthentication auth = user.authentication;
      
      // Obtain the authorization token required by Firebase (Access Token)
      // The native Android Google Sign-In API crashes if this list is empty,
      // so we explicitly ask for the standard 'email' scope.
      final authz = await user.authorizationClient.authorizeScopes(['email']);

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz.accessToken,
        idToken: auth.idToken,
      );

      // Once signed in, return the UserCredential
      final userCredential = await _auth.signInWithCredential(credential);
      final newUid = userCredential.user?.uid;
      debugPrint('[AuthService] Signed in as: $newUid');

      final storage = StorageService.instance;
      final lastUid = storage.lastUid;

      // If a differnet user is logging in, WIPE the local data completely!
      if (lastUid != null && lastUid != newUid) {
        debugPrint('[AuthService] Different user detected ($lastUid -> $newUid). Wiping local data to prevent leak.');
        await storage.clearAll();
      }

      await storage.setLastUid(newUid);

      // 1. Download their existing data from the cloud and merge it into the local database
      try {
        final remote = FirebaseRemoteService();
        final cloudData = await remote.fetchUserData();
        
        // If no cloud profile exists, create one from the Auth user info
        if (cloudData['profile'] == null) {
          debugPrint('[AuthService] No cloud profile found. Saving initial profile.');
          final initialProfile = UserProfile.initial();
          await remote.saveProfile(initialProfile.toMap());
        }
        
        await storage.restoreUserData(cloudData);
        _dataRestoredController.add(null);
      } catch (e) {
        debugPrint('[AuthService] Failed to download cloud data on sign in: $e');
      }
      
      return userCredential;
    } on PlatformException catch (pe) {
      if (pe.code == 'sign_in_failed') {
        throw Exception('Google Sign-In failed. Ensure your Release or Debug SHA-1 fingerprint is added to the Firebase Console.');
      }
      rethrow;
    } catch (e) {
      debugPrint('[AuthService] Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
      try {
        await GoogleSignIn.instance.disconnect();
      } catch (_) {}
      await _auth.signOut();
      
      // Wipe all local caches on sign out so no data leaks
      await StorageService.instance.clearAll();
      await StorageService.instance.setGuestMode(false);
      debugPrint('[AuthService] Successfully signed out and wiped local cache.');
    } catch (e) {
      debugPrint('[AuthService] Sign-Out Error: $e');
      rethrow;
    }
  }
}
