import 'package:flutter/material.dart';

class AppConstants {
  // ==================== APP INFO ====================
  static const String appName = 'AuthApp';
  static const String appVersion = '1.0. 0';
  static const String appBuildNumber = '1';
  static const String appDescription = 'Secure Authentication Made Easy';
  
  // ==================== URLS ====================
  static const String playStoreUrl = 'https://play. google.com/store/apps/details? id=com.example.authapp';
  static const String appStoreUrl = 'https://apps. apple.com/app/authapp';
  static const String webUrl = 'https://authapp.com';
  static const String privacyPolicyUrl = 'https://authapp. com/privacy';
  static const String termsOfServiceUrl = 'https://authapp. com/terms';
  
  // ==================== FIREBASE COLLECTIONS ====================
  static const String usersCollection = 'users';
  static const String activitiesCollection = 'activities';
  static const String notificationsCollection = 'notifications';
  static const String sessionsSubcollection = 'sessions';
  static const String loginHistorySubcollection = 'login_history';
  
  // ==================== SHARED PREFERENCES KEYS ====================
  static const String themeModeKey = 'theme_mode';
  static const String primaryColorKey = 'primary_color';
  static const String languageCodeKey = 'language_code';
  static const String biometricEnabledKey = 'biometric_enabled';
  static const String biometricEmailKey = 'biometric_email';
  static const String biometricPasswordKey = 'biometric_password';
  static const String twoFaEnabledKey = 'two_fa_enabled';
  static const String twoFaSecretKey = 'two_fa_secret';
  static const String savedEmailKey = 'saved_email';
  static const String savedPasswordKey = 'saved_password';
  static const String rememberMeKey = 'remember_me';
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  // ==================== VALIDATION ====================
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 32;
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int otpLength = 6;
  static const int phoneMinLength = 10;
  static const int phoneMaxLength = 15;
  
  // ==================== TIMEOUTS & DURATIONS ====================
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration splashDuration = Duration(seconds: 2);
  static const Duration snackBarDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const Duration cacheExpiry = Duration(hours: 24);
  
  // ==================== PAGINATION ====================
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  
  // ==================== IMAGE SIZES ====================
  static const int thumbnailSize = 100;
  static const int profileImageSize = 200;
  static const int maxImageSize = 1024;
  static const int maxImageBytes = 5 * 1024 * 1024; // 5MB
  
  // ==================== THEME COLORS ====================
  static const List<Color> themeColors = [
    Colors.blue,
    Colors.indigo,
    Colors.purple,
    Colors.deepPurple,
    Colors.teal,
    Colors.green,
    Colors. orange,
    Colors. deepOrange,
    Colors.red,
    Colors.pink,
  ];
  
  static const List<String> themeColorNames = [
    'Blue',
    'Indigo',
    'Purple',
    'Deep Purple',
    'Teal',
    'Green',
    'Orange',
    'Deep Orange',
    'Red',
    'Pink',
  ];
  
  // ==================== SUPPORTED LANGUAGES ====================
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'ur', 'name': 'Urdu', 'nativeName': 'اردو'},
    {'code': 'ar', 'name': 'Arabic', 'nativeName': 'العربية'},
    {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    {'code': 'fr', 'name': 'French', 'nativeName': 'Français'},
  ];
  
  // ==================== SUPPORT ====================
  static const String supportEmail = 'support@authapp.com';
  static const String supportPhone = '+92 334 6461739';
  static const String supportHours = '9 AM - 6 PM';
}