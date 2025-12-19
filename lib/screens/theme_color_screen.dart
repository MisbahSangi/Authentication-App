import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class ThemeColorScreen extends StatelessWidget {
  const ThemeColorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.themeColor),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview Card
              _buildPreviewCard(themeProvider, isDark, l10n),
              const SizedBox(height: 24),

              // Color Selection
              Text(
                l10n.selectThemeColor,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Color Grid
              _buildColorGrid(themeProvider, isDark),
              const SizedBox(height: 24),

              // Dark Mode Toggle
              _buildDarkModeCard(themeProvider, isDark, l10n),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewCard(ThemeProvider themeProvider, bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ? Colors.grey. shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.preview,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ?  Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),

            // Preview App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: themeProvider.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  const SizedBox(width: 16),
                  const Text(
                    'App Bar Preview',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.more_vert, color: Colors. white, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Preview Button
            Row(
              children: [
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeProvider.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(l10n.save),
                ),
                const SizedBox(width: 12),
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: themeProvider.primaryColor,
                    side: BorderSide(color: themeProvider.primaryColor),
                  ),
                  child: Text(l10n.cancel),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Preview Switch
            Row(
              children: [
                Text(
                  l10n.notifications,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                Switch(
                  value: true,
                  onChanged: (_) {},
                  activeThumbColor: themeProvider.primaryColor,
                ),
              ],
            ),

            // Preview Progress
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: 0.7,
              backgroundColor: isDark ?  Colors.grey. shade700 : Colors.grey. shade200,
              valueColor: AlwaysStoppedAnimation<Color>(themeProvider.primaryColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorGrid(ThemeProvider themeProvider, bool isDark) {
    return Card(
      color: isDark ?  Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius. circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: ThemeProvider.themeColors.length,
          itemBuilder: (context, index) {
            final colorOption = ThemeProvider.themeColors[index];
            final isSelected = themeProvider.primaryColorIndex == index;

            return GestureDetector(
              onTap: () {
                themeProvider.setPrimaryColor(index);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: colorOption.color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: colorOption.color.withValues(alpha:0.5),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 24,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildDarkModeCard(ThemeProvider themeProvider, bool isDark, AppLocalizations l10n) {
    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (isDark ? Colors.amber : Colors.indigo).withValues(alpha:0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isDark ? Icons.dark_mode : Icons.light_mode,
            color: isDark ? Colors.amber : Colors.indigo,
          ),
        ),
        title: Text(
          l10n. darkMode,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDark ?  Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          isDark ? l10n.darkModeEnabled : l10n.lightModeEnabled,
          style: TextStyle(
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
        trailing: Switch(
          value: isDark,
          onChanged: (value) => themeProvider.setDarkMode(value),
          activeThumbColor: themeProvider.primaryColor,
        ),
      ),
    );
  }
}