import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/cloudinary_service.dart';
import '../services/notification_badge_service.dart';
import '../services/activity_service.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'sessions_screen.dart';
import 'activity_log_screen.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super. key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _cloudinaryService = CloudinaryService();
  final _notificationBadgeService = NotificationBadgeService();
  final _activityService = ActivityService();

  String _userName = '';
  String?  _profileImageUrl;
  bool _emailVerified = false;
  DateTime? _memberSince;
  List<Map<String, dynamic>> _recentActivities = [];
  bool _isLoadingActivities = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadRecentActivities();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid). get();
        if (doc. exists) {
          setState(() {
            _userName = doc.data()?['name'] ?? '';
            _profileImageUrl = doc.data()?['photoUrl'];
            _emailVerified = user.emailVerified;
            final createdAt = doc.data()? ['createdAt'];
            if (createdAt is Timestamp) {
              _memberSince = createdAt.toDate();
            }
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    setState(() {
      _isLoadingActivities = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Query activities collection
      final snapshot = await _firestore
          . collection('activities')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(5)
          .get();

      print('📊 Home: Found ${snapshot.docs.length} recent activities');

      final activities = snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }). toList();

      setState(() {
        _recentActivities = activities;
      });
    } catch (e) {
      print('Error loading recent activities: $e');

      // Fallback: try without orderBy if index not created
      try {
        final userId = _auth.currentUser?.uid;
        if (userId == null) return;

        final snapshot = await _firestore
            .collection('activities')
            .where('userId', isEqualTo: userId)
            .get();

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
          _recentActivities = activities. take(5).toList();
        });
      } catch (e2) {
        print('Fallback also failed: $e2');
      }
    } finally {
      setState(() {
        _isLoadingActivities = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp. toDate();
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
      return DateFormat('MMM dd'). format(date);
    }
  }

  String _getActivityTitle(String?  type) {
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
      default:
        return type?.replaceAll('_', ' ') ?? 'Activity';
    }
  }

  IconData _getActivityIcon(String? type) {
    switch (type) {
      case 'login':
        return Icons.login;
      case 'logout':
        return Icons. logout;
      case 'password_changed':
        return Icons. lock;
      case 'profile_updated':
        return Icons. person;
      case '2fa_enabled':
      case '2fa_disabled':
        return Icons.security;
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
      case 'profile_updated':
        return Colors.teal;
      case '2fa_enabled':
        return Colors.green;
      case '2fa_disabled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _logout() async {
    final l10n = AppLocalizations.of(context)!;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.logout),
        content: const Text('Are you sure you want to logout?'),
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
            child: Text(l10n. logout),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _activityService.logActivity(
          type: 'logout',
          description: 'User logged out',
        );
        await _auth.signOut();
        if (mounted) {
          Navigator. pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
          );
        }
      } catch (e) {
        print('Error logging out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final user = _auth.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.home),
        backgroundColor: isDark ? Colors.grey. shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          // Notification Bell with Badge
          StreamBuilder<int>(
            stream: _notificationBadgeService. getUnreadCountStream(),
            builder: (context, snapshot) {
              final count = snapshot.data ?? 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ). then((_) {
                _loadUserData();
                _loadRecentActivities();
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(isDark, l10n, user, themeProvider),
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
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadUserData();
            await _loadRecentActivities();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Card
                _buildWelcomeCard(isDark, l10n, user, themeProvider),
                const SizedBox(height: 20),

                // Account Info Card
                _buildAccountInfoCard(isDark, l10n, user),
                const SizedBox(height: 20),

                // Quick Actions
                _buildQuickActionsGrid(isDark, l10n, themeProvider),
                const SizedBox(height: 20),

                // Recent Activity
                _buildRecentActivitySection(isDark, l10n),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(bool isDark, AppLocalizations l10n, User? user, ThemeProvider themeProvider) {
    return Card(
      color: isDark ? Colors.grey. shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ). then((_) => _loadUserData());
              },
              child: CircleAvatar(
                radius: 35,
                backgroundColor: themeProvider.primaryColor. withValues(alpha:0.1),
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_cloudinaryService.getOptimizedUrl(_profileImageUrl!, size: 150))
                    : null,
                child: _profileImageUrl == null
                    ? Text(
                  _userName.isNotEmpty
                      ? _userName[0]. toUpperCase()
                      : (user?.email?. isNotEmpty == true ? user! .email![0].toUpperCase() : 'U'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: themeProvider.primaryColor,
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.welcome,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    _userName.isNotEmpty ?  _userName : (user?.displayName ??  'User'),
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ??  '',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator. push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ).then((_) => _loadUserData());
              },
              icon: Icon(
                Icons.edit,
                color: themeProvider.primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(bool isDark, AppLocalizations l10n, User? user) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: isDark ? Colors.blue. shade300 : Colors.blue.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  l10n. account,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.email_outlined, '${l10n.email}:', user?.email ?? '', isDark),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.calendar_today,
              'Member Since:',
              _memberSince != null ? DateFormat('MMM dd, yyyy'). format(_memberSince!) : 'N/A',
              isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              Icons.verified,
              'Email Verified:',
              _emailVerified ? 'Yes' : 'No',
              isDark,
              valueColor: _emailVerified ? Colors.green : Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: isDark ? Colors. grey.shade400 : Colors. grey.shade600),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(color: isDark ? Colors.grey. shade400 : Colors.grey. shade600),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: valueColor ??  (isDark ? Colors.white : Colors.black87),
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid(bool isDark, AppLocalizations l10n, ThemeProvider themeProvider) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildQuickActionCard(
          icon: Icons.person,
          title: l10n.profile,
          color: Colors.blue,
          isDark: isDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()))
                .then((_) => _loadUserData());
          },
        ),
        _buildQuickActionCard(
          icon: Icons.settings,
          title: l10n.settings,
          color: Colors.grey,
          isDark: isDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()))
                .then((_) {
              _loadUserData();
              _loadRecentActivities();
            });
          },
        ),
        _buildQuickActionCard(
          icon: Icons. notifications,
          title: l10n.notifications,
          color: Colors.orange,
          isDark: isDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen()));
          },
        ),
        _buildQuickActionCard(
          icon: Icons.security,
          title: l10n.security,
          color: Colors.green,
          isDark: isDark,
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen()));
          },
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Card(
      color: isDark ? Colors.grey. shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius. circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color. withValues(alpha:0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : Colors. black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(bool isDark, AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ?  Colors.white : Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ActivityLogScreen()),
                ).then((_) => _loadRecentActivities());
              },
              child: Text(
                'View All',  // 🆕 CHANGED from "View Profile"
                style: TextStyle(
                  color: isDark ?  Colors.blue.shade300 : Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: isDark ?  Colors.grey.shade800 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
          child: _isLoadingActivities
              ? const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          )
              : _recentActivities.isEmpty
              ?  Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.history,
                  size: 48,
                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'No activity yet',
                  style: TextStyle(
                    color: isDark ? Colors.grey. shade400 : Colors.grey. shade600,
                  ),
                ),
              ],
            ),
          )
              : ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
            ),
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              final type = activity['type'] as String? ;
              return ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getActivityColor(type). withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getActivityIcon(type),
                    color: _getActivityColor(type),
                    size: 20,
                  ),
                ),
                title: Text(
                  _getActivityTitle(type),
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ?  Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  activity['description'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey. shade400 : Colors.grey. shade600,
                  ),
                ),
                trailing: Text(
                  _formatDate(activity['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey. shade500 : Colors.grey.shade500,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDrawer(bool isDark, AppLocalizations l10n, User?  user, ThemeProvider themeProvider) {
    return Drawer(
      backgroundColor: isDark ? Colors.grey. shade900 : Colors.white,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [themeProvider.primaryColor, themeProvider.primaryColor. withValues(alpha:0.8)],
              ),
            ),
            padding: const EdgeInsets.all(16),  // 🆕 Added padding
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,  // 🆕 Changed to center
              children: [
                CircleAvatar(
                  radius: 30,  // 🆕 Reduced from 35 to 30
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_cloudinaryService.getOptimizedUrl(_profileImageUrl!, size: 150))
                      : null,
                  child: _profileImageUrl == null
                      ? Text(
                    _userName.isNotEmpty
                        ? _userName[0]. toUpperCase()
                        : (user?.email?.isNotEmpty == true ?  user!.email![0].toUpperCase() : 'U'),
                    style: TextStyle(
                      fontSize: 24,  // 🆕 Reduced from 28 to 24
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  )
                      : null,
                ),
                const SizedBox(height: 10),  // 🆕 Reduced from 12 to 10
                Text(
                  _userName.isNotEmpty ?  _userName : 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,  // 🆕 Reduced from 18 to 16
                    fontWeight: FontWeight. bold,
                  ),
                  maxLines: 1,  // 🆕 Added maxLines
                  overflow: TextOverflow.ellipsis,  // 🆕 Added overflow handling
                ),
                const SizedBox(height: 2),  // 🆕 Added small spacing
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    color: Colors.white. withValues(alpha:0.9),
                    fontSize: 12,  // 🆕 Reduced from 14 to 12
                  ),
                  maxLines: 1,  // 🆕 Added maxLines
                  overflow: TextOverflow. ellipsis,  // 🆕 Added overflow handling
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(l10n. home),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons. person),
            title: Text(l10n.profile),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: Text(l10n.settings),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: Text(l10n. logout, style: const TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              _logout();
            },
          ),
        ],
      ),
    );
  }
}