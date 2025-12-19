import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/statistics_service.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final _statisticsService = StatisticsService();
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final stats = await _statisticsService.getUserStatistics();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      print('Error loading statistics: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider. isDarkMode;
    final l10n = AppLocalizations. of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.accountStatistics),
        backgroundColor: isDark ? Colors.grey.shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey. shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
          onRefresh: _loadStatistics,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSecurityScoreCard(isDark, l10n),
                const SizedBox(height: 20),
                _buildQuickStatsGrid(isDark, l10n),
                const SizedBox(height: 20),
                _buildProfileCompletionCard(isDark, l10n),
                const SizedBox(height: 20),
                _buildAccountInfoCard(isDark, l10n),
                const SizedBox(height: 20),
                _buildActivityBreakdownCard(isDark, l10n),
                const SizedBox(height: 20),
                _buildSecurityStatusCard(isDark, l10n),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityScoreCard(bool isDark, AppLocalizations l10n) {
    final score = _stats['securityScore'] ?? 0;
    Color scoreColor;
    String scoreLabel;

    if (score >= 80) {
      scoreColor = Colors.green;
      scoreLabel = l10n.excellent;
    } else if (score >= 60) {
      scoreColor = Colors. lightGreen;
      scoreLabel = l10n.good;
    } else if (score >= 40) {
      scoreColor = Colors. orange;
      scoreLabel = l10n. fair;
    } else {
      scoreColor = Colors.red;
      scoreLabel = l10n.needsImprovement;
    }

    return Card(
      color: isDark ? Colors. grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              l10n.securityScore,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors. grey.shade300 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 20),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: CircularProgressIndicator(
                    value: score / 100,
                    strokeWidth: 12,
                    backgroundColor: isDark ?  Colors.grey.shade700 : Colors. grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight. bold,
                        color: scoreColor,
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: scoreColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.securityScoreDesc,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isDark ?  Colors.grey. shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid(bool isDark, AppLocalizations l10n) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          icon: Icons.history,
          title: l10n.totalActivities,
          value: '${_stats['totalActivities'] ??  0}',
          color: Colors. blue,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.login,
          title: l10n.totalLogins,
          value: '${_stats['totalLogins'] ?? 0}',
          color: Colors.green,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons. devices,
          title: l10n. activeSessions,
          value: '${_stats['activeSessions'] ?? 0}',
          color: Colors.orange,
          isDark: isDark,
        ),
        _buildStatCard(
          icon: Icons.notifications,
          title: l10n.notifications,
          value: '${_stats['totalNotifications'] ??  0}',
          color: Colors. purple,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
    required bool isDark,
  }) {
    return Card(
      color: isDark ? Colors. grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color. withValues(alpha:0.1),
                    borderRadius: BorderRadius. circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight. bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCompletionCard(bool isDark, AppLocalizations l10n) {
    final completion = (_stats['profileCompletion'] ?? 0.0) as double;
    final percentage = (completion * 100).toInt();

    return Card(
      color: isDark ? Colors. grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.profileCompletion, // ✅ FIXED: Using l10n instead of hardcoded
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight. w600,
                    color: isDark ?  Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: percentage >= 100
                        ? Colors. green. shade100
                        : Colors.orange.shade100,
                    borderRadius: BorderRadius. circular(20),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight. bold,
                      color: percentage >= 100
                          ?  Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: completion,
                minHeight: 10,
                backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  percentage >= 100 ?  Colors.green : Colors.blue,
                ),
              ),
            ),
            if (percentage < 100) ...[
              const SizedBox(height: 12),
              Text(
                l10n.completeProfileMessage, // ✅ FIXED: Using l10n instead of hardcoded
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ?  Colors.grey.shade400 : Colors. grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAccountInfoCard(bool isDark, AppLocalizations l10n) {
    final accountAgeDays = _stats['accountAgeDays'] ?? 0;
    String accountAge;
    if (accountAgeDays < 1) {
      accountAge = l10n.today;
    } else if (accountAgeDays == 1) {
      accountAge = '1 ${l10n.day}';
    } else if (accountAgeDays < 30) {
      accountAge = '$accountAgeDays ${l10n.days}';
    } else if (accountAgeDays < 365) {
      final months = (accountAgeDays / 30). floor();
      accountAge = '$months ${months == 1 ? l10n.month : l10n.months}';
    } else {
      final years = (accountAgeDays / 365).floor();
      accountAge = '$years ${years == 1 ? l10n.year : l10n.years}';
    }

    return Card(
      color: isDark ?  Colors.grey.shade800 : Colors. white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.accountInfo,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.calendar_today,
              label: l10n. accountAge,
              value: accountAge,
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.notifications_active,
              label: l10n.unreadNotifications,
              value: '${_stats['unreadNotifications'] ??  0}',
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight. w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityBreakdownCard(bool isDark, AppLocalizations l10n) {
    final breakdown = (_stats['activityBreakdown'] ?? {}) as Map<String, dynamic>;

    if (breakdown.isEmpty) {
      return Card(
        color: isDark ? Colors. grey.shade800 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: isDark ?  Colors.grey.shade600 : Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                l10n.noActivityData,
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.activityBreakdown,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight. w600,
                color: isDark ?  Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ... breakdown.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildActivityRow(
                  type: entry.key,
                  count: entry.value as int,
                  isDark: isDark,
                  l10n: l10n,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityRow({
    required String type,
    required int count,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    final displayName = _getActivityDisplayName(type, l10n);
    final color = _getActivityColor(type);

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius. circular(3),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            displayName,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
        Text(
          '$count',
          style: TextStyle(
            fontWeight: FontWeight. w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // ✅ NEW: Localized activity display names
  String _getActivityDisplayName(String type, AppLocalizations l10n) {
    switch (type) {
      case 'login':
        return l10n.activityLogin;
      case 'logout':
        return l10n.activityLogout;
      case 'password_changed':
        return l10n.activityPasswordChanged;
      case 'profile_updated':
        return l10n.activityProfileUpdated;
      case '2fa_enabled':
        return l10n. activity2faEnabled;
      case '2fa_disabled':
        return l10n.activity2faDisabled;
      case 'account_created':
        return l10n.activityAccountCreated;
      default:
        return type. replaceAll('_', ' '). toUpperCase();
    }
  }

  Color _getActivityColor(String type) {
    switch (type) {
      case 'login':
        return Colors.green;
      case 'logout':
        return Colors.orange;
      case 'password_changed':
        return Colors. blue;
      case 'profile_updated':
        return Colors. purple;
      case '2fa_enabled':
        return Colors. teal;
      case '2fa_disabled':
        return Colors.red;
      case 'account_created':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSecurityStatusCard(bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n. securityStatus,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            _buildSecurityItem(
              icon: Icons.verified,
              title: l10n.emailVerified, // ✅ FIXED: Using l10n instead of hardcoded
              enabled: _stats['emailVerified'] ?? false,
              isDark: isDark,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons. security,
              title: l10n.twoFactorAuth,
              enabled: _stats['twoFactorEnabled'] ?? false,
              isDark: isDark,
              l10n: l10n,
            ),
            const SizedBox(height: 12),
            _buildSecurityItem(
              icon: Icons.fingerprint,
              title: l10n. biometricLogin,
              enabled: _stats['biometricEnabled'] ?? false,
              isDark: isDark,
              l10n: l10n,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityItem({
    required IconData icon,
    required String title,
    required bool enabled,
    required bool isDark,
    required AppLocalizations l10n,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: enabled ? Colors.green : (isDark ? Colors. grey.shade500 : Colors.grey.shade400),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: enabled ?  Colors.green. shade100 : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            enabled ?  l10n.enabled : l10n.disabled, // ✅ FIXED: Using l10n instead of hardcoded
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight. w600,
              color: enabled ? Colors.green. shade700 : Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }
}