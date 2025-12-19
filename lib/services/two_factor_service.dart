import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:base32/base32.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TwoFactorService {
  final FirebaseFirestore _firestore = FirebaseFirestore. instance;
  final FirebaseAuth _auth = FirebaseAuth. instance;

  static const String _twoFaEnabledKey = 'two_fa_enabled';
  static const String _twoFaSecretKey = 'two_fa_secret';

  // Generate a random secret key for TOTP (Base32 compatible)
  String generateSecretKey() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    // Generate 16 characters (80 bits) - standard for Google Authenticator
    return List.generate(16, (_) => chars[random.nextInt(chars.length)]).join();
  }

  // Generate TOTP code from secret
  String generateTOTP(String secret, {int?  timestamp}) {
    try {
      // Get current time counter (30-second intervals since Unix epoch)
      final time = timestamp ?? (DateTime.now().millisecondsSinceEpoch ~/ 1000);
      final counter = time ~/ 30;

      // Convert counter to 8-byte big-endian
      final counterBytes = _intToBytes(counter);

      // Decode the base32 secret
      final key = base32.decode(secret. toUpperCase());

      // Calculate HMAC-SHA1
      final hmac = Hmac(sha1, key);
      final hash = hmac.convert(counterBytes);

      // Dynamic truncation
      final offset = hash.bytes[hash.bytes.length - 1] & 0x0f;
      final binary = ((hash.bytes[offset] & 0x7f) << 24) |
      ((hash.bytes[offset + 1] & 0xff) << 16) |
      ((hash.bytes[offset + 2] & 0xff) << 8) |
      (hash. bytes[offset + 3] & 0xff);

      // Get 6-digit code
      final otp = binary % 1000000;
      return otp.toString().padLeft(6, '0');
    } catch (e) {
      print('Error generating TOTP: $e');
      return '';
    }
  }

  // Convert int to 8-byte big-endian Uint8List
  Uint8List _intToBytes(int value) {
    final result = Uint8List(8);
    for (var i = 7; i >= 0; i--) {
      result[i] = value & 0xff;
      value >>= 8;
    }
    return result;
  }

  // Verify TOTP code with time window tolerance
  bool verifyTOTP(String secret, String code) {
    if (code.length != 6) return false;

    try {
      final currentTime = DateTime.now().millisecondsSinceEpoch ~/ 1000;

      // Check current time and +/- 1 time step (90 second window total)
      // This handles clock skew between server and authenticator app
      for (var i = -2; i <= 2; i++) {
        final checkTime = currentTime + (i * 30);
        final generatedCode = generateTOTP(secret, timestamp: checkTime);

        print('Checking time offset $i: Generated=$generatedCode, Input=$code');

        if (generatedCode == code) {
          print('TOTP verification successful! ');
          return true;
        }
      }

      print('TOTP verification failed - no match found');
      return false;
    } catch (e) {
      print('Error verifying TOTP: $e');
      return false;
    }
  }

  // Generate QR code data for authenticator apps
  String generateQRCodeData(String secret, String email) {
    final issuer = 'AuthApp';
    final encodedEmail = Uri.encodeComponent(email);
    final encodedIssuer = Uri. encodeComponent(issuer);
    return 'otpauth://totp/$encodedIssuer:$encodedEmail?secret=$secret&issuer=$encodedIssuer&algorithm=SHA1&digits=6&period=30';
  }

  // Enable 2FA for user
  Future<void> enable2FA(String secret) async {
    final userId = _auth.currentUser?. uid;
    if (userId == null) throw Exception('User not logged in');

    // Save to Firestore
    await _firestore.collection('users').doc(userId).set({
      'twoFactorEnabled': true,
      'twoFactorSecret': secret,
      'twoFactorEnabledAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Save locally
    final prefs = await SharedPreferences.getInstance();
    await prefs. setBool(_twoFaEnabledKey, true);
    await prefs.setString(_twoFaSecretKey, secret);
  }

  // Disable 2FA for user
  Future<void> disable2FA() async {
    final userId = _auth. currentUser?.uid;
    if (userId == null) return;

    // Remove from Firestore
    await _firestore.collection('users'). doc(userId).update({
      'twoFactorEnabled': false,
      'twoFactorSecret': FieldValue.delete(),
      'twoFactorDisabledAt': FieldValue.serverTimestamp(),
    });

    // Remove locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_twoFaEnabledKey, false);
    await prefs.remove(_twoFaSecretKey);
  }

  // Check if 2FA is enabled
  Future<bool> is2FAEnabled() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore.collection('users'). doc(userId).get();
      return doc.data()?['twoFactorEnabled'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if 2FA is enabled for email (before login)
  Future<bool> is2FAEnabledForEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return false;
      return query.docs.first.data()['twoFactorEnabled'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Get secret for user
  Future<String?> getSecret() async {
    final userId = _auth. currentUser?.uid;
    if (userId == null) return null;

    try {
      final doc = await _firestore. collection('users'). doc(userId).get();
      return doc. data()?['twoFactorSecret'];
    } catch (e) {
      return null;
    }
  }

  // Get secret by email (for login verification)
  Future<String?> getSecretByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return null;
      return query.docs.first.data()['twoFactorSecret'];
    } catch (e) {
      return null;
    }
  }

  // Generate backup codes
  List<String> generateBackupCodes() {
    final random = Random.secure();
    return List.generate(8, (_) {
      return List. generate(8, (_) => random.nextInt(10)). join();
    });
  }

  // Save backup codes
  Future<void> saveBackupCodes(List<String> codes) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    await _firestore.collection('users').doc(userId).set({
      'backupCodes': codes,
    }, SetOptions(merge: true));
  }

  // Verify backup code
  Future<bool> verifyBackupCode(String code) async {
    final userId = _auth. currentUser?.uid;
    if (userId == null) return false;

    try {
      final doc = await _firestore. collection('users'). doc(userId).get();
      final codes = List<String>.from(doc.data()?['backupCodes'] ?? []);

      if (codes.contains(code)) {
        codes.remove(code);
        await _firestore.collection('users').doc(userId).update({
          'backupCodes': codes,
        });
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}