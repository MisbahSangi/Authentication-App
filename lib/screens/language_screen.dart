import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../providers/language_provider.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.selectLanguage),
        backgroundColor: isDark ?  Colors.grey.shade800 : Colors. blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors. grey.shade100, Colors.white],
          ),
        ),
        child: ListView. builder(
          padding: const EdgeInsets. all(16),
          itemCount: LanguageProvider.supportedLanguages.length,
          itemBuilder: (context, index) {
            final language = LanguageProvider.supportedLanguages[index];
            final isSelected = languageProvider.currentLocale. languageCode == language.code;

            return Card(
              color: isDark ? Colors.grey.shade800 : Colors.white,
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: isSelected
                    ? BorderSide(color: Colors.blue.shade700, width: 2)
                    : BorderSide. none,
              ),
              child: ListTile(
                leading: Text(
                  language.flag,
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(
                  language.name,
                  style: TextStyle(
                    fontWeight: FontWeight. w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                subtitle: Text(
                  language.nativeName,
                  style: TextStyle(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
                trailing: isSelected
                    ?  Icon(Icons.check_circle, color: Colors.blue.shade700)
                    : null,
                onTap: () {
                  languageProvider.setLanguage(language.code);
                  Navigator.pop(context);
                },
              ),
            );
          },
        ),
      ),
    );
  }
}