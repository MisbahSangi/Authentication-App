import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final List<FAQItem> _faqItems = [
    FAQItem(
      question: 'How do I reset my password?',
      answer: 'Go to the login screen and tap "Forgot Password".  Enter your email address and we\'ll send you a link to reset your password.',
    ),
    FAQItem(
      question: 'How do I enable Two-Factor Authentication?',
      answer: 'Go to Settings > Security > Two-Factor Authentication.  Follow the setup wizard to scan the QR code with your authenticator app.',
    ),
    FAQItem(
      question: 'How do I change my profile picture?',
      answer: 'Go to your Profile screen and tap on the camera icon on your avatar. You can choose to take a new photo or select one from your gallery.',
    ),
    FAQItem(
      question: 'How do I change the app language?',
      answer: 'Go to Settings > Preferences > Language and select your preferred language from the list.',
    ),
    FAQItem(
      question: 'How do I delete my account?',
      answer: 'Go to Settings > Data > Delete Account. You\'ll need to enter your password and type "DELETE" to confirm.  This action is permanent.',
    ),
    FAQItem(
      question: 'How do I export my data?',
      answer: 'Go to Settings > Data > Export Data. Your data will be prepared for download and you\'ll be notified when it\'s ready.',
    ),
    FAQItem(
      question: 'How do I log out from other devices?',
      answer: 'Go to Settings > Security > Active Sessions. You can see all devices logged into your account and revoke access to any of them.',
    ),
    FAQItem(
      question: 'Is my data secure?',
      answer: 'Yes!  We use industry-standard encryption and security measures to protect your data.  We also offer Two-Factor Authentication for additional security.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n. helpSupport),
        backgroundColor: isDark ? Colors.grey.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors. grey.shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              _buildHeaderCard(isDark, l10n),
              const SizedBox(height: 24),

              // Contact Support Section
              _buildSectionHeader(l10n.contactSupport, isDark),
              const SizedBox(height: 12),
              _buildContactCard(isDark, l10n),
              const SizedBox(height: 24),

              // FAQ Section
              _buildSectionHeader(l10n.faq, isDark),
              const SizedBox(height: 12),
              _buildFAQList(isDark),
              const SizedBox(height: 24),

              // Quick Links Section
              _buildSectionHeader(l10n.quickLinks, isDark),
              const SizedBox(height: 12),
              _buildQuickLinksCard(isDark, l10n),
              const SizedBox(height: 24),

              // App Info
              _buildAppInfoCard(isDark, l10n),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ? Colors.blue.shade900. withValues(alpha:0.3) : Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? Colors.blue.shade800 : Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.support_agent,
                size: 48,
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.howCanWeHelp,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.blue.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.helpDescription,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.blue.shade200 : Colors.blue.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white : Colors. black87,
      ),
    );
  }

  Widget _buildContactCard(bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          _buildContactTile(
            icon: Icons. email_outlined,
            title: l10n.emailUs,
            subtitle: 'support@authapp.com',
            color: Colors.blue,
            isDark: isDark,
            onTap: () => _launchEmail(),
          ),
          Divider(height: 1, color: isDark ?  Colors.grey.shade700 : Colors.grey.shade200),
          _buildContactTile(
            icon: Icons.chat_outlined,
            title: l10n.liveChat,
            subtitle: l10n.availableHours,
            color: Colors. green,
            isDark: isDark,
            onTap: () => _showComingSoon(),
          ),
          Divider(height: 1, color: isDark ? Colors.grey. shade700 : Colors.grey. shade200),
          _buildContactTile(
            icon: Icons.phone_outlined,
            title: l10n.callUs,
            subtitle: '+1 (555) 123-4567',
            color: Colors.orange,
            isDark: isDark,
            onTap: () => _launchPhone(),
          ),
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha:0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors. black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildFAQList(bool isDark) {
    return Card(
      color: isDark ?  Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      child: ExpansionPanelList.radio(
        elevation: 0,
        expandedHeaderPadding: EdgeInsets.zero,
        children: _faqItems.asMap().entries.map((entry) {
          final index = entry. key;
          final item = entry.value;
          return ExpansionPanelRadio(
            value: index,
            backgroundColor: isDark ? Colors.grey. shade800 : Colors.white,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                leading: Icon(
                  Icons.help_outline,
                  color: isDark ?  Colors.blue.shade300 : Colors.blue.shade700,
                ),
                title: Text(
                  item.question,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              );
            },
            body: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  item.answer,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickLinksCard(bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ?  Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      child: Column(
        children: [
          _buildQuickLinkTile(
            icon: Icons. description_outlined,
            title: l10n.termsOfService,
            isDark: isDark,
            onTap: () => _showComingSoon(),
          ),
          Divider(height: 1, color: isDark ? Colors. grey.shade700 : Colors. grey.shade200),
          _buildQuickLinkTile(
            icon: Icons.privacy_tip_outlined,
            title: l10n.privacyPolicy,
            isDark: isDark,
            onTap: () => _showComingSoon(),
          ),
          Divider(height: 1, color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
          _buildQuickLinkTile(
            icon: Icons.feedback_outlined,
            title: l10n.sendFeedback,
            isDark: isDark,
            onTap: () => _showFeedbackDialog(),
          ),
          Divider(height: 1, color: isDark ? Colors. grey.shade700 : Colors. grey.shade200),
          _buildQuickLinkTile(
            icon: Icons.star_outline,
            title: l10n.rateApp,
            isDark: isDark,
            onTap: () => _showComingSoon(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinkTile({
    required IconData icon,
    required String title,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isDark ?  Colors.white : Colors.black87,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
      ),
      onTap: onTap,
    );
  }

  Widget _buildAppInfoCard(bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ?  Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.blue.shade700,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.security,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'AuthApp',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight. bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                color: isDark ? Colors.grey. shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '© 2025 AuthApp. All rights reserved.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchEmail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@authapp.com',
      queryParameters: {
        'subject': 'AuthApp Support Request',
      },
    );

    try {
      await launchUrl(emailUri);
    } catch (e) {
      _showError('Could not open email app');
    }
  }

  Future<void> _launchPhone() async {
    final Uri phoneUri = Uri(scheme: 'tel', path: '+923346461739');

    try {
      await launchUrl(phoneUri);
    } catch (e) {
      _showError('Could not open phone app');
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Coming soon!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showFeedbackDialog() {
    final isDark = Provider.of<ThemeProvider>(context, listen: false). isDarkMode;
    final feedbackController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? Colors.grey. shade800 : Colors.white,
        title: Text(
          l10n.sendFeedback,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
        content: TextField(
          controller: feedbackController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: l10n.feedbackHint,
            hintStyle: TextStyle(
              color: isDark ? Colors. grey.shade500 : Colors.grey.shade400,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n. feedbackSent),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.send),
          ),
        ],
      ),
    );
  }
}

class FAQItem {
  final String question;
  final String answer;

  FAQItem({required this. question, required this.answer});
}