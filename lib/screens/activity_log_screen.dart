import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class ActivityLogScreen extends StatefulWidget {
  const ActivityLogScreen({super.key});

  @override
  State<ActivityLogScreen> createState() => _ActivityLogScreenState();
}

class _ActivityLogScreenState extends State<ActivityLogScreen> {
  final _firestore = FirebaseFirestore. instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      print('🔍 Loading activities for userId: $userId');

      // Query the activities collection - same as statistics_service
      final snapshot = await _firestore
          .collection('activities')
          .where('userId', isEqualTo: userId)
          . orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      print('📊 Found ${snapshot.docs.length} activities');

      final activities = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }). toList();

      setState(() {
        _activities = activities;
      });
    } catch (e) {
      print('❌ Error loading activities: $e');

      // If index error, try without orderBy
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        final snapshot = await _firestore
            .collection('activities')
            .where('userId', isEqualTo: userId)
            .get();

        print('📊 Found ${snapshot. docs.length} activities (without order)');

        final activities = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id;
          return data;
        }).toList();

        // Sort manually
        activities.sort((a, b) {
          final aTime = a['timestamp'] as Timestamp? ;
          final bTime = b['timestamp'] as Timestamp?;
          if (aTime == null || bTime == null) return 0;
          return bTime.compareTo(aTime);
        });

        setState(() {
          _activities = activities;
        });
      } catch (e2) {
        print('❌ Second attempt failed: $e2');
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return '';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference. inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(date);
    }
  }

  IconData _getActivityIcon(String?  type) {
    switch (type) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons.logout;
      case 'password_changed':
        return Icons.lock;
      case 'email_updated':
        return Icons.email;
      case 'profile_updated':
        return Icons.person;
      case '2fa_enabled':
        return Icons.security;
      case '2fa_disabled':
        return Icons.security;
      case 'account_created':
        return Icons.person_add;
      case 'session_revoked':
        return Icons.devices;
      default:
        return Icons.history;
    }
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'password_changed':
        return Colors.blue;
      case 'email_updated':
        return Colors.purple;
      case 'profile_updated':
        return Colors.teal;
      case '2fa_enabled':
        return Colors. green;
      case '2fa_disabled':
        return Colors.red;
      case 'account_created':
        return Colors.indigo;
      case 'session_revoked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getActivityTitle(String? type) {
    switch (type) {
      case 'login':
        return 'Logged In';
      case 'logout':
        return 'Logged Out';
      case 'password_changed':
        return 'Password Changed';
      case 'email_updated':
        return 'Email Updated';
      case 'profile_updated':
        return 'Profile Updated';
      case '2fa_enabled':
        return '2FA Enabled';
      case '2fa_disabled':
        return '2FA Disabled';
      case 'account_created':
        return 'Account Created';
      case 'session_revoked':
        return 'Session Revoked';
      default:
        return type?. replaceAll('_', ' '). toUpperCase() ?? 'Activity';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activityLog),
        backgroundColor: isDark ? Colors.grey. shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons. refresh),
            onPressed: _loadActivities,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _activities.isEmpty
            ? _buildEmptyState(isDark, l10n)
            : RefreshIndicator(
          onRefresh: _loadActivities,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _activities. length,
            itemBuilder: (context, index) {
              final activity = _activities[index];
              return _buildActivityCard(activity, isDark);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons. history,
            size: 80,
            color: isDark ?  Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noActivityYet,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your activity will appear here',
            style: TextStyle(
              color: isDark ? Colors.grey. shade400 : Colors.grey. shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity, bool isDark) {
    final type = activity['type'] as String? ;
    final description = activity['description'] as String?  ?? _getActivityTitle(type);
    final timestamp = activity['timestamp'];

    return Card(
      color: isDark ? Colors.grey. shade800 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets. all(10),
          decoration: BoxDecoration(
            color: _getActivityColor(type). withValues(alpha:0.1),
            borderRadius: BorderRadius. circular(10),
          ),
          child: Icon(
            _getActivityIcon(type),
            color: _getActivityColor(type),
            size: 24,
          ),
        ),
        title: Text(
          _getActivityTitle(type),
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description != _getActivityTitle(type)) ...[
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(
                  color: isDark ?  Colors.grey.shade400 : Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _formatDate(timestamp),
              style: TextStyle(
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}