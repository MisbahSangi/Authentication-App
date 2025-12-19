import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';
import '../services/biometric_service.dart';
import '../services/two_factor_service.dart';
import '../services/cloudinary_service.dart';
import '../services/share_service.dart';
import 'change_password_screen.dart';
import 'update_email_screen.dart';
import 'activity_log_screen.dart';
import 'delete_account_screen.dart';
import 'two_factor_setup_screen.dart';
import 'language_screen.dart';
import 'profile_screen.dart';
import 'sessions_screen.dart';
import 'help_support_screen.dart';
import 'notification_preferences_screen.dart';
import 'statistics_screen.dart';
import 'theme_color_screen.dart';
import 'default_avatars_screen.dart';
import 'export_data_screen.dart';
import 'privacy_controls_screen.dart';
import 'email_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _biometricService = BiometricService();
  final _twoFactorService = TwoFactorService();
  final _cloudinaryService = CloudinaryService();
  final _shareService = ShareService();
  final _firestore = FirebaseFirestore.instance;

  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  String?  _profileImageUrl;
  String _userName = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?. uid;
      if (userId != null) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          setState(() {
            _profileImageUrl = doc.data()? ['photoUrl'];
            _userName = doc.data()?['name'] ??  '';
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
    }
  }

  Future<void> _loadSettings() async {
    final available = await _biometricService. isBiometricAvailable();
    final biometricEnabled = await _biometricService.isBiometricEnabled();
    final twoFactorEnabled = await _twoFactorService.is2FAEnabled();

    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = biometricEnabled;
      _twoFactorEnabled = twoFactorEnabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (value) {
      // First authenticate with biometric
      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to enable biometric login',
      );

      if (authenticated) {
        // Get current user email
        final user = FirebaseAuth.instance.currentUser;
        if (user?. email == null) {
          _showSnackBar('Cannot enable biometric: No email found');
          return;
        }

        // Ask user to enter password to save for biometric
        final password = await _showPasswordDialog();

        if (password != null && password.isNotEmpty) {
          // Save credentials for biometric login
          await _biometricService.saveCredentials(user! .email!, password);
          await _biometricService.enableBiometric();

          setState(() {
            _biometricEnabled = true;
          });
          _showSnackBar('Biometric login enabled');
          print('🔒 Biometric enabled with credentials saved');
        } else {
          _showSnackBar('Password required to enable biometric login');
        }
      }
    } else {
      await _biometricService.disableBiometric();
      setState(() {
        _biometricEnabled = false;
      });
      _showSnackBar('Biometric login disabled');
    }
  }

// 🆕 Add this new method to show password dialog
  Future<String?> _showPasswordDialog() async {
    final passwordController = TextEditingController();
    final l10n = AppLocalizations.of(context)! ;

    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool obscurePassword = true;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Confirm Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Enter your password to enable biometric login.  This will be securely saved for future logins.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    autofocus: true,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword ?  Icons.visibility_off : Icons. visibility,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: Text(l10n.cancel),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, passwordController. text);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggle2FA(bool value) async {
    if (value) {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TwoFactorSetupScreen()),
      );
      if (result == true) {
        setState(() {
          _twoFactorEnabled = true;
        });
        _showSnackBar('Two-Factor Authentication enabled');
      }
    } else {
      final l10n = AppLocalizations.of(context)!;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Disable 2FA'),
          content: const Text(
            'Are you sure you want to disable Two-Factor Authentication?  This will make your account less secure.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator. pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Disable'),
            ),
          ],
        ),
      );

      if (confirm == true) {
        await _twoFactorService.disable2FA();
        setState(() {
          _twoFactorEnabled = false;
        });
        _showSnackBar('Two-Factor Authentication disabled');
      }
    }
  }

  void _shareApp() async {
    final box = context.findRenderObject() as RenderBox? ;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;
    await _shareService.shareApp(sharePositionOrigin: sharePositionOrigin);
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final user = FirebaseAuth.instance.currentUser;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
        appBar: AppBar(
          title: Text(l10n. settings),
          backgroundColor: isDark ? Colors.grey. shade800 : themeProvider.primaryColor,
          foregroundColor: Colors.white,
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
            child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                // PROFILE HEADER
                _buildProfileHeader(user, isDark, l10n, themeProvider),
            const SizedBox(height: 24),

            // ==================== ACCOUNT SECTION ====================
            _buildSectionHeader(l10n.account, isDark),
            _buildSettingsCard(
              isDark: isDark,
              children: [
                _buildSettingsTile(
                  icon: Icons.email_outlined,
                  title: l10n.email,
                  subtitle: user?.email ?? 'Not set',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const UpdateEmailScreen()));
                  },
                  isDark: isDark,
                  themeProvider: themeProvider,
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  icon: Icons.lock_outlined,
                  title: l10n.changePassword,
                  subtitle: 'Update your password',
                  onTap: () {
                    Navigator. push(context, MaterialPageRoute(builder: (_) => const ChangePasswordScreen()));
                  },
                  isDark: isDark,
                  themeProvider: themeProvider,
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  icon: Icons.face,
                  title: 'Default Avatars',
                  subtitle: 'Choose from preset avatars',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DefaultAvatarsScreen())). then((_) => _loadUserData());
                  },
                  isDark: isDark,
                  themeProvider: themeProvider,
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  icon: Icons.history,
                  title: l10n.activityLog,
                  subtitle: 'View your login history',
                  onTap: () {
                    Navigator. push(context, MaterialPageRoute(builder: (_) => const ActivityLogScreen()));
                  },
                  isDark: isDark,
                  themeProvider: themeProvider,
                ),
                _buildDivider(isDark),
                _buildSettingsTile(
                  icon: Icons. bar_chart,
                  title: l10n.accountStatistics,
                  subtitle: 'View your account stats',
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()));
                  },
                  isDark: isDark,
                  themeProvider: themeProvider,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ==================== SECURITY SECTION ====================
            _buildSectionHeader(l10n. security, isDark),
            _buildSettingsCard(
              isDark: isDark,
              children: [
              _buildSwitchTile(
              icon: Icons.security,
              title: l10n.twoFactorAuth,
              subtitle: _twoFactorEnabled ? 'Enabled' : 'Add extra security',
              value: _twoFactorEnabled,
              onChanged: _toggle2FA,
              isDark: isDark,
              themeProvider: themeProvider,
            ),
            if (_biometricAvailable) ...[
        _buildDivider(isDark),
    _buildSwitchTile(
    icon: Icons. fingerprint,
    title: l10n.biometricLogin,
    subtitle: 'Use fingerprint or face to login',
    value: _biometricEnabled,
    onChanged: _toggleBiometric,
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    ],
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.devices,
    title: l10n.activeSessions,
    subtitle: 'Manage your active sessions',
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const SessionsScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    ],
    ),
    const SizedBox(height: 24),

    // ==================== PREFERENCES SECTION ====================
    _buildSectionHeader(l10n. preferences, isDark),
    _buildSettingsCard(
    isDark: isDark,
    children: [
    _buildSettingsTile(
    icon: Icons.palette_outlined,
    title: l10n.themeColor,
    subtitle: themeProvider.currentColorName,
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ThemeColorScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    trailing: Container(
    width: 24,
    height: 24,
    decoration: BoxDecoration(
    color: themeProvider.primaryColor,
    shape: BoxShape. circle,
    border: Border.all(color: Colors.white, width: 2),
    boxShadow: [
    BoxShadow(
    color: themeProvider.primaryColor.withValues(alpha:0.4),
    blurRadius: 4,
    ),
    ],
    ),
    ),
    ),
    _buildDivider(isDark),
    _buildSwitchTile(
    icon: isDark ? Icons.dark_mode : Icons.light_mode,
    title: l10n.darkMode,
    subtitle: 'Toggle dark/light theme',
    value: isDark,
    onChanged: (value) => themeProvider.setDarkMode(value),
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons. notifications_outlined,
    title: l10n.notifications,
    subtitle: 'Manage notification preferences',
    onTap: () {
    Navigator. push(context, MaterialPageRoute(builder: (_) => const NotificationPreferencesScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.email_outlined,
    title: 'Email Settings',
    subtitle: 'Manage email notifications',
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const EmailSettingsScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.language,
    title: l10n.language,
    subtitle: languageProvider.getCurrentLanguageName(),
    onTap: () {
    Navigator. push(context, MaterialPageRoute(builder: (_) => const LanguageScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    ],
    ),
    const SizedBox(height: 24),

    // ==================== DATA & PRIVACY SECTION ====================
    _buildSectionHeader(l10n.data, isDark),
    _buildSettingsCard(
    isDark: isDark,
    children: [
    _buildSettingsTile(
    icon: Icons.download_outlined,
    title: l10n.exportData,
    subtitle: 'Download your account data',
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExportDataScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.privacy_tip_outlined,
    title: 'Privacy Controls',
    subtitle: 'Manage your data privacy',
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyControlsScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.delete_outline,
    title: l10n.deleteAccount,
    subtitle: 'Permanently delete your account',
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const DeleteAccountScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    isDestructive: true,
    ),
    ],
    ),
    const SizedBox(height: 24),

    // ==================== ABOUT SECTION ====================
    _buildSectionHeader(l10n. about, isDark),
    _buildSettingsCard(
    isDark: isDark,
    children: [
    _buildSettingsTile(
    icon: Icons.info_outline,
    title: l10n.appVersion,
    subtitle: '1.0.0',
    onTap: () {},
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.share_outlined,
    title: l10n.shareApp,
    subtitle: 'Share AuthApp with friends',
    onTap: _shareApp,
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons. description_outlined,
    title: l10n.termsOfService,
    subtitle: 'Read our terms',
    onTap: () {},
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.privacy_tip_outlined,
    title: l10n.privacyPolicy,
    subtitle: 'Read our privacy policy',
    onTap: () {},
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    _buildDivider(isDark),
    _buildSettingsTile(
    icon: Icons.help_outline,
    title: l10n.helpSupport,
    subtitle: 'FAQs, contact support',
    onTap: () {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const HelpSupportScreen()));
    },
    isDark: isDark,
    themeProvider: themeProvider,
    ),
    ],
    ),
    const SizedBox(height: 32),
    ],
    ),
    ),
    );
  }

  Widget _buildProfileHeader(User?  user, bool isDark, AppLocalizations l10n, ThemeProvider themeProvider) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [Colors.grey.shade800, Colors.grey.shade700]
              : [themeProvider.primaryColor, themeProvider.primaryColor.withValues(alpha:0.8)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadUserData());
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.white,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_cloudinaryService.getOptimizedUrl(_profileImageUrl!, size: 200))
                      : null,
                  child: _profileImageUrl == null
                      ? Text(
                    _userName.isNotEmpty
                        ? _userName[0].toUpperCase()
                        : (user?.email?. isNotEmpty == true)
                        ? user! .email![0].toUpperCase()
                        : 'U',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: themeProvider.primaryColor,
                    ),
                  )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.grey.shade700 : themeProvider.primaryColor,
                        width: 2,
                      ),
                    ),
                    child: Icon(Icons.camera_alt, size: 16, color: themeProvider.primaryColor),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName.isNotEmpty ?  _userName : (user?.displayName ??  l10n.profile),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? '',
                  style: TextStyle(fontSize: 14, color: Colors.white.withValues(alpha:0.9)),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())).then((_) => _loadUserData());
                  },
                  child: Row(
                    children: [
                      Text(
                        l10n.viewProfile,
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white. withValues(alpha:0.9)),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Colors. white.withValues(alpha:0.9)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
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

  Widget _buildSettingsCard({required bool isDark, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ?  Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required ThemeProvider themeProvider,
    bool isDestructive = false,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : (isDark ? themeProvider.primaryColor. withValues(alpha:0.8) : themeProvider.primaryColor),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black87),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isDark ? Colors.grey. shade400 : Colors.grey. shade600),
      ),
      trailing: trailing ??  Icon(Icons.chevron_right, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required ThemeProvider themeProvider,
  }) {
    return ListTile(
      leading: Icon(icon, color: isDark ? themeProvider.primaryColor. withValues(alpha:0.8) : themeProvider.primaryColor),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(subtitle, style: TextStyle(color: isDark ?  Colors.grey.shade400 : Colors.grey.shade600)),
      trailing: Switch(value: value, onChanged: onChanged, activeThumbColor: themeProvider.primaryColor),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(height: 1, indent: 56, color: isDark ? Colors. grey.shade700 : Colors.grey.shade200);
  }
}