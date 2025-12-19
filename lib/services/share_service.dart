import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

class ShareService {
  static const String appName = 'AuthApp';
  static const String appDescription = 'Secure Authentication Made Easy';
  static const String playStoreUrl = 'https://play.google.com/store/apps/details?id=com.authapp';
  static const String appStoreUrl = 'https://apps. apple.com/app/authapp';
  static const String webUrl = 'https://authapp.com';

  /// Get the share message
  String getShareMessage() {
    return '''
🔐 Check out $appName! 

$appDescription

✅ Multiple sign-in options (Email, Google, Facebook, Apple, Phone)
✅ Two-Factor Authentication
✅ Biometric Login
✅ Dark Mode
✅ Multi-language Support

Download now:
📱 Android: $playStoreUrl
🍎 iOS: $appStoreUrl
🌐 Web: $webUrl
''';
  }

  /// Share via system share dialog
  Future<void> shareApp({Rect? sharePositionOrigin}) async {
    try {
      await Share.share(
        getShareMessage(),
        subject: '$appName - $appDescription',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      print('Error sharing: $e');
    }
  }

  /// Share with specific text
  Future<void> shareWithText(String text, {Rect? sharePositionOrigin}) async {
    try {
      await Share.share(
        text,
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      print('Error sharing: $e');
    }
  }

  /// Copy share link to clipboard
  Future<bool> copyLinkToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: webUrl));
      return true;
    } catch (e) {
      print('Error copying to clipboard: $e');
      return false;
    }
  }

  /// Copy full message to clipboard
  Future<bool> copyMessageToClipboard() async {
    try {
      await Clipboard.setData(ClipboardData(text: getShareMessage()));
      return true;
    } catch (e) {
      print('Error copying to clipboard: $e');
      return false;
    }
  }

  /// Get referral code (placeholder - would integrate with backend)
  String getReferralCode() {
    // In a real app, this would fetch from user profile or generate unique code
    return 'AUTHAPP2024';
  }

  /// Get referral link
  String getReferralLink() {
    return '$webUrl/invite/${getReferralCode()}';
  }

  /// Share referral link
  Future<void> shareReferralLink({Rect? sharePositionOrigin}) async {
    final referralMessage = '''
🔐 Join me on $appName!

Use my referral code: ${getReferralCode()}

$appDescription

Sign up here: ${getReferralLink()}
''';

    try {
      await Share.share(
        referralMessage,
        subject: 'Join $appName with my referral',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      print('Error sharing referral: $e');
    }
  }
}