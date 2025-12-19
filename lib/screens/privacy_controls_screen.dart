import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/activity_service.dart';

class PrivacyControlsScreen extends StatefulWidget {
  const PrivacyControlsScreen({super.key});

  @override
  State<PrivacyControlsScreen> createState() => _PrivacyControlsScreenState();
}

class _PrivacyControlsScreenState extends State<PrivacyControlsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth. instance;
  final _activityService = ActivityService();

  bool _isLoading = true;

  bool _profileVisibility = true;
  bool _activityTracking = true;
  bool _loginTracking = true;
  bool _analyticsEnabled = true;
  bool _personalizedAds = false;
  bool _dataSharing = false;
  bool _locationTracking = false;

  @override
  void initState() {
    super. initState();
    _loadPrivacySettings();
  }

  Future<void> _loadPrivacySettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _profileVisibility = prefs.getBool('privacy_profile_visibility') ?? true;
      _activityTracking = prefs.getBool('privacy_activity_tracking') ?? true;
      _loginTracking = prefs.getBool('privacy_login_tracking') ?? true;
      _analyticsEnabled = prefs.getBool('privacy_analytics') ?? true;
      _personalizedAds = prefs.getBool('privacy_personalized_ads') ?? false;
      _dataSharing = prefs. getBool('privacy_data_sharing') ??  false;
      _locationTracking = prefs.getBool('privacy_location_tracking') ?? false;
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePrivacySetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs. setBool('privacy_$key', value);
    ScaffoldMessenger. of(context).showSnackBar(
      const SnackBar(content: Text('Setting updated'), duration: Duration(seconds: 1)),
    );
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text('This will delete all your activity logs, login history, and sessions.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = _auth.currentUser?. uid;
      if (userId == null) return;

      final activitiesSnapshot = await _firestore. collection('activities').where('userId', isEqualTo: userId).get();
      for (final doc in activitiesSnapshot.docs) await doc.reference.delete();

      final loginSnapshot = await _firestore.collection('users'). doc(userId).collection('login_history').get();
      for (final doc in loginSnapshot.docs) await doc.reference.delete();

      final sessionsSnapshot = await _firestore. collection('users'). doc(userId).collection('sessions').get();
      for (final doc in sessionsSnapshot. docs) await doc. reference.delete();

      ScaffoldMessenger. of(context).showSnackBar(
        const SnackBar(content: Text('All data cleared'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider. isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Controls'),
        backgroundColor: isDark ? Colors.grey. shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ?  [Colors.grey.shade900, Colors.grey. shade800] : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: _isLoading
            ?  const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildInfoCard(isDark),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Profile Privacy', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitch('Profile Visibility', 'Allow others to see your profile', Icons.visibility, Colors.blue, _profileVisibility, (v) async {
                      setState(() => _profileVisibility = v);
                      await _savePrivacySetting('profile_visibility', v);
                    }, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Data Collection', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitch('Activity Tracking', 'Track your app activities', Icons.history, Colors. green, _activityTracking, (v) async {
                      setState(() => _activityTracking = v);
                      await _savePrivacySetting('activity_tracking', v);
                    }, isDark),
                    _buildSwitch('Login Tracking', 'Track login history', Icons.login, Colors.orange, _loginTracking, (v) async {
                      setState(() => _loginTracking = v);
                      await _savePrivacySetting('login_tracking', v);
                    }, isDark),
                    _buildSwitch('Location Tracking', 'Track location for security', Icons.location_on, Colors.red, _locationTracking, (v) async {
                      setState(() => _locationTracking = v);
                      await _savePrivacySetting('location_tracking', v);
                    }, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Analytics & Ads', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitch('Analytics', 'Help improve the app', Icons.analytics, Colors.purple, _analyticsEnabled, (v) async {
                      setState(() => _analyticsEnabled = v);
                      await _savePrivacySetting('analytics', v);
                    }, isDark),
                    _buildSwitch('Personalized Ads', 'Show relevant ads', Icons.ads_click, Colors.pink, _personalizedAds, (v) async {
                      setState(() => _personalizedAds = v);
                      await _savePrivacySetting('personalized_ads', v);
                    }, isDark),
                    _buildSwitch('Data Sharing', 'Share with partners', Icons.share, Colors.teal, _dataSharing, (v) async {
                      setState(() => _dataSharing = v);
                      await _savePrivacySetting('data_sharing', v);
                    }, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Danger Zone', isDark),
                  Card(
                    color: isDark ? Colors.red. shade900. withValues(alpha:0.3) : Colors.red.shade50,
                    child: ListTile(
                      leading: const Icon(Icons.delete_forever, color: Colors.red),
                      title: Text('Clear All Data', style: TextStyle(color: Colors.red. shade700, fontWeight: FontWeight. bold)),
                      subtitle: const Text('Delete all activity logs and history'),
                      trailing: const Icon(Icons. chevron_right, color: Colors.red),
                      onTap: _clearAllData,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoCard(bool isDark) {
    return Card(
      color: isDark ? Colors.purple.shade900.withValues(alpha:0.3) : Colors. purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.privacy_tip, color: isDark? Colors.purple.shade300 : Colors.purple.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text('Control how your data is collected and used. ', style: TextStyle(color: isDark ? Colors.purple.shade200 : Colors.purple.shade700))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitch(String title, String subtitle, IconData icon, Color color, bool value, Function(bool) onChanged, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color. withValues(alpha:0.1), borderRadius: BorderRadius. circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight. w500, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: color),
    );
  }
}