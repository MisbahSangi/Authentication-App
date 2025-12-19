import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/login_alert_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final _loginAlertService = LoginAlertService();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth. instance;

  bool _isLoading = true;

  // Notification toggles
  bool _pushNotificationsEnabled = true;
  bool _emailNotificationsEnabled = true;
  bool _loginAlertsEnabled = true;
  bool _securityAlertsEnabled = true;
  bool _accountUpdatesEnabled = true;
  bool _promotionalEnabled = false;
  bool _newsUpdatesEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // Load from SharedPreferences
      _pushNotificationsEnabled = prefs.getBool('push_notifications') ?? true;
      _emailNotificationsEnabled = prefs. getBool('email_notifications') ?? true;
      _loginAlertsEnabled = await _loginAlertService.isLoginAlertsEnabled();
      _securityAlertsEnabled = prefs.getBool('security_alerts') ??  true;
      _accountUpdatesEnabled = prefs.getBool('account_updates') ?? true;
      _promotionalEnabled = prefs.getBool('promotional') ?? false;
      _newsUpdatesEnabled = prefs.getBool('news_updates') ?? true;

      // Also try to load from Firestore for sync
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('users'). doc(userId).get();
        if (doc.exists) {
          final data = doc.data();
          if (data != null) {
            _pushNotificationsEnabled = data['pushNotificationsEnabled'] ?? _pushNotificationsEnabled;
            _emailNotificationsEnabled = data['emailNotificationsEnabled'] ?? _emailNotificationsEnabled;
            _loginAlertsEnabled = data['loginAlertsEnabled'] ?? _loginAlertsEnabled;
            _securityAlertsEnabled = data['securityAlertsEnabled'] ?? _securityAlertsEnabled;
            _accountUpdatesEnabled = data['accountUpdatesEnabled'] ?? _accountUpdatesEnabled;
            _promotionalEnabled = data['promotionalEnabled'] ?? _promotionalEnabled;
            _newsUpdatesEnabled = data['newsUpdatesEnabled'] ?? _newsUpdatesEnabled;
          }
        }
      }
    } catch (e) {
      print('Error loading preferences: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);

      // Also save to Firestore
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        String firestoreKey = _getFirestoreKey(key);
        await _firestore.collection('users').doc(userId).update({
          firestoreKey: value,
        });
      }

      _showSnackBar('Preference updated');
    } catch (e) {
      print('Error saving preference: $e');
      _showSnackBar('Failed to update preference');
    }
  }

  String _getFirestoreKey(String key) {
    switch (key) {
      case 'push_notifications':
        return 'pushNotificationsEnabled';
      case 'email_notifications':
        return 'emailNotificationsEnabled';
      case 'login_alerts':
        return 'loginAlertsEnabled';
      case 'security_alerts':
        return 'securityAlertsEnabled';
      case 'account_updates':
        return 'accountUpdatesEnabled';
      case 'promotional':
        return 'promotionalEnabled';
      case 'news_updates':
        return 'newsUpdatesEnabled';
      default:
        return key;
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider. isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n. notificationPreferences),
        backgroundColor: isDark ? Colors.grey. shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey. shade900, Colors. grey.shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: _isLoading
            ?  const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    _buildInfoCard(isDark, l10n),
                    const SizedBox(height: 24),

                    // General Notifications
                    _buildSectionHeader(l10n.generalNotifications, isDark),
                    const SizedBox(height: 8),
                    _buildNotificationCard(
                      isDark: isDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_active,
                          title: l10n. pushNotifications,
                          subtitle: l10n.pushNotificationsDesc,
                          value: _pushNotificationsEnabled,
                          onChanged: (value) async {
                            setState(() => _pushNotificationsEnabled = value);
                            await _savePreference('push_notifications', value);
                          },
                          isDark: isDark,
                          iconColor: Colors.blue,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          icon: Icons.email_outlined,
                          title: l10n.emailNotifications,
                          subtitle: l10n.emailNotificationsDesc,
                          value: _emailNotificationsEnabled,
                          onChanged: (value) async {
                            setState(() => _emailNotificationsEnabled = value);
                            await _savePreference('email_notifications', value);
                          },
                          isDark: isDark,
                          iconColor: Colors.orange,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Security Notifications
                    _buildSectionHeader(l10n.securityNotifications, isDark),
                    const SizedBox(height: 8),
                    _buildNotificationCard(
                      isDark: isDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.login,
                          title: l10n.loginAlerts,
                          subtitle: l10n.loginAlertsDesc,
                          value: _loginAlertsEnabled,
                          onChanged: (value) async {
                            setState(() => _loginAlertsEnabled = value);
                            await _loginAlertService.setLoginAlertsEnabled(value);
                          },
                          isDark: isDark,
                          iconColor: Colors.green,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          icon: Icons. security,
                          title: l10n.securityAlerts,
                          subtitle: l10n.securityAlertsDesc,
                          value: _securityAlertsEnabled,
                          onChanged: (value) async {
                            setState(() => _securityAlertsEnabled = value);
                            await _savePreference('security_alerts', value);
                          },
                          isDark: isDark,
                          iconColor: Colors. red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Account Notifications
                    _buildSectionHeader(l10n.accountNotifications, isDark),
                    const SizedBox(height: 8),
                    _buildNotificationCard(
                      isDark: isDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons. person_outline,
                          title: l10n.accountUpdates,
                          subtitle: l10n.accountUpdatesDesc,
                          value: _accountUpdatesEnabled,
                          onChanged: (value) async {
                            setState(() => _accountUpdatesEnabled = value);
                            await _savePreference('account_updates', value);
                          },
                          isDark: isDark,
                          iconColor: Colors.purple,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Marketing Notifications
                    _buildSectionHeader(l10n. marketingNotifications, isDark),
                    const SizedBox(height: 8),
                    _buildNotificationCard(
                      isDark: isDark,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.local_offer_outlined,
                          title: l10n.promotionalOffers,
                          subtitle: l10n.promotionalOffersDesc,
                          value: _promotionalEnabled,
                          onChanged: (value) async {
                            setState(() => _promotionalEnabled = value);
                            await _savePreference('promotional', value);
                          },
                          isDark: isDark,
                          iconColor: Colors.pink,
                        ),
                        _buildDivider(isDark),
                        _buildSwitchTile(
                          icon: Icons. newspaper_outlined,
                          title: l10n.newsUpdates,
                          subtitle: l10n. newsUpdatesDesc,
                          value: _newsUpdatesEnabled,
                          onChanged: (value) async {
                            setState(() => _newsUpdatesEnabled = value);
                            await _savePreference('news_updates', value);
                          },
                          isDark: isDark,
                          iconColor: Colors.teal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ? Colors.blue.shade900. withValues(alpha:0.3) : Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      child: Padding(
        padding: const EdgeInsets. all(16),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.notificationPreferencesInfo,
                style: TextStyle(
                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNotificationCard({required bool isDark, required List<Widget> children}) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Column(children: children),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color iconColor,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor. withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 24),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight. w500,
          color: isDark ? Colors. white : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: isDark ? Colors.grey. shade400 : Colors.grey.shade600,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors. blue.shade700,
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      indent: 72,
      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
    );
  }
}