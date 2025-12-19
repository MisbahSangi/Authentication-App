import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _auth = FirebaseAuth. instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (! _formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    // Show final confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors. red. shade700),
            const SizedBox(width: 8),
            Text(l10n.areYouSure),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n. deleteAccountWarning),
            const SizedBox(height: 16),
            Text(
              'This will delete:',
              style: TextStyle(fontWeight: FontWeight. bold),
            ),
            const SizedBox(height: 8),
            _buildDeleteItem('Your profile information'),
            _buildDeleteItem('Your activity history'),
            _buildDeleteItem('Your settings and preferences'),
            _buildDeleteItem('All associated data'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors. red,
              foregroundColor: Colors.white,
            ),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('User not logged in');
      }

      // Re-authenticate user
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: _passwordController.text,
      );
      await user.reauthenticateWithCredential(credential);

      // Delete user data from Firestore
      await _deleteUserData(user.uid);

      // Delete Firebase Auth account
      await user.delete();

      if (mounted) {
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.accountDeleted),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e. code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred.  Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteUserData(String userId) async {
    // Delete user document
    await _firestore.collection('users'). doc(userId).delete();

    // Delete user activities
    final activitiesSnapshot = await _firestore
        .collection('activities')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in activitiesSnapshot.docs) {
      await doc.reference.delete();
    }

    // Delete user notifications
    final notificationsSnapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .get();

    for (final doc in notificationsSnapshot.docs) {
      await doc. reference.delete();
    }
  }

  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(Icons.remove_circle, size: 16, color: Colors. red.shade400),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'wrong-password':
        return 'Password is incorrect. ';
      case 'requires-recent-login':
        return 'Please log out and log in again before deleting account.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Failed to delete account. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider. of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations. of(context)! ;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n. deleteAccount),
        backgroundColor: Colors.red. shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey. shade900, Colors.grey. shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Warning Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius. circular(12),
                    border: Border.all(color: Colors. red.shade200),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons. warning_amber_rounded,
                        color: Colors.red.shade700,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Danger Zone',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight. bold,
                                color: Colors.red.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              l10n.deleteAccountWarning,
                              style: TextStyle(
                                color: Colors.red. shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Icon
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.delete_forever,
                      size: 60,
                      color: Colors.red. shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Error Message
                if (_errorMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors. red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors. red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red. shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage,
                            style: TextStyle(color: Colors.red. shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Password Field
                Text(
                  l10n.password,
                  style: TextStyle(
                    fontWeight: FontWeight. w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: isDark ? Colors.white : Colors. black),
                  decoration: InputDecoration(
                    hintText: l10n.enterPassword,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ? Colors.grey. shade700 : Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value. isEmpty) {
                      return l10n.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Confirmation Field
                Text(
                  l10n.typeDeleteToConfirm,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmController,
                  style: TextStyle(color: isDark ? Colors.white : Colors. black),
                  decoration: InputDecoration(
                    hintText: 'DELETE',
                    prefixIcon: const Icon(Icons.warning_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: isDark ?  Colors.grey.shade700 : Colors. white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l10n.fieldRequired;
                    }
                    if (value. toUpperCase() != 'DELETE') {
                      return 'Please type DELETE to confirm';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Delete Account Button
                SizedBox(
                  width: double. infinity,
                  height: 50,
                  child: ElevatedButton. icon(
                    onPressed: _isLoading ? null : _deleteAccount,
                    icon: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.delete_forever),
                    label: Text(
                      _isLoading ? l10n.loading : l10n. deleteAccount,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight. bold,
                      ),
                    ),
                    style: ElevatedButton. styleFrom(
                      backgroundColor: Colors. red. shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Cancel Button
                SizedBox(
                  width: double. infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => Navigator. pop(context),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius. circular(12),
                      ),
                    ),
                    child: Text(
                      l10n.cancel,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}