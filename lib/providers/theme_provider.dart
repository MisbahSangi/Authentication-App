import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;
  Color _primaryColor = Colors.blue;
  int _primaryColorIndex = 0;

  static const String _themeKey = 'isDarkMode';
  static const String _colorKey = 'primaryColorIndex';

  // Available theme colors
  static const List<ThemeColorOption> themeColors = [
    ThemeColorOption(name: 'Blue', color: Colors.blue, index: 0),
    ThemeColorOption(name: 'Purple', color: Colors.purple, index: 1),
    ThemeColorOption(name: 'Teal', color: Colors.teal, index: 2),
    ThemeColorOption(name: 'Green', color: Colors.green, index: 3),
    ThemeColorOption(name: 'Orange', color: Colors.orange, index: 4),
    ThemeColorOption(name: 'Red', color: Colors.red, index: 5),
    ThemeColorOption(name: 'Pink', color: Colors.pink, index: 6),
    ThemeColorOption(name: 'Indigo', color: Colors.indigo, index: 7),
    ThemeColorOption(name: 'Cyan', color: Colors.cyan, index: 8),
    ThemeColorOption(name: 'Amber', color: Colors.amber, index: 9),
  ];

  ThemeProvider() {
    _loadTheme();
  }

  bool get isDarkMode => _isDarkMode;
  Color get primaryColor => _primaryColor;
  int get primaryColorIndex => _primaryColorIndex;

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themeKey) ?? false;
    _primaryColorIndex = prefs.getInt(_colorKey) ?? 0;
    _primaryColor = themeColors[_primaryColorIndex].color;
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setDarkMode(bool value) async {
    _isDarkMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDarkMode);
    notifyListeners();
  }

  Future<void> setPrimaryColor(int index) async {
    if (index >= 0 && index < themeColors.length) {
      _primaryColorIndex = index;
      _primaryColor = themeColors[index].color;
      final prefs = await SharedPreferences.getInstance();
      await prefs. setInt(_colorKey, index);
      notifyListeners();
    }
  }

  String get currentColorName => themeColors[_primaryColorIndex].name;

  // Create MaterialColor from Color
  MaterialColor _createMaterialColor(Color color) {
    List<double> strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  Color _getDarkShade(Color color) {
    return HSLColor.fromColor(color).withLightness(0.4).toColor();
  }

  ThemeData get lightTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primarySwatch: _createMaterialColor(_primaryColor),
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.light,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _getDarkShade(_primaryColor),
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton. styleFrom(
        backgroundColor: _getDarkShade(_primaryColor),
        foregroundColor: Colors. white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _getDarkShade(_primaryColor),
      foregroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState. selected)) {
          return _getDarkShade(_primaryColor);
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryColor.withValues(alpha: 0.5);
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _getDarkShade(_primaryColor);
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState. selected)) {
          return _getDarkShade(_primaryColor);
        }
        return null;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _getDarkShade(_primaryColor),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton. styleFrom(
        foregroundColor: _getDarkShade(_primaryColor),
      ),
    ),
  );

  ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primarySwatch: _createMaterialColor(_primaryColor),
    primaryColor: _primaryColor,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _primaryColor,
      brightness: Brightness.dark,
    ),
    scaffoldBackgroundColor: Colors.grey. shade900,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.grey.shade800,
      foregroundColor: Colors.white,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: Colors.grey.shade800,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: _primaryColor,
      foregroundColor: Colors.white,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty. resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryColor;
        }
        return null;
      }),
      trackColor: WidgetStateProperty. resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryColor.withValues(alpha: 0.5);
        }
        return null;
      }),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState. selected)) {
          return _primaryColor;
        }
        return null;
      }),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return _primaryColor;
        }
        return null;
      }),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: _primaryColor,
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
      ),
    ),
  );
}

class ThemeColorOption {
  final String name;
  final Color color;
  final int index;

  const ThemeColorOption({
    required this.name,
    required this.color,
    required this. index,
  });
}