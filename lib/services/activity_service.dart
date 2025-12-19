import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Log a new activity
  Future<void> logActivity({
    required String type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore.collection('activities').add({
        'userId': userId,
        'type': type,
        'description': description,
        'metadata': metadata ?? {},
        'timestamp': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // Silently fail - activity logging should not break the app
      print('Failed to log activity: $e');
    }
  }

  /// Get recent activities for the current user
  Future<List<Map<String, dynamic>>> getRecentActivities({int limit = 10}) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          .collection('activities')
          . where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Failed to get activities: $e');
      return [];
    }
  }

  /// Get all activities for the current user
  Future<List<Map<String, dynamic>>> getAllActivities() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          . collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Failed to get all activities: $e');
      return [];
    }
  }

  /// Delete a specific activity
  Future<void> deleteActivity(String activityId) async {
    try {
      await _firestore.collection('activities').doc(activityId).delete();
    } catch (e) {
      print('Failed to delete activity: $e');
    }
  }

  /// Clear all activities for the current user
  Future<void> clearAllActivities() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          . get();

      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Failed to clear activities: $e');
    }
  }

  /// Log login activity
  Future<void> logLogin() async {
    await logActivity(
      type: 'login',
      description: 'Logged in successfully',
    );
  }

  /// Log logout activity
  Future<void> logLogout() async {
    await logActivity(
      type: 'logout',
      description: 'Logged out',
    );
  }

  /// Log password change
  Future<void> logPasswordChange() async {
    await logActivity(
      type: 'password_changed',
      description: 'Password changed successfully',
    );
  }

  /// Log email update
  Future<void> logEmailUpdate(String newEmail) async {
    await logActivity(
      type: 'email_updated',
      description: 'Email updated to $newEmail',
      metadata: {'newEmail': newEmail},
    );
  }

  /// Log profile update
  Future<void> logProfileUpdate() async {
    await logActivity(
      type: 'profile_updated',
      description: 'Profile information updated',
    );
  }

  /// Log 2FA enabled
  Future<void> log2FAEnabled() async {
    await logActivity(
      type: '2fa_enabled',
      description: 'Two-Factor Authentication enabled',
    );
  }

  /// Log 2FA disabled
  Future<void> log2FADisabled() async {
    await logActivity(
      type: '2fa_disabled',
      description: 'Two-Factor Authentication disabled',
    );
  }

  /// Log biometric enabled
  Future<void> logBiometricEnabled() async {
    await logActivity(
      type: 'biometric_enabled',
      description: 'Biometric login enabled',
    );
  }

  /// Log biometric disabled
  Future<void> logBiometricDisabled() async {
    await logActivity(
      type: 'biometric_disabled',
      description: 'Biometric login disabled',
    );
  }

  /// Log account creation
  Future<void> logAccountCreated() async {
    await logActivity(
      type: 'account_created',
      description: 'Account created successfully',
    );
  }
}