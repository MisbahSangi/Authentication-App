import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:universal_html/html.dart' as html;

class ExportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Export all user data as JSON
  Future<Map<String, dynamic>> gatherUserData() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('User not logged in');
    }

    final exportData = <String, dynamic>{
      'exportDate': DateTime.now().toIso8601String(),
      'userId': userId,
    };

    // Get user profile
    try {
      final userDoc = await _firestore.collection('users'). doc(userId).get();
      if (userDoc.exists) {
        final userData = userDoc.data()!;
        userData.remove('password');
        exportData['profile'] = userData;
      }
    } catch (e) {
      exportData['profile'] = {'error': 'Could not fetch profile data'};
    }

    // Get activities
    try {
      final activitiesSnapshot = await _firestore
          . collection('activities')
          .where('userId', isEqualTo: userId)
          .get();

      exportData['activities'] = activitiesSnapshot.docs.map((doc) {
        final data = doc.data();
        if (data['timestamp'] is Timestamp) {
          data['timestamp'] = (data['timestamp'] as Timestamp). toDate(). toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      exportData['activities'] = [];
    }

    // Get login history
    try {
      final loginHistorySnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('login_history')
          .get();

      exportData['loginHistory'] = loginHistorySnapshot.docs.map((doc) {
        final data = doc.data();
        if (data['loginAt'] is Timestamp) {
          data['loginAt'] = (data['loginAt'] as Timestamp). toDate().toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      exportData['loginHistory'] = [];
    }

    // Get sessions
    try {
      final sessionsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          . collection('sessions')
          .get();

      exportData['sessions'] = sessionsSnapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['lastActiveAt'] is Timestamp) {
          data['lastActiveAt'] = (data['lastActiveAt'] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }). toList();
    } catch (e) {
      exportData['sessions'] = [];
    }

    // Get notifications
    try {
      final notificationsSnapshot = await _firestore
          .collection('notifications')
          .where('userId', isEqualTo: userId)
          .get();

      exportData['notifications'] = notificationsSnapshot.docs.map((doc) {
        final data = doc.data();
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        return data;
      }).toList();
    } catch (e) {
      exportData['notifications'] = [];
    }

    return exportData;
  }

  /// Export data as JSON file download
  Future<void> exportAsJson() async {
    final data = await gatherUserData();
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final fileName = 'authapp_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}. json';

    if (kIsWeb) {
      // Web: Use HTML download
      _downloadFileWeb(jsonString, fileName, 'application/json');
    } else {
      // Mobile/Desktop: Save to file and share
      await _saveAndShareFile(jsonString, fileName);
    }
  }

  /// Export data as CSV file download
  Future<void> exportAsCsv() async {
    final data = await gatherUserData();

    final csvBuffer = StringBuffer();

    // Profile section
    csvBuffer.writeln('=== PROFILE ===');
    csvBuffer.writeln('Field,Value');
    if (data['profile'] is Map) {
      (data['profile'] as Map).forEach((key, value) {
        final escapedValue = value.toString().replaceAll('"', '""');
        csvBuffer.writeln('$key,"$escapedValue"');
      });
    }
    csvBuffer.writeln();

    // Activities section
    csvBuffer.writeln('=== ACTIVITIES ===');
    csvBuffer.writeln('Type,Description,Timestamp');
    if (data['activities'] is List) {
      for (final activity in data['activities']) {
        final type = activity['type'] ??  '';
        final desc = (activity['description'] ?? '').toString().replaceAll('"', '""');
        final time = activity['timestamp'] ?? '';
        csvBuffer.writeln('$type,"$desc",$time');
      }
    }
    csvBuffer.writeln();

    // Login History section
    csvBuffer.writeln('=== LOGIN HISTORY ===');
    csvBuffer.writeln('Device,Platform,Login Time');
    if (data['loginHistory'] is List) {
      for (final login in data['loginHistory']) {
        final device = login['deviceName'] ?? '';
        final platform = login['platform'] ?? '';
        final time = login['loginAt'] ?? '';
        csvBuffer. writeln('$device,$platform,$time');
      }
    }
    csvBuffer.writeln();

    // Sessions section
    csvBuffer.writeln('=== SESSIONS ===');
    csvBuffer.writeln('Device,Platform,Created,Last Active,Is Active');
    if (data['sessions'] is List) {
      for (final session in data['sessions']) {
        final device = session['deviceType'] ?? '';
        final platform = session['platform'] ?? '';
        final created = session['createdAt'] ??  '';
        final lastActive = session['lastActiveAt'] ?? '';
        final isActive = session['isActive'] ?? false;
        csvBuffer.writeln('$device,$platform,$created,$lastActive,$isActive');
      }
    }

    final fileName = 'authapp_data_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv';

    if (kIsWeb) {
      // Web: Use HTML download
      _downloadFileWeb(csvBuffer.toString(), fileName, 'text/csv');
    } else {
      // Mobile/Desktop: Save to file and share
      await _saveAndShareFile(csvBuffer.toString(), fileName);
    }
  }

  /// Web: Download file using HTML
  void _downloadFileWeb(String content, String fileName, String mimeType) {
    final bytes = utf8.encode(content);
    final blob = html. Blob([bytes], mimeType);
    final url = html. Url.createObjectUrlFromBlob(blob);

    final _ = html.AnchorElement(href: url)
      .. setAttribute('download', fileName)
      ..click();

    html. Url.revokeObjectUrl(url);
  }

  /// Mobile/Desktop: Save file and share
  Future<void> _saveAndShareFile(String content, String fileName) async {
    try {
      // Get temporary directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsString(content);

      // Share file
      await Share.shareXFiles(
        [XFile(filePath)],
        subject: 'AuthApp Data Export',
        text: 'Here is your exported data from AuthApp',
      );
    } catch (e) {
      print('Error saving/sharing file: $e');
      rethrow;
    }
  }

  /// Get data summary for preview
  Future<Map<String, int>> getDataSummary() async {
    final data = await gatherUserData();

    return {
      'activities': (data['activities'] as List?)?.length ?? 0,
      'loginHistory': (data['loginHistory'] as List?)?.length ??  0,
      'sessions': (data['sessions'] as List?)?.length ?? 0,
      'notifications': (data['notifications'] as List?)?.length ?? 0,
    };
  }
}