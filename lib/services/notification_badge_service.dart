import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationBadgeService {
  final FirebaseFirestore _firestore = FirebaseFirestore. instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get stream of unread notification count
  Stream<int> getUnreadCountStream() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value(0);
    }

    print('🔔 Badge Service: Listening for userId: $userId');

    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('read', isEqualTo: false)
        . snapshots()
        .map((snapshot) {
      print('🔔 Badge Service: Found ${snapshot.docs.length} unread notifications');
      return snapshot. docs.length;
    });
  }

  /// Get unread notification count (one-time)
  Future<int> getUnreadCount() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      return snapshot.docs.length;
    } catch (e) {
      print('Error getting unread count: $e');
      return 0;
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final snapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch. commit();
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }
}