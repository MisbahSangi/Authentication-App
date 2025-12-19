import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatisticsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get all statistics for the current user
  Future<Map<String, dynamic>> getUserStatistics() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId == null) {
        return _getEmptyStats();
      }

      // Get user document
      final userDoc = await _firestore.collection('users'). doc(userId).get();
      final userData = userDoc.data() ??  {};

      // Get activity count
      final activitiesSnapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();
      final totalActivities = activitiesSnapshot.docs. length;

      // Get login count
      final loginHistorySnapshot = await _firestore
          . collection('users')
          .doc(userId)
          .collection('login_history')
          .get();
      final totalLogins = loginHistorySnapshot.docs.length;

      // Get session count
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          . collection('sessions')
          .where('isActive', isEqualTo: true)
          .get();
      final activeSessions = sessionsSnapshot.docs.length;

      // Get notification count
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();
      final totalNotifications = notificationsSnapshot.docs.length;

      // Get unread notification count
      final unreadNotificationsSnapshot = await _firestore
          . collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          . get();
      final unreadNotifications = unreadNotificationsSnapshot.docs.length;

      // Calculate account age
      final createdAt = userData['createdAt'] as Timestamp? ;
      int accountAgeDays = 0;
      if (createdAt != null) {
        accountAgeDays = DateTime.now().difference(createdAt. toDate()).inDays;
      }

      // Get profile completion
      final profileCompletion = _calculateProfileCompletion(userData);

      // Get security score
      final securityScore = _calculateSecurityScore(userData);

      // Get recent activity breakdown
      final activityBreakdown = await _getActivityBreakdown(userId);

      // Get login trends (last 7 days)
      final loginTrends = await _getLoginTrends(userId);

      return {
        'totalActivities': totalActivities,
        'totalLogins': totalLogins,
        'activeSessions': activeSessions,
        'totalNotifications': totalNotifications,
        'unreadNotifications': unreadNotifications,
        'accountAgeDays': accountAgeDays,
        'profileCompletion': profileCompletion,
        'securityScore': securityScore,
        'activityBreakdown': activityBreakdown,
        'loginTrends': loginTrends,
        'twoFactorEnabled': userData['twoFactorEnabled'] ?? false,
        'biometricEnabled': userData['biometricEnabled'] ?? false,
        'emailVerified': _auth.currentUser?.emailVerified ?? false,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return _getEmptyStats();
    }
  }

  Map<String, dynamic> _getEmptyStats() {
    return {
      'totalActivities': 0,
      'totalLogins': 0,
      'activeSessions': 0,
      'totalNotifications': 0,
      'unreadNotifications': 0,
      'accountAgeDays': 0,
      'profileCompletion': 0.0,
    'securityScore': 0,
    'activityBreakdown': <String, int>{},
    'loginTrends': <String, int>{},
    'twoFactorEnabled': false,
    'biometricEnabled': false,
    'emailVerified': false,
    };
  }

  double _calculateProfileCompletion(Map<String, dynamic> userData) {
    int completedFields = 0;
    int totalFields = 5;

    if (userData['name'] != null && userData['name'].toString().isNotEmpty) completedFields++;
    if (userData['phone'] != null && userData['phone'].toString(). isNotEmpty) completedFields++;
    if (userData['bio'] != null && userData['bio'].toString(). isNotEmpty) completedFields++;
    if (userData['location'] != null && userData['location'].toString(). isNotEmpty) completedFields++;
    if (userData['photoUrl'] != null && userData['photoUrl'].toString().isNotEmpty) completedFields++;

    return completedFields / totalFields;
  }

  int _calculateSecurityScore(Map<String, dynamic> userData) {
    int score = 0;
    int maxScore = 100;

    // Email verified: 20 points
    if (_auth.currentUser?. emailVerified == true) score += 20;

    // 2FA enabled: 30 points
    if (userData['twoFactorEnabled'] == true) score += 30;

    // Biometric enabled: 20 points
    if (userData['biometricEnabled'] == true) score += 20;

    // Login alerts enabled: 15 points
    if (userData['loginAlertsEnabled'] == true) score += 15;

    // Profile complete: 15 points
    if (_calculateProfileCompletion(userData) >= 1.0) score += 15;

    return score. clamp(0, maxScore);
  }

  Future<Map<String, int>> _getActivityBreakdown(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          .get();

      Map<String, int> breakdown = {};
      for (final doc in snapshot.docs) {
        final type = doc. data()['type'] as String?  ?? 'other';
        breakdown[type] = (breakdown[type] ??  0) + 1;
      }
      return breakdown;
    } catch (e) {
      print('Error getting activity breakdown: $e');
      return {};
    }
  }

  Future<Map<String, int>> _getLoginTrends(String userId) async {
    try {
      final sevenDaysAgo = DateTime.now(). subtract(const Duration(days: 7));

      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          . collection('login_history')
          .where('loginAt', isGreaterThan: Timestamp. fromDate(sevenDaysAgo))
          .get();

      Map<String, int> trends = {};
      for (final doc in snapshot.docs) {
        final loginAt = doc.data()['loginAt'] as Timestamp?;
        if (loginAt != null) {
          final dayKey = '${loginAt.toDate().month}/${loginAt. toDate().day}';
          trends[dayKey] = (trends[dayKey] ?? 0) + 1;
        }
      }
      return trends;
    } catch (e) {
      print('Error getting login trends: $e');
      return {};
    }
  }

  /// Get quick stats for dashboard widgets
  Future<Map<String, int>> getQuickStats() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        return {'activities': 0, 'logins': 0, 'sessions': 0};
      }

      final activitiesSnapshot = await _firestore
          .collection('activities')
          . where('userId', isEqualTo: userId)
          .get();

      final loginsSnapshot = await _firestore
          . collection('users')
          .doc(userId)
          .collection('login_history')
          .get();

      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('sessions')
          . where('isActive', isEqualTo: true)
          .get();

      return {
        'activities': activitiesSnapshot. docs.length,
        'logins': loginsSnapshot.docs.length,
        'sessions': sessionsSnapshot.docs.length,
      };
    } catch (e) {
      print('Error getting quick stats: $e');
      return {'activities': 0, 'logins': 0, 'sessions': 0};
    }
  }
}