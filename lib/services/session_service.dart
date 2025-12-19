import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class SessionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth. instance;

  /// Get current device info
  Map<String, dynamic> _getDeviceInfo() {
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
          deviceType = 'Android Device';
          platform = 'Android';
          deviceName = 'Android Device';
          break;
        case TargetPlatform.iOS:
          deviceType = 'iPhone/iPad';
          platform = 'iOS';
          deviceName = 'iPhone/iPad';
          break;
        case TargetPlatform.windows:
          deviceType = 'Windows PC';
          platform = 'Windows';
          deviceName = 'Windows PC';
          break;
        case TargetPlatform.macOS:
          deviceType = 'Mac';
          platform = 'macOS';
          deviceName = 'Mac';
          break;
        case TargetPlatform.linux:
          deviceType = 'Linux PC';
          platform = 'Linux';
          deviceName = 'Linux PC';
          break;
        default:
          deviceType = 'Unknown Device';
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

  /// Create a new session when user logs in
  Future<String? > createSession() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final deviceInfo = _getDeviceInfo();
      final sessionId = DateTime.now().millisecondsSinceEpoch.toString();

      // Mark all other sessions as not current
      final otherSessions = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('isCurrent', isEqualTo: true)
          .get();
      final batch = _firestore. batch();
      for (final doc in otherSessions.docs) {
        batch.update(doc.reference, {'isCurrent': false});
      }
      await batch.commit();

      // Create new session
      await _firestore
          .collection('users')
          .doc(userId)
          . collection('sessions')
          . doc(sessionId)
          .set({
        'sessionId': sessionId,
        'deviceType': deviceInfo['deviceType'],
        'deviceName': deviceInfo['deviceName'],
        'platform': deviceInfo['platform'],
        'createdAt': FieldValue.serverTimestamp(),
        'lastActiveAt': FieldValue.serverTimestamp(),
        'isActive': true,
        'isCurrent': true,
        'userId': userId,
      });

      print('✅ Session created: $sessionId');
      return sessionId;
    } catch (e) {
      print('❌ Error creating session: $e');
      return null;
    }
  }

  /// Update last active time for current session
  Future<void> updateSessionActivity(String sessionId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          . doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'lastActiveAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating session: $e');
    }
  }

  /// Get all active sessions for current user
  Future<List<Map<String, dynamic>>> getActiveSessions() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId == null) return [];

      final snapshot = await _firestore
          . collection('users')
          . doc(userId)
          .collection('sessions')
          .where('isActive', isEqualTo: true)
          .orderBy('lastActiveAt', descending: true)
          .get();

      print('📱 Found ${snapshot.docs.length} active sessions');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    } catch (e) {
      print('Error getting sessions: $e');

      // Fallback without orderBy (if index not created)
      try {
        final userId = _auth.currentUser?. uid;
        if (userId == null) return [];

        final snapshot = await _firestore
            . collection('users')
            . doc(userId)
            .collection('sessions')
            .where('isActive', isEqualTo: true)
            .get();

        print('📱 Fallback: Found ${snapshot.docs.length} active sessions');

        final sessions = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sort manually by lastActiveAt
        sessions.sort((a, b) {
          final aTime = a['lastActiveAt'] as Timestamp? ;
          final bTime = b['lastActiveAt'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        return sessions;
      } catch (e2) {
        print('Fallback also failed: $e2');
        return [];
      }
    }
  }

  /// Stream of active sessions
  Stream<List<Map<String, dynamic>>> getActiveSessionsStream() {
    final userId = _auth.currentUser?. uid;
    if (userId == null) return Stream.value([]);

    return _firestore
        .collection('users')
        .doc(userId)
        .collection('sessions')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final sessions = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Sort manually
      sessions.sort((a, b) {
        final aTime = a['lastActiveAt'] as Timestamp?;
        final bTime = b['lastActiveAt'] as Timestamp?;
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

      return sessions;
    });
  }

  /// Revoke a specific session (logout from that device)
  Future<bool> revokeSession(String sessionId) async {
    try {
      final userId = _auth. currentUser?.uid;
      if (userId == null) return false;

      await _firestore
          .collection('users')
          . doc(userId)
          .collection('sessions')
          .doc(sessionId)
          .update({
        'isActive': false,
        'revokedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Session revoked: $sessionId');
      return true;
    } catch (e) {
      print('Error revoking session: $e');
      return false;
    }
  }

  /// Revoke all sessions except current one
  Future<bool> revokeAllOtherSessions() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return false;

      final snapshot = await _firestore
          . collection('users')
          . doc(userId)
          .collection('sessions')
          .where('isActive', isEqualTo: true)
          .where('isCurrent', isEqualTo: false)
          .get();

      for (final doc in snapshot.docs) {
        await doc.reference. update({
          'isActive': false,
          'revokedAt': FieldValue. serverTimestamp(),
        });
      }

      print('✅ All other sessions revoked');
      return true;
    } catch (e) {
      print('Error revoking all sessions: $e');
      return false;
    }
  }

  /// End current session (on logout)
  Future<void> endCurrentSession() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('users')
          . doc(userId)
          .collection('sessions')
          .where('isCurrent', isEqualTo: true)
          .get();

      for (final doc in snapshot. docs) {
        await doc. reference.update({
          'isActive': false,
          'isCurrent': false,
          'endedAt': FieldValue.serverTimestamp(),
        });
      }

      print('✅ Current session ended');
    } catch (e) {
      print('Error ending session: $e');
    }
  }

  /// Get session count
  Future<int> getActiveSessionCount() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      return 0;
    }
  }
}