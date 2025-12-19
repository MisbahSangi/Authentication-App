import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginAlertService {
  final FirebaseFirestore _firestore = FirebaseFirestore. instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String _loginAlertsEnabledKey = 'login_alerts_enabled';
  static const String _emailAlertsEnabledKey = 'email_alerts_enabled';

  /// Get current device info
  Map<String, dynamic> getDeviceInfo() {
    String deviceType = 'Unknown';
    String platform = 'Unknown';
    String deviceName = 'Unknown Device';

    if (kIsWeb) {
      deviceType = 'Web Browser';
      platform = 'Web';
      deviceName = 'Web Browser';
    } else {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          deviceType = 'Mobile';
          platform = 'Android';
          deviceName = 'Android Device';
          break;
        case TargetPlatform. iOS:
          deviceType = 'Mobile';
          platform = 'iOS';
          deviceName = 'iPhone/iPad';
          break;
        case TargetPlatform. windows:
          deviceType = 'Desktop';
          platform = 'Windows';
          deviceName = 'Windows PC';
          break;
        case TargetPlatform.macOS:
          deviceType = 'Desktop';
          platform = 'macOS';
          deviceName = 'Mac';
          break;
        case TargetPlatform.linux:
          deviceType = 'Desktop';
          platform = 'Linux';
          deviceName = 'Linux PC';
          break;
        default:
          deviceType = 'Unknown';
          platform = 'Unknown';
          deviceName = 'Unknown Device';
      }
    }

    return {
      'deviceType': deviceType,
      'platform': platform,
      'deviceName': deviceName,
    };
  }

  /// Check if login alerts are enabled
  Future<bool> isLoginAlertsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_loginAlertsEnabledKey) ??  true;
    } catch (e) {
      return true;
    }
  }

  /// Enable/disable login alerts
  Future<void> setLoginAlertsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences. getInstance();
      await prefs. setBool(_loginAlertsEnabledKey, enabled);

      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore. collection('users').doc(userId). update({
          'loginAlertsEnabled': enabled,
        });
      }
    } catch (e) {
      print('Error setting login alerts: $e');
    }
  }

  /// Check if email alerts are enabled
  Future<bool> isEmailAlertsEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_emailAlertsEnabledKey) ??  true;
    } catch (e) {
      return true;
    }
  }

  /// Enable/disable email alerts
  Future<void> setEmailAlertsEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_emailAlertsEnabledKey, enabled);

      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore.collection('users').doc(userId).update({
          'emailAlertsEnabled': enabled,
        });
      }
    } catch (e) {
      print('Error setting email alerts: $e');
    }
  }

  /// Record a login event and send alert
  Future<void> recordLoginAndAlert() async {
    try {
      final userId = _auth.currentUser?.uid;
      final userEmail = _auth.currentUser?.email;
      if (userId == null) return;

      final deviceInfo = getDeviceInfo();

      // Record login in Firestore
      await _firestore.collection('users').doc(userId).collection('login_history').add({
        ... deviceInfo,
        'loginAt': FieldValue.serverTimestamp(),
        'email': userEmail,
      });

      // Check if alerts are enabled
      final alertsEnabled = await isLoginAlertsEnabled();
      if (! alertsEnabled) return;

      // Create in-app notification with ALL required fields at ROOT level
      await _firestore.collection('notifications').add({
        'userId': userId,
        'title': 'New Login Detected',
        'message': 'A new login was detected from ${deviceInfo['deviceName']} (${deviceInfo['platform']})',
        'type': 'security',
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
        'deviceName': deviceInfo['deviceName'],
        'deviceType': deviceInfo['deviceType'],
        'platform': deviceInfo['platform'],
      });

      print('✅ Notification created successfully for user: $userId');

    } catch (e) {
      print('Error recording login alert: $e');
    }
  }

  /// Get login history
  Future<List<Map<String, dynamic>>> getLoginHistory({int limit = 20}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          . collection('login_history')
          .orderBy('loginAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }). toList();
    } catch (e) {
      print('Error getting login history: $e');
      return [];
    }
  }

  /// Clear login history
  Future<void> clearLoginHistory() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          . doc(userId)
          .collection('login_history')
          . get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing login history: $e');
    }
  }
}