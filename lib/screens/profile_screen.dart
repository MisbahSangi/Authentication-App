import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/activity_service.dart';
import '../services/cloudinary_service.dart';
import 'settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();  // 🆕 NEW
  final _bioController = TextEditingController();  // 🆕 NEW
  final _locationController = TextEditingController();  // 🆕 NEW
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _cloudinaryService = CloudinaryService();

  bool _isLoading = false;
  bool _isEditing = false;
  bool _isUploadingImage = false;
  Map<String, dynamic>? _userData;
  String? _profileImageUrl;

  // 🆕 NEW: Profile completion tracking
  double _profileCompletion = 0.0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();  // 🆕 NEW
    _bioController.dispose();  // 🆕 NEW
    _locationController.dispose();  // 🆕 NEW
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          setState(() {
            _userData = doc.data();
            _nameController.text = _userData?['name'] ?? '';
            _phoneController.text = _userData?['phone'] ?? '';  // 🆕 NEW
            _bioController.text = _userData?['bio'] ?? '';  // 🆕 NEW
            _locationController.text = _userData?['location'] ?? '';  // 🆕 NEW
            _profileImageUrl = _userData?['photoUrl'];
            _calculateProfileCompletion();  // 🆕 NEW
          });
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 🆕 NEW: Calculate profile completion percentage
  void _calculateProfileCompletion() {
    int completedFields = 0;
    int totalFields = 5; // name, phone, bio, location, photo

    if (_nameController.text. isNotEmpty) completedFields++;
    if (_phoneController.text.isNotEmpty) completedFields++;
    if (_bioController.text.isNotEmpty) completedFields++;
    if (_locationController.text.isNotEmpty) completedFields++;
    if (_profileImageUrl != null) completedFields++;

    setState(() {
      _profileCompletion = completedFields / totalFields;
    });
  }

  Future<void> _saveProfile() async {
    if (! _formKey.currentState!. validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Update Firebase Auth display name
      await user.updateDisplayName(_nameController.text. trim());

      // 🆕 UPDATED: Save all profile fields to Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),  // 🆕 NEW
        'bio': _bioController.text.trim(),  // 🆕 NEW
        'location': _locationController.text. trim(),  // 🆕 NEW
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Log activity
      try {
        final activityService = ActivityService();
        await activityService.logActivity(
          type: 'profile_updated',
          description: 'Profile information updated',
        );
      } catch (e) {
        // Ignore activity logging errors
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdated),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _isEditing = false;
        });
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context). showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
            backgroundColor: Colors. red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showImageSourceDialog() async {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? Colors.grey. shade800 : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius. vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  l10n.chooseImageSource,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 24),

                // Camera Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.blue.shade700),
                  ),
                  title: Text(
                    l10n.camera,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ?  Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(fromCamera: true);
                  },
                ),
                const SizedBox(height: 8),

                // Gallery Option
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons. photo_library, color: Colors. green.shade700),
                  ),
                  title: Text(
                    l10n.gallery,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(fromCamera: false);
                  },
                ),

                // Remove Photo Option (only show if photo exists)
                if (_profileImageUrl != null) ...[
                  const SizedBox(height: 8),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.delete, color: Colors.red.shade700),
                    ),
                    title: Text(
                      l10n.removePhoto,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _removeProfilePicture();
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadImage({required bool fromCamera}) async {
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // Pick image
      final imageFile = fromCamera
          ? await _cloudinaryService.pickImageFromCamera()
          : await _cloudinaryService.pickImageFromGallery();

      if (imageFile == null) {
        setState(() {
          _isUploadingImage = false;
        });
        return;
      }

      // Upload to Cloudinary
      final imageUrl = await _cloudinaryService.uploadImage(imageFile);

      if (imageUrl != null) {
        setState(() {
          _profileImageUrl = imageUrl;
        });
        _calculateProfileCompletion();  // 🆕 NEW

        // Log activity
        try {
          final activityService = ActivityService();
          await activityService.logActivity(
            type: 'profile_updated',
            description: 'Profile picture updated',
          );
        } catch (e) {
          // Ignore
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.imageUploadSuccess),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.imageUploadFailed),
              backgroundColor: Colors. red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.imageUploadFailed),
            backgroundColor: Colors. red,
          ),
        );
      }
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  Future<void> _removeProfilePicture() async {
    final l10n = AppLocalizations.of(context)! ;

    setState(() {
      _isUploadingImage = true;
    });

    try {
      final success = await _cloudinaryService.deleteProfilePicture();

      if (success) {
        setState(() {
          _profileImageUrl = null;
        });
        _calculateProfileCompletion();  // 🆕 NEW

        if (mounted) {
          ScaffoldMessenger.of(context). showSnackBar(
            SnackBar(
              content: Text(l10n.imageRemoved),
              backgroundColor: Colors. green,
            ),
          );
        }
      }
    } catch (e) {
      // Handle error silently
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';

    DateTime date;
    if (timestamp is Timestamp) {
      date = timestamp.toDate();
    } else {
      return 'N/A';
    }

    return DateFormat('MMMM dd, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations.of(context)!;
    final user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.profile),
        backgroundColor: isDark ? Colors.grey. shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          if (! _isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () {
                setState(() {
                  _isEditing = false;
                  // Reset controllers to original values
                  _nameController.text = _userData?['name'] ?? '';
                  _phoneController.text = _userData?['phone'] ?? '';
                  _bioController.text = _userData? ['bio'] ?? '';
                  _locationController.text = _userData?['location'] ?? '';
                });
              },
            ),
        ],
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // 🆕 NEW: Profile Completion Progress
              _buildProfileCompletionCard(isDark, l10n),
              const SizedBox(height: 20),

              // Profile Avatar with Upload
              Center(
                child: Stack(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _isUploadingImage ? null : _showImageSourceDialog,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.shade700,
                            width: 3,
                          ),
                        ),
                        child: _isUploadingImage
                            ? CircleAvatar(
                          radius: 60,
                          backgroundColor: isDark
                              ? Colors.grey. shade700
                              : Colors.blue.shade50,
                          child: const CircularProgressIndicator(),
                        )
                            : CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.blue.shade100,
                          backgroundImage: _profileImageUrl != null
                              ? NetworkImage(
                            _cloudinaryService.getOptimizedUrl(
                              _profileImageUrl!,
                              size: 300,
                            ),
                          )
                              : null,
                          child: _profileImageUrl == null
                              ? Text(
                            (user?.displayName?. isNotEmpty == true)
                                ?  user! .displayName![0]. toUpperCase()
                                : (user?.email?.isNotEmpty == true)
                                ? user!. email![0].toUpperCase()
                                : 'U',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade700,
                            ),
                          )
                              : null,
                        ),
                      ),
                    ),

                    // Camera Icon Button
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _isUploadingImage ? null : _showImageSourceDialog,
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade700,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ?  Colors.grey.shade800 : Colors.white,
                              width: 3,
                            ),
                          ),
                          child: const Icon(
                            Icons. camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Change Photo Text
              TextButton(
                onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                child: Text(
                  l10n.changeProfilePicture,
                  style: TextStyle(
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Profile Form
              Form(
                key: _formKey,
                child: Card(
                  color: isDark ? Colors.grey. shade800 : Colors.white,
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name Field
                        _buildTextField(
                          controller: _nameController,
                          label: l10n.fullName,
                          hint: l10n.enterFullName,
                          icon: Icons.person_outlined,
                          enabled: _isEditing,
                          isDark: isDark,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l10n.fieldRequired;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // 🆕 NEW: Phone Field
                        _buildTextField(
                          controller: _phoneController,
                          label: l10n.phone,
                          hint: l10n.enterPhone,
                          icon: Icons.phone_outlined,
                          enabled: _isEditing,
                          isDark: isDark,
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 20),

                        // 🆕 NEW: Bio Field
                        _buildTextField(
                          controller: _bioController,
                          label: l10n.bio,
                          hint: l10n.enterBio,
                          icon: Icons.info_outlined,
                          enabled: _isEditing,
                          isDark: isDark,
                          maxLines: 3,
                          maxLength: 150,
                        ),
                        const SizedBox(height: 20),

                        // 🆕 NEW: Location Field
                        _buildTextField(
                          controller: _locationController,
                          label: l10n. location,
                          hint: l10n.enterLocation,
                          icon: Icons.location_on_outlined,
                          enabled: _isEditing,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 20),

                        // Email Field (Read-only)
                        _buildTextField(
                          controller: TextEditingController(text: user?.email ?? ''),
                          label: l10n. email,
                          hint: '',
                          icon: Icons.email_outlined,
                          enabled: false,
                          isDark: isDark,
                          readOnlyStyle: true,
                        ),
                        const SizedBox(height: 20),

                        // Member Since
                        Text(
                          l10n. memberSince,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _formatDate(_userData?['createdAt']),
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              if (_isEditing)
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(
                      l10n.saveChanges,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Settings Button
              if (!_isEditing) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton. icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l10n.settings),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // 🆕 NEW: Profile Completion Card Widget
  Widget _buildProfileCompletionCard(bool isDark, AppLocalizations l10n) {
    final percentage = (_profileCompletion * 100).toInt();
    final isComplete = percentage == 100;

    return Card(
      color: isDark ? Colors.grey.shade800 : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Profile Completion',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ?  Colors.white : Colors.black87,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isComplete ? Colors.green.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isComplete ? Colors.green. shade700 : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: _profileCompletion,
                minHeight: 8,
                backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isComplete ? Colors. green : Colors.blue. shade700,
                ),
              ),
            ),
            if (!isComplete) ...[
              const SizedBox(height: 8),
              Text(
                'Complete your profile to unlock all features! ',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // 🆕 NEW: Reusable TextField Builder
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool enabled,
    required bool isDark,
    TextInputType?  keyboardType,
    int maxLines = 1,
    int?  maxLength,
    bool readOnlyStyle = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          style: TextStyle(
            color: readOnlyStyle
                ? (isDark ? Colors.grey.shade400 : Colors.grey.shade600)
                : (isDark ? Colors.white : Colors.black),
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: enabled
                ? (isDark ? Colors. grey.shade700 : Colors. white)
                : (isDark ?  Colors.grey.shade700 : Colors.grey.shade100),
            counterText: maxLength != null ?  null : '',
          ),
          validator: validator,
        ),
      ],
    );
  }
}