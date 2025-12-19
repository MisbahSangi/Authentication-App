import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with Email and Password
  Future<UserCredential? > signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      print('[Auth] Email sign in error: $e');
      rethrow;
    }
  }

  /// Sign up with Email and Password
  Future<UserCredential?> signUpWithEmail(String email, String password, String name) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential. user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'name': name,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'provider': 'email',
        });

        await userCredential.user! .updateDisplayName(name);
      }

      return userCredential;
    } catch (e) {
      print('[Auth] Email sign up error: $e');
      rethrow;
    }
  }

  /// Sign in with Google - Cross Platform
  Future<UserCredential?> signInWithGoogle() async {
    try {
      if (kIsWeb) {
        GoogleAuthProvider googleProvider = GoogleAuthProvider();
        googleProvider.addScope('email');
        googleProvider.addScope('profile');
        return await _auth.signInWithPopup(googleProvider);
      } else {
        final GoogleSignIn googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          print('[Auth] Google sign in cancelled by user');
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth. idToken,
        );

        final userCredential = await _auth.signInWithCredential(credential);

        if (userCredential.user != null) {
          await _firestore.collection('users'). doc(userCredential.user!.uid).set({
            'name': userCredential.user?. displayName ?? '',
            'email': userCredential.user?.email ?? '',
            'photoUrl': userCredential. user?.photoURL,
            'lastLoginAt': FieldValue.serverTimestamp(),
            'provider': 'google',
          }, SetOptions(merge: true));
        }

        return userCredential;
      }
    } catch (e) {
      print('[Auth] Google sign in error: $e');
      rethrow;
    }
  }

  /// Sign in with Facebook - Cross Platform
  Future<UserCredential? > signInWithFacebook() async {
    try {
      if (kIsWeb) {
        FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        facebookProvider.addScope('public_profile');
        return await _auth.signInWithPopup(facebookProvider);
      } else {
        print('[Auth] Facebook mobile auth requires flutter_facebook_auth package');
        throw UnimplementedError('Facebook mobile auth not implemented');
      }
    } catch (e) {
      print('[Auth] Facebook sign in error: $e');
      rethrow;
    }
  }

  /// Sign in with Twitter - Cross Platform
  Future<UserCredential?> signInWithTwitter() async {
    try {
      if (kIsWeb) {
        TwitterAuthProvider twitterProvider = TwitterAuthProvider();
        return await _auth.signInWithPopup(twitterProvider);
      } else {
        print('[Auth] Twitter mobile auth requires twitter_login package');
        throw UnimplementedError('Twitter mobile auth not implemented');
      }
    } catch (e) {
      print('[Auth] Twitter sign in error: $e');
      rethrow;
    }
  }

  /// Sign in with Apple - Cross Platform
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        AppleAuthProvider appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        return await _auth.signInWithPopup(appleProvider);
      } else {
        print('[Auth] Apple mobile auth requires sign_in_with_apple package');
        throw UnimplementedError('Apple mobile auth not implemented');
      }
    } catch (e) {
      print('[Auth] Apple sign in error: $e');
      rethrow;
    }
  }

  /// Sign Out
  Future<void> signOut() async {
    try {
      if (! kIsWeb) {
        try {
          final GoogleSignIn googleSignIn = GoogleSignIn();
          await googleSignIn.signOut();
        } catch (e) {
          // Ignore if not signed in with Google
        }
      }

      await _auth. signOut();
      print('[Auth] User signed out');
    } catch (e) {
      print('[Auth] Sign out error: $e');
      rethrow;
    }
  }

  /// Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('[Auth] Password reset email sent');
    } catch (e) {
      print('[Auth] Password reset error: $e');
      rethrow;
    }
  }

  /// Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
      print('[Auth] Verification email sent');
    } catch (e) {
      print('[Auth] Email verification error: $e');
      rethrow;
    }
  }

  /// Delete Account
  Future<void> deleteAccount() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId != null) {
        await _firestore. collection('users'). doc(userId).delete();
      }
      await _auth.currentUser?.delete();
      print('[Auth] Account deleted');
    } catch (e) {
      print('[Auth] Delete account error: $e');
      rethrow;
    }
  }
}