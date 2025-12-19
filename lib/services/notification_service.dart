import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

// THIS MUST BE A TOP-LEVEL FUNCTION (outside any class)
// Firebase requires this for background message handling
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.notification?. title}');
  // Note: You cannot access instance variables here
  // If you need to save to Firestore, initialize Firebase first:
  // await Firebase.initializeApp();
}

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final FirebaseFirestore _firestore = FirebaseFirestore. instance;
  final FirebaseAuth _auth = FirebaseAuth. instance;

  // Initialize notifications
  Future<void> initialize() async {
    // Skip initialization on web for unsupported features
    await _requestPermission();

    if (! kIsWeb) {
      await _initializeLocalNotifications();
    }

    await _getFCMToken();

    // Set up message handlers
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

    // Handle notification that opened the app from terminated state
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage);
    }
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      print('Notification permission: ${settings.authorizationStatus}');
    } catch (e) {
      print('Error requesting notification permission: $e');
    }
  }

  Future<void> _initializeLocalNotifications() async {
    // Skip on web - flutter_local_notifications doesn't support web
    if (kIsWeb) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        print('Notification tapped: ${response. payload}');
        // Handle notification tap here
      },
    );

    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'default_channel',
      'Default Notifications',
      description: 'Default notification channel',
      importance: Importance.high,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?. createNotificationChannel(androidChannel);
  }

  Future<String?> _getFCMToken() async {
    try {
      String? token;

      if (kIsWeb) {
        // Web requires VAPID key
        // You need to generate this from Firebase Console -> Project Settings -> Cloud Messaging -> Web Push certificates
        // Uncomment and add your VAPID key:
        // token = await _messaging.getToken(vapidKey: 'YOUR_VAPID_KEY_HERE');
        print('FCM on web requires VAPID key configuration');
        return null;
      } else {
        token = await _messaging. getToken();
      }

      print('FCM Token: $token');

      final userId = _auth.currentUser?.uid;
      if (userId != null && token != null) {
        await _firestore.collection('users').doc(userId). update({
          'fcmToken': token,
          'tokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) async {
        print('FCM Token refreshed: $newToken');
        final userId = _auth. currentUser?.uid;
        if (userId != null) {
          await _firestore.collection('users'). doc(userId).update({
            'fcmToken': newToken,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          });
        }
      });

      return token;
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?. title}');

    // Show local notification (not on web)
    if (!kIsWeb) {
      _showLocalNotification(
        title: message.notification?. title ?? 'Notification',
        body: message.notification?. body ?? '',
        payload: message.data. toString(),
      );
    }

    // Save notification to Firestore
    _saveNotification(message);
  }

  void _handleNotificationTap(RemoteMessage message) {
    print('Notification tapped: ${message.notification?.title}');
    // Navigate to specific screen based on message data
    // You can use a navigation service or callback here
    final data = message.data;
    if (data.containsKey('screen')) {
      // Handle navigation based on data['screen']
      print('Should navigate to: ${data['screen']}');
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    // Skip on web
    if (kIsWeb) return;

    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Default Notifications',
      channelDescription: 'Default notification channel',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now(). millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  Future<void> _saveNotification(RemoteMessage message) async {
    try {
      final userId = _auth. currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          . doc(userId)
          .collection('notifications')
          .add({
        'title': message.notification?. title ?? 'Notification',
        'body': message.notification?.body ?? '',
        'data': message.data,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving notification: $e');
    }
  }

  /// Get notifications stream for current user
  Stream<QuerySnapshot> getNotifications() {
    final userId = _auth. currentUser?.uid;
    if (userId == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('users')
        . doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }

  /// Mark a single notification as read
  Future<void> markAsRead(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          . doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /// Mark all notifications as read
  Future<void> markAllAsRead() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final batch = _firestore. batch();
      final notifications = await _firestore
          .collection('users')
          . doc(userId)
          .collection('notifications')
          .where('read', isEqualTo: false)
          .get();

      for (var doc in notifications.docs) {
        batch.update(doc. reference, {'read': true});
      }

      await batch.commit();
    } catch (e) {
      print('Error marking all notifications as read: $e');
    }
  }

  /// Delete a notification
  Future<void> deleteNotification(String notificationId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      await _firestore
          .collection('users')
          . doc(userId)
          .collection('notifications')
          . doc(notificationId)
          .delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  /// Delete all notifications
  Future<void> deleteAllNotifications() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId == null) return;

      final batch = _firestore.batch();
      final notifications = await _firestore
          . collection('users')
          .doc(userId)
          .collection('notifications')
          .get();

      for (var doc in notifications.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('Error deleting all notifications: $e');
    }
  }

  /// Send a test notification (for debugging)
  Future<void> sendTestNotification() async {
    if (kIsWeb) {
      print('Test notifications not supported on web');
      return;
    }

    await _showLocalNotification(
      title: 'Test Notification',
      body: 'This is a test notification from AuthApp! ',
    );
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging. unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}