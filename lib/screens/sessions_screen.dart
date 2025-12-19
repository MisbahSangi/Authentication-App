import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/session_service.dart';
import '../services/activity_service.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  final _sessionService = SessionService();
  final _activityService = ActivityService();
  List<Map<String, dynamic>> _sessions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSessions();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final sessions = await _sessionService.getActiveSessions();
      setState(() {
        _sessions = sessions;
      });
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _revokeSession(String sessionId, bool isCurrent) async {
    final l10n = AppLocalizations.of(context)!;

    if (isCurrent) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.cannotRevokeCurrentSession),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revokeSession),
        content: Text(l10n.revokeSessionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.revoke),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _sessionService.revokeSession(sessionId);
      if (success) {
        await _activityService.logActivity(
          type: 'session_revoked',
          description: 'Revoked a session from another device',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.sessionRevoked),
              backgroundColor: Colors.green,
            ),
          );
          _loadSessions();
        }
      }
    }
  }

  Future<void> _revokeAllOtherSessions() async {
    final l10n = AppLocalizations.of(context)! ;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.revokeAllSessions),
        content: Text(l10n.revokeAllSessionsConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors. white,
            ),
            child: Text(l10n.revokeAll),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _sessionService.revokeAllOtherSessions();
      if (success) {
        await _activityService.logActivity(
          type: 'all_sessions_revoked',
          description: 'Revoked all other sessions',
        );

        if (mounted) {
          ScaffoldMessenger.of(context). showSnackBar(
            SnackBar(
              content: Text(l10n.allSessionsRevoked),
              backgroundColor: Colors.green,
            ),
          );
          _loadSessions();
        }
      }
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'Unknown';
    }

    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference. inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  IconData _getDeviceIcon(String?  platform) {
    switch (platform?. toLowerCase()) {
      case 'web':
        return Icons.language;
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.laptop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.devices;
    }
  }

  Color _getDeviceColor(String?  platform) {
    switch (platform?.toLowerCase()) {
      case 'web':
        return Colors. blue;
      case 'android':
        return Colors.green;
      case 'ios':
        return Colors.grey;
      case 'windows':
        return Colors.lightBlue;
      case 'macos':
        return Colors. blueGrey;
      case 'linux':
        return Colors.orange;
      default:
        return Colors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.activeSessions),
        backgroundColor: isDark ? Colors.grey. shade800 : Colors.blue. shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSessions,
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
            : Column(
                children: [
                  // Info Card
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      color: isDark ? Colors.blue.shade900. withValues(alpha:0.3) : Colors.blue.shade50,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                l10n. sessionsInfo,
                                style: TextStyle(
                                  color: isDark ? Colors.blue. shade200 : Colors.blue.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Session Count
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_sessions.length} ${l10n.activeSessionsCount}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (_sessions.length > 1)
                          TextButton. icon(
                            onPressed: _revokeAllOtherSessions,
                            icon: Icon(Icons.logout, color: Colors.red. shade700, size: 18),
                            label: Text(
                              l10n.revokeAllOther,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Sessions List
                  Expanded(
                    child: _sessions.isEmpty
                        ? _buildEmptyState(isDark, l10n)
                        : RefreshIndicator(
                            onRefresh: _loadSessions,
                            child: ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: _sessions.length,
                              itemBuilder: (context, index) {
                                final session = _sessions[index];
                                return _buildSessionCard(session, isDark, l10n);
                              },
                            ),
                          ),
                  ),
                ],
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
            Icons. devices,
            size: 80,
            color: isDark ?  Colors.grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.noActiveSessions,
            style: TextStyle(
              fontSize: 18,
              color: isDark ? Colors.grey. shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session, bool isDark, AppLocalizations l10n) {
    final isCurrent = session['isCurrent'] == true;
    final platform = session['platform'] as String?;
    final deviceType = session['deviceType'] as String?  ?? 'Unknown Device';
    final lastActive = session['lastActiveAt'];
    final sessionId = session['id'] as String;

    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isCurrent
            ? BorderSide(color: Colors.green.shade400, width: 2)
            : BorderSide. none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Device Icon
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _getDeviceColor(platform). withValues(alpha:0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getDeviceIcon(platform),
                color: _getDeviceColor(platform),
                size: 28,
              ),
            ),
            const SizedBox(width: 16),

            // Session Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          deviceType,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                      if (isCurrent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.currentSession,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors. green.shade700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    platform ??  'Unknown Platform',
                    style: TextStyle(
                      color: isDark ? Colors.grey. shade400 : Colors.grey. shade600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${l10n.lastActive}: ${_formatDate(lastActive)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Revoke Button
            if (!isCurrent)
              IconButton(
                onPressed: () => _revokeSession(sessionId, isCurrent),
                icon: Icon(
                  Icons.logout,
                  color: Colors. red.shade400,
                ),
                tooltip: l10n. revokeSession,
              ),
          ],
        ),
      ),
    );
  }
}