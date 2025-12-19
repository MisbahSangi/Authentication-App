import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/export_service.dart';
import '../services/activity_service.dart';

class ExportDataScreen extends StatefulWidget {
  const ExportDataScreen({super.key});

  @override
  State<ExportDataScreen> createState() => _ExportDataScreenState();
}

class _ExportDataScreenState extends State<ExportDataScreen> {
  final _exportService = ExportService();
  final _activityService = ActivityService();
  
  Map<String, int>? _dataSummary;
  bool _isLoading = true;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadDataSummary();
  }

  Future<void> _loadDataSummary() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final summary = await _exportService.getDataSummary();
      setState(() {
        _dataSummary = summary;
      });
    } catch (e) {
      print('Error loading summary: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _exportJson() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.exportAsJson();
      await _activityService.logActivity(
        type: 'data_exported',
        description: 'Data exported as JSON',
      );

      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully! '),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportCsv() async {
    setState(() {
      _isExporting = true;
    });

    try {
      await _exportService.exportAsCsv();
      await _activityService.logActivity(
        type: 'data_exported',
        description: 'Data exported as CSV',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data exported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.exportData),
        backgroundColor: isDark ? Colors.grey. shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment. bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors. grey.shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Card(
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
                                'Download a copy of your personal data.  This includes your profile, activities, login history, and more.',
                                style: TextStyle(
                                  color: isDark ? Colors.blue.shade200 : Colors.blue.shade700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Data Summary
                    Text(
                      'Your Data Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      color: isDark ? Colors.grey.shade800 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildSummaryRow(
                              icon: Icons.history,
                              label: 'Activities',
                              count: _dataSummary?['activities'] ?? 0,
                              isDark: isDark,
                            ),
                            const Divider(),
                            _buildSummaryRow(
                              icon: Icons.login,
                              label: 'Login History',
                              count: _dataSummary?['loginHistory'] ?? 0,
                              isDark: isDark,
                            ),
                            const Divider(),
                            _buildSummaryRow(
                              icon: Icons.devices,
                              label: 'Sessions',
                              count: _dataSummary?['sessions'] ?? 0,
                              isDark: isDark,
                            ),
                            const Divider(),
                            _buildSummaryRow(
                              icon: Icons.notifications,
                              label: 'Notifications',
                              count: _dataSummary?['notifications'] ?? 0,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Export Options
                    Text(
                      'Export Format',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // JSON Export
                    Card(
                      color: isDark ? Colors. grey.shade800 : Colors. white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.data_object, color: Colors.orange),
                        ),
                        title: Text(
                          'JSON Format',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Machine-readable format, includes all data',
                          style: TextStyle(
                            color: isDark ?  Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: _isExporting ? null : _exportJson,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                          ),
                          child: _isExporting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Export'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // CSV Export
                    Card(
                      color: isDark ? Colors.grey. shade800 : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius. circular(12),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green. withValues(alpha:0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.table_chart, color: Colors.green),
                        ),
                        title: Text(
                          'CSV Format',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          'Spreadsheet format, open in Excel/Sheets',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: _isExporting ? null : _exportCsv,
                          style: ElevatedButton. styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                          child: _isExporting
                              ?  const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Export'),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummaryRow({
    required IconData icon,
    required String label,
    required int count,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.grey. shade300 : Colors.grey.shade700,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ?  Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}