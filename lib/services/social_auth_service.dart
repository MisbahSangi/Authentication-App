import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:twitter_login/twitter_login.dart';
import 'package:crypto/crypto.dart';

class SocialAuthService {
  final FirebaseAuth _auth = FirebaseAuth. instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ============================================
  // GOOGLE SIGN IN
  // ============================================
  Future<UserCredential? > signInWithGoogle() async {
    try {
      if (kIsWeb) {
        // Web: Use popup
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        return await _auth.signInWithPopup(googleProvider);
      } else {
        // Mobile: Use google_sign_in package
        final GoogleSignInAccount?  googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          // User cancelled the sign-in
          return null;
        }

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

        final credential = GoogleAuthProvider. credential(
          accessToken: googleAuth. accessToken,
          idToken: googleAuth. idToken,
        );

        return await _auth.signInWithCredential(credential);
      }
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOutGoogle() async {
    await _googleSignIn.signOut();
  }

  // ============================================
  // FACEBOOK SIGN IN
  // ============================================
  Future<UserCredential?> signInWithFacebook() async {
    try {
      if (kIsWeb) {
        // Web: Use popup
        final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
        facebookProvider.addScope('email');
        facebookProvider.addScope('public_profile');
        return await _auth.signInWithPopup(facebookProvider);
      } else {
        // Mobile: Use flutter_facebook_auth package
        final LoginResult loginResult = await FacebookAuth.instance. login(
          permissions: ['email', 'public_profile'],
        );

        if (loginResult. status != LoginStatus.success) {
          debugPrint('Facebook login failed: ${loginResult.status}');
          debugPrint('Message: ${loginResult. message}');
          return null;
        }

        // Get the access token
        final AccessToken? accessToken = loginResult.accessToken;

        if (accessToken == null) {
          debugPrint('Facebook access token is null');
          return null;
        }

        // Create a credential from the access token
        // ✅ FIXED: Use 'token' instead of 'tokenString'
        final OAuthCredential facebookAuthCredential =
        FacebookAuthProvider.credential(accessToken.token);

        // Sign in to Firebase with the Facebook credential
        return await _auth.signInWithCredential(facebookAuthCredential);
      }
    } catch (e) {
      debugPrint('Facebook Sign-In Error: $e');
      rethrow;
    }
  }

  Future<void> signOutFacebook() async {
    await FacebookAuth.instance.logOut();
  }

  // ============================================
  // APPLE SIGN IN
  // ============================================
  Future<UserCredential?> signInWithApple() async {
    try {
      if (kIsWeb) {
        // Web: Use popup
        final AppleAuthProvider appleProvider = AppleAuthProvider();
        appleProvider.addScope('email');
        appleProvider.addScope('name');
        return await _auth.signInWithPopup(appleProvider);
      } else {
        // Mobile: Use sign_in_with_apple package

        // Generate a random nonce
        final rawNonce = _generateNonce();
        final nonce = _sha256ofString(rawNonce);

        // Request Apple ID credential
        final appleCredential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes. fullName,
          ],
          nonce: nonce,
        );

        // Create an OAuthCredential from the Apple ID credential
        final oauthCredential = OAuthProvider("apple. com"). credential(
          idToken: appleCredential.identityToken,
          rawNonce: rawNonce,
        );

        // Sign in to Firebase with the Apple credential
        final userCredential = await _auth.signInWithCredential(oauthCredential);

        // Apple only returns the name on first sign-in
        // So we need to update the display name if we got it
        if (appleCredential.givenName != null || appleCredential. familyName != null) {
          final displayName = [
            appleCredential.givenName ??  '',
            appleCredential.familyName ?? '',
          ].where((s) => s.isNotEmpty). join(' ');

          if (displayName.isNotEmpty) {
            await userCredential.user?. updateDisplayName(displayName);
          }
        }

        return userCredential;
      }
    } catch (e) {
      debugPrint('Apple Sign-In Error: $e');
      rethrow;
    }
  }

  // ============================================
  // TWITTER SIGN IN
  // ============================================

  // ⚠️ IMPORTANT: Replace these with your actual Twitter API keys
  static const String _twitterApiKey = 'YOUR_TWITTER_API_KEY';
  static const String _twitterApiSecret = 'YOUR_TWITTER_API_SECRET';
  static const String _twitterRedirectUri = 'https://your-project-id.firebaseapp.com/__/auth/handler';

  Future<UserCredential?> signInWithTwitter() async {
    try {
      if (kIsWeb) {
        // Web: Use popup
        final TwitterAuthProvider twitterProvider = TwitterAuthProvider();
        return await _auth.signInWithPopup(twitterProvider);
      } else {
        // Mobile: Use twitter_login package
        final twitterLogin = TwitterLogin(
          apiKey: _twitterApiKey,
          apiSecretKey: _twitterApiSecret,
          redirectURI: _twitterRedirectUri,
        );

        final authResult = await twitterLogin.login();

        // ✅ FIXED: Handle nullable status properly
        final status = authResult.status;

        if (status == null) {
          debugPrint('Twitter login status is null');
          return null;
        }

        switch (status) {
          case TwitterLoginStatus.loggedIn:
          // Create a credential from the access token
            final authToken = authResult.authToken;
            final authTokenSecret = authResult. authTokenSecret;

            if (authToken == null || authTokenSecret == null) {
              debugPrint('Twitter auth tokens are null');
              return null;
            }

            final twitterAuthCredential = TwitterAuthProvider.credential(
              accessToken: authToken,
              secret: authTokenSecret,
            );

            // Sign in to Firebase with the Twitter credential
            return await _auth. signInWithCredential(twitterAuthCredential);

          case TwitterLoginStatus.cancelledByUser:
            debugPrint('Twitter login cancelled by user');
            return null;

          case TwitterLoginStatus.error:
            debugPrint('Twitter login error: ${authResult. errorMessage}');
            throw Exception(authResult.errorMessage ??  'Twitter login failed');
        }
      }
    } catch (e) {
      debugPrint('Twitter Sign-In Error: $e');
      rethrow;
    }
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Generates a cryptographically secure random nonce
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Returns the SHA256 hash of the input string
  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if Apple Sign In is available (iOS 13+, macOS 10.15+)
  Future<bool> isAppleSignInAvailable() async {
    if (kIsWeb) return true;
    return await SignInWithApple. isAvailable();
  }

  /// Sign out from all providers
  Future<void> signOutAll() async {
    await Future.wait([
      _auth.signOut(),
      _googleSignIn.signOut(),
      FacebookAuth.instance.logOut(),
    ]);
  }
}