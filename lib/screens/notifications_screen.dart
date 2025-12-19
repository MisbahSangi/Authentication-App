import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth. instance;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;
    final userId = _auth.currentUser?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notifications),
        backgroundColor: isDark ? Colors.grey.shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          // Mark all as read button
          IconButton(
            icon: const Icon(Icons.done_all),
            tooltip: 'Mark all as read',
            onPressed: () => _markAllAsRead(userId),
          ),
          // Clear all button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'clear') {
                _clearAllNotifications(userId);
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red.shade700),
                    const SizedBox(width: 8),
                    const Text('Clear All'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment. topCenter,
            end: Alignment. bottomCenter,
            colors: isDark
                ? [Colors. grey.shade900, Colors.grey.shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: userId == null
            ? _buildEmptyState(isDark, l10n)
            : StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('notifications')
              . where('userId', isEqualTo: userId)
              . orderBy('createdAt', descending: true)
              .limit(50)
              . snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState. waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error loading notifications',
                      style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              );
            }

            final notifications = snapshot.data?. docs ?? [];

            if (notifications.isEmpty) {
              return _buildEmptyState(isDark, l10n);
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final doc = notifications[index];
                final data = doc.data() as Map<String, dynamic>;
                return _buildNotificationCard(doc. id, data, isDark, l10n);
              },
            );
          },
        ),
      ),
      // ✅ REMOVED: Debug FAB removed for production
      // floatingActionButton was removed here
    );
  }

  Widget _buildEmptyState(bool isDark, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            size: 80,
            color: isDark ? Colors. grey.shade600 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No notifications',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors. white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "You're all caught up! ",
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(String docId, Map<String, dynamic> data, bool isDark, AppLocalizations l10n) {
    final title = data['title'] as String?  ?? 'Notification';
    final message = data['message'] as String? ?? '';
    final type = data['type'] as String? ?? 'info';
    final isRead = data['read'] as bool? ??  false;
    final createdAt = data['createdAt'] as Timestamp? ;

    return Dismissible(
      key: Key(docId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _deleteNotification(docId);
      },
      child: Card(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: ! isRead
              ? BorderSide(color: Colors. blue.shade400, width: 2)
              : BorderSide. none,
        ),
        child: InkWell(
          onTap: () {
            if (! isRead) {
              _markAsRead(docId);
            }
          },
          borderRadius: BorderRadius. circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type). withValues(alpha: 0.1),
                    borderRadius: BorderRadius. circular(10),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: TextStyle(
                                fontWeight: isRead ? FontWeight. normal : FontWeight.bold,
                                fontSize: 16,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          if (! isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'security':
        return Icons.security;
      case 'account':
        return Icons.person;
      case 'update':
        return Icons.system_update;
      case 'promo':
        return Icons.local_offer;
      case 'info':
      default:
        return Icons.info_outline;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'security':
        return Colors.red;
      case 'account':
        return Colors.blue;
      case 'update':
        return Colors.green;
      case 'promo':
        return Colors.orange;
      case 'info':
      default:
        return Colors.purple;
    }
  }

  String _formatDate(Timestamp?  timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
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

  Future<void> _markAsRead(String docId) async {
    try {
      await _firestore.collection('notifications').doc(docId).update({
        'read': true,
      });
    } catch (e) {
      print('Error marking as read: $e');
    }
  }

  Future<void> _markAllAsRead(String?  userId) async {
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('notifications')
          . where('userId', isEqualTo: userId)
          .where('read', isEqualTo: false)
          .get();

      final batch = _firestore. batch();
      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {'read': true});
      }
      await batch.commit();

      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          const SnackBar(
            content: Text('All notifications marked as read'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  Future<void> _deleteNotification(String docId) async {
    try {
      await _firestore. collection('notifications'). doc(docId).delete();
    } catch (e) {
      print('Error deleting notification: $e');
    }
  }

  Future<void> _clearAllNotifications(String?  userId) async {
    if (userId == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Notifications'),
        content: const Text('Are you sure you want to delete all notifications? '),
        actions: [
          TextButton(
            onPressed: () => Navigator. pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors. red,
              foregroundColor: Colors. white,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final snapshot = await _firestore
            .collection('notifications')
            . where('userId', isEqualTo: userId)
            .get();

        final batch = _firestore. batch();
        for (final doc in snapshot.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All notifications cleared'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        print('Error clearing notifications: $e');
      }
    }
  }
}