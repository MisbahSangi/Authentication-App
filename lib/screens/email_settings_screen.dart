import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/theme_provider.dart';

class EmailSettingsScreen extends StatefulWidget {
  const EmailSettingsScreen({super. key});

  @override
  State<EmailSettingsScreen> createState() => _EmailSettingsScreenState();
}

class _EmailSettingsScreenState extends State<EmailSettingsScreen> {
  bool _isLoading = true;
  bool _securityEmails = true;
  bool _loginAlertEmails = true;
  bool _accountUpdateEmails = true;
  bool _newsletterEmails = false;
  bool _promotionalEmails = false;
  bool _weeklyDigest = true;
  String _emailFrequency = 'instant';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _securityEmails = prefs.getBool('email_security') ?? true;
      _loginAlertEmails = prefs.getBool('email_login_alerts') ?? true;
      _accountUpdateEmails = prefs. getBool('email_account_updates') ??  true;
      _newsletterEmails = prefs.getBool('email_newsletter') ?? false;
      _promotionalEmails = prefs.getBool('email_promotional') ?? false;
      _weeklyDigest = prefs. getBool('email_weekly_digest') ??  true;
      _emailFrequency = prefs.getString('email_frequency') ??  'instant';
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences. getInstance();
    if (value is bool) await prefs.setBool(key, value);
    if (value is String) await prefs.setString(key, value);
    ScaffoldMessenger. of(context).showSnackBar(
      const SnackBar(content: Text('Setting saved'), duration: Duration(seconds: 1)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Settings'),
        backgroundColor: isDark ? Colors.grey.shade800 : themeProvider.primaryColor,
        foregroundColor: Colors. white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment. topCenter,
            end: Alignment. bottomCenter,
            colors: isDark ?  [Colors.grey. shade900, Colors. grey.shade800] : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: _isLoading
            ?  const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets. all(16),
                children: [
                  _buildInfoCard(isDark),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Security Emails', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitch('Security Alerts', 'Password changes, suspicious activity', Icons.security, Colors.red, _securityEmails, (v) async {
                      setState(() => _securityEmails = v);
                      await _saveSetting('email_security', v);
                    }, isDark),
                    _buildSwitch('Login Alerts', 'New device or location logins', Icons.login, Colors.orange, _loginAlertEmails, (v) async {
                      setState(() => _loginAlertEmails = v);
                      await _saveSetting('email_login_alerts', v);
                    }, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Account Emails', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitch('Account Updates', 'Profile changes, settings updates', Icons.person, Colors.blue, _accountUpdateEmails, (v) async {
                      setState(() => _accountUpdateEmails = v);
                      await _saveSetting('email_account_updates', v);
                    }, isDark),
                    _buildSwitch('Weekly Digest', 'Summary of your account activity', Icons.calendar_today, Colors.green, _weeklyDigest, (v) async {
                      setState(() => _weeklyDigest = v);
                      await _saveSetting('email_weekly_digest', v);
                    }, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Marketing Emails', isDark),
                  _buildSettingsCard(isDark, [
                    _buildSwitch('Newsletter', 'Tips, news, and updates', Icons.newspaper, Colors.purple, _newsletterEmails, (v) async {
                      setState(() => _newsletterEmails = v);
                      await _saveSetting('email_newsletter', v);
                    }, isDark),
                    _buildSwitch('Promotional', 'Special offers and discounts', Icons.local_offer, Colors.pink, _promotionalEmails, (v) async {
                      setState(() => _promotionalEmails = v);
                      await _saveSetting('email_promotional', v);
                    }, isDark),
                  ]),
                  const SizedBox(height: 20),
                  _buildSectionTitle('Email Frequency', isDark),
                  Card(
                    color: isDark ? Colors.grey.shade800 : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          title: Text('Instant', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text('Get emails immediately', style: TextStyle(fontSize: 12, color: isDark ?  Colors.grey.shade400 : Colors. grey.shade600)),
                          value: 'instant',
                          groupValue: _emailFrequency,
                          onChanged: (v) async {
                            setState(() => _emailFrequency = v! );
                            await _saveSetting('email_frequency', v);
                          },
                          activeColor: themeProvider.primaryColor,
                        ),
                        RadioListTile<String>(
                          title: Text('Daily Digest', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text('One email per day', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          value: 'daily',
                          groupValue: _emailFrequency,
                          onChanged: (v) async {
                            setState(() => _emailFrequency = v!);
                            await _saveSetting('email_frequency', v);
                          },
                          activeColor: themeProvider.primaryColor,
                        ),
                        RadioListTile<String>(
                          title: Text('Weekly Digest', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
                          subtitle: Text('One email per week', style: TextStyle(fontSize: 12, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
                          value: 'weekly',
                          groupValue: _emailFrequency,
                          onChanged: (v) async {
                            setState(() => _emailFrequency = v! );
                            await _saveSetting('email_frequency', v);
                          },
                          activeColor: themeProvider. primaryColor,
                        ),
                      ],
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
      color: isDark ? Colors.blue.shade900.withValues(alpha:0.3) : Colors. blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.email, color: isDark ? Colors.blue. shade300 : Colors.blue.shade700),
            const SizedBox(width: 12),
            Expanded(child: Text('Choose which emails you want to receive. ', style: TextStyle(color: isDark ? Colors.blue. shade200 : Colors.blue.shade700))),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets. only(left: 4, bottom: 8),
      child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600)),
    );
  }

  Widget _buildSettingsCard(bool isDark, List<Widget> children) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: children),
    );
  }

  Widget _buildSwitch(String title, String subtitle, IconData icon, Color color, bool value, Function(bool) onChanged, bool isDark) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha:0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight. w500, color: isDark ? Colors. white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ?  Colors.grey.shade400 : Colors. grey.shade600)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: color),
    );
  }
}