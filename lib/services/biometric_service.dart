import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  /// Check if biometric is available on this device
  Future<bool> isBiometricAvailable() async {
    if (kIsWeb) {
      print('🔒 Biometric: Not available on web');
      return false;
    }

    try {
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      print('🔒 Biometric: Device supported = $isDeviceSupported');

      if (!isDeviceSupported) {
        return false;
      }

      final canCheckBiometrics = await _localAuth.canCheckBiometrics;
      print('🔒 Biometric: Can check biometrics = $canCheckBiometrics');

      if (!canCheckBiometrics) {
        return false;
      }

      final availableBiometrics = await _localAuth.getAvailableBiometrics();
      print('🔒 Biometric: Available types = $availableBiometrics');

      final hasEnrolledBiometrics = availableBiometrics.isNotEmpty;
      print('🔒 Biometric: Has enrolled = $hasEnrolledBiometrics');

      return hasEnrolledBiometrics;
    } catch (e) {
      print('🔒 Biometric Error: $e');
      return false;
    }
  }

  /// Check if biometric login is enabled by user
  Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs. getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Enable biometric login
  Future<void> enableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, true);
  }

  /// Disable biometric login
  Future<void> disableBiometric() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_biometricEnabledKey, false);
    await prefs.remove('biometric_email');
    await prefs.remove('biometric_password');
  }

  /// Authenticate using biometrics
  Future<bool> authenticate({required String reason}) async {
    if (kIsWeb) {
      print('🔒 Biometric: Cannot authenticate on web');
      return false;
    }

    try {
      final isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        print('🔒 Biometric: Not available for authentication');
        return false;
      }

      final authenticated = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );

      print('🔒 Biometric: Authentication result = $authenticated');
      return authenticated;
    } catch (e) {
      print('🔒 Biometric Authentication Error: $e');
      return false;
    }
  }

  /// Get list of available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    if (kIsWeb) return [];

    try {
      return await _localAuth. getAvailableBiometrics();
    } catch (e) {
      print('Error getting biometrics: $e');
      return [];
    }
  }

  /// Save credentials for biometric login
  Future<void> saveCredentials(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('biometric_email', email);
    await prefs.setString('biometric_password', password);
  }

  /// Get saved credentials
  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('biometric_email');
    final password = prefs.getString('biometric_password');

    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}