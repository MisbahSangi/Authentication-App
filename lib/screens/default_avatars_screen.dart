import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/activity_service.dart';

class DefaultAvatarsScreen extends StatefulWidget {
  const DefaultAvatarsScreen({super.key});

  @override
  State<DefaultAvatarsScreen> createState() => _DefaultAvatarsScreenState();
}

class _DefaultAvatarsScreenState extends State<DefaultAvatarsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth. instance;
  final _activityService = ActivityService();

  int?  _selectedIndex;
  bool _isLoading = false;
  String? _currentAvatar;

  // Default avatar options - using UI Avatars API
  final List<AvatarOption> _avatarOptions = [
    AvatarOption(name: 'Blue', color: '0D47A1', background: 'BBDEFB'),
    AvatarOption(name: 'Green', color: '1B5E20', background: 'C8E6C9'),
    AvatarOption(name: 'Purple', color: '4A148C', background: 'E1BEE7'),
    AvatarOption(name: 'Orange', color: 'E65100', background: 'FFE0B2'),
    AvatarOption(name: 'Red', color: 'B71C1C', background: 'FFCDD2'),
    AvatarOption(name: 'Teal', color: '004D40', background: 'B2DFDB'),
    AvatarOption(name: 'Pink', color: '880E4F', background: 'F8BBD9'),
    AvatarOption(name: 'Indigo', color: '1A237E', background: 'C5CAE9'),
    AvatarOption(name: 'Cyan', color: '006064', background: 'B2EBF2'),
    AvatarOption(name: 'Amber', color: 'FF6F00', background: 'FFECB3'),
    AvatarOption(name: 'Brown', color: '3E2723', background: 'D7CCC8'),
    AvatarOption(name: 'Grey', color: '37474F', background: 'CFD8DC'),
  ];

  // Fun avatar icons using DiceBear API
  final List<String> _avatarStyles = [
    'adventurer',
    'adventurer-neutral',
    'avataaars',
    'big-ears',
    'big-smile',
    'bottts',
    'croodles',
    'fun-emoji',
    'icons',
    'identicon',
    'initials',
    'lorelei',
    'micah',
    'miniavs',
    'notionists',
    'open-peeps',
    'personas',
    'pixel-art',
    'shapes',
    'thumbs',
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentAvatar();
  }

  Future<void> _loadCurrentAvatar() async {
    try {
      final userId = _auth.currentUser?. uid;
      if (userId != null) {
        final doc = await _firestore.collection('users'). doc(userId).get();
        if (doc.exists) {
          setState(() {
            _currentAvatar = doc.data()?['photoUrl'];
          });
        }
      }
    } catch (e) {
      print('Error loading avatar: $e');
    }
  }

  String _getAvatarUrl(int index) {
    final userName = _auth.currentUser?.displayName ??
        _auth.currentUser?.email?. split('@')[0] ??
        'User';
    final initials = userName.isNotEmpty ? userName[0]. toUpperCase() : 'U';

    if (index < _avatarOptions.length) {
      final option = _avatarOptions[index];
      return 'https://ui-avatars.com/api/?name=$initials&size=200&background=${option.background}&color=${option.color}&bold=true&font-size=0.4';
    } else {
      final styleIndex = index - _avatarOptions.length;
      if (styleIndex < _avatarStyles. length) {
        final style = _avatarStyles[styleIndex];
        final seed = _auth.currentUser?. uid ?? 'default';
        return 'https://api.dicebear. com/7.x/$style/png?seed=$seed&size=200';
      }
    }
    return '';
  }

  Future<void> _selectAvatar(int index) async {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _saveAvatar() async {
    if (_selectedIndex == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final avatarUrl = _getAvatarUrl(_selectedIndex!);

      await _firestore.collection('users').doc(userId). update({
        'photoUrl': avatarUrl,
        'avatarType': 'default',
        'avatarIndex': _selectedIndex,
      });

      await _activityService. logActivity(
        type: 'profile_updated',
        description: 'Default avatar selected',
      );

      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully! '),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error saving avatar: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider. of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations. of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Avatar'),
        backgroundColor: isDark ? Colors. grey.shade800 : themeProvider.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedIndex != null)
            TextButton(
              onPressed: _isLoading ? null : _saveAvatar,
              child: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Text(
                'Save',
                style: TextStyle(
                  color: Colors. white,
                  fontWeight: FontWeight.bold,
                ),
              ),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Preview
              if (_selectedIndex != null)
                Center(
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: themeProvider.primaryColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: themeProvider.primaryColor.withValues(alpha:0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: _buildNetworkImage(
                            _getAvatarUrl(_selectedIndex!),
                            120,
                            isDark,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Preview',
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),

              // Color Avatars Section
              Text(
                'Color Avatars',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _avatarOptions. length,
                itemBuilder: (context, index) {
                  final isSelected = _selectedIndex == index;
                  return GestureDetector(
                    onTap: () => _selectAvatar(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? themeProvider.primaryColor : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ?  [
                          BoxShadow(
                            color: themeProvider.primaryColor.withValues(alpha:0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: ClipOval(
                        child: _buildNetworkImage(
                          _getAvatarUrl(index),
                          70,
                          isDark,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Fun Avatars Section
              Text(
                'Fun Avatars',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight. bold,
                  color: isDark ?  Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _avatarStyles.length,
                itemBuilder: (context, index) {
                  final actualIndex = index + _avatarOptions. length;
                  final isSelected = _selectedIndex == actualIndex;
                  return GestureDetector(
                    onTap: () => _selectAvatar(actualIndex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? themeProvider.primaryColor : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: themeProvider.primaryColor.withValues(alpha:0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                            : null,
                      ),
                      child: ClipOval(
                        child: _buildNetworkImage(
                          _getAvatarUrl(actualIndex),
                          70,
                          isDark,
                          backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Network image with error handling
  Widget _buildNetworkImage(
      String url,
      double size,
      bool isDark, {
        Color? backgroundColor,
      }) {
    return CachedNetworkImage(
      imageUrl: url,
      width: size,
      height: size,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        width: size,
        height: size,
        color: backgroundColor ?? (isDark ? Colors. grey.shade700 : Colors.grey.shade200),
        child: Center(
          child: SizedBox(
            width: size * 0.3,
            height: size * 0.3,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Container(
        width: size,
        height: size,
        color: backgroundColor ??  (isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        child: Icon(
          Icons. person,
          size: size * 0.5,
          color: isDark ? Colors. grey.shade500 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

class AvatarOption {
  final String name;
  final String color;
  final String background;

  AvatarOption({
    required this.name,
    required this.color,
    required this. background,
  });
}