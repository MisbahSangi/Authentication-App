import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/activity_service.dart';
import '../widgets/password_strength_widget.dart';  // 🆕 NEW IMPORT
import 'home_screen.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth. instance;
  final _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreeToTerms = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _nameController. dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController. dispose();
    super.dispose();
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'An account already exists with this email. ';
      case 'invalid-email':
        return 'The email address is invalid. ';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'weak-password':
        return 'The password is too weak. ';
      default:
        return 'Signup failed. Please try again.';
    }
  }

  Future<void> _signUp() async {
    if (! _formKey.currentState!.validate()) return;

    if (! _agreeToTerms) {
      setState(() {
        _errorMessage = 'Please agree to the Terms of Service and Privacy Policy.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Create user with Firebase Auth
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text. trim(),
        password: _passwordController. text,
      );

      // Update display name
      await userCredential.user?. updateDisplayName(_nameController.text. trim());

      // Create user document in Firestore
      await _firestore. collection('users'). doc(userCredential. user! .uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text. trim(),
        'phone': '',  // 🆕 NEW: Added for profile completion
        'bio': '',  // 🆕 NEW: Added for profile completion
        'location': '',  // 🆕 NEW: Added for profile completion
        'createdAt': FieldValue.serverTimestamp(),
        'twoFactorEnabled': false,
        'biometricEnabled': false,
        'notificationsEnabled': true,
        'photoUrl': null,
      });

      // Log activity
      try {
        final activityService = ActivityService();
        await activityService.logActivity(
          type: 'account_created',
          description: 'Account created successfully',
        );
      } catch (e) {
        // Ignore activity logging errors
      }

      if (mounted) {
        // Show success message
        ScaffoldMessenger. of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.signupSuccessful),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithGoogle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      final userCredential = await _auth.signInWithPopup(googleProvider);

      // Create or update user document in Firestore
      await _firestore. collection('users'). doc(userCredential. user!.uid). set({
        'name': userCredential.user?. displayName ?? '',
        'email': userCredential.user?.email ?? '',
        'phone': '',  // 🆕 NEW
        'bio': '',  // 🆕 NEW
        'location': '',  // 🆕 NEW
        'createdAt': FieldValue.serverTimestamp(),
        'twoFactorEnabled': false,
        'biometricEnabled': false,
        'notificationsEnabled': true,
        'photoUrl': userCredential.user?. photoURL,
        'provider': 'google',
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Google sign-up failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithFacebook() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final FacebookAuthProvider facebookProvider = FacebookAuthProvider();
      facebookProvider.addScope('email');
      facebookProvider.addScope('public_profile');

      final userCredential = await _auth. signInWithPopup(facebookProvider);

      // Create or update user document in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'name': userCredential. user?.displayName ??  '',
        'email': userCredential. user?.email ?? '',
        'phone': '',  // 🆕 NEW
        'bio': '',  // 🆕 NEW
        'location': '',  // 🆕 NEW
        'createdAt': FieldValue.serverTimestamp(),
        'twoFactorEnabled': false,
        'biometricEnabled': false,
        'notificationsEnabled': true,
        'photoUrl': userCredential.user?. photoURL,
        'provider': 'facebook',
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Facebook sign-up failed.  Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _signUpWithApple() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final AppleAuthProvider appleProvider = AppleAuthProvider();
      appleProvider.addScope('email');
      appleProvider.addScope('name');

      final userCredential = await _auth. signInWithPopup(appleProvider);

      // Create or update user document in Firestore
      await _firestore. collection('users'). doc(userCredential. user!.uid). set({
        'name': userCredential.user?.displayName ?? '',
        'email': userCredential.user?.email ??  '',
        'phone': '',  // 🆕 NEW
        'bio': '',  // 🆕 NEW
        'location': '',  // 🆕 NEW
        'createdAt': FieldValue.serverTimestamp(),
        'twoFactorEnabled': false,
        'biometricEnabled': false,
        'notificationsEnabled': true,
        'photoUrl': userCredential.user?.photoURL,
        'provider': 'apple',
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Apple sign-up failed. Please try again. ';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showTermsDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n. termsOfService),
        content: const SingleChildScrollView(
          child: Text(
            'Terms of Service\n\n'
                '1.  Acceptance of Terms\n'
                'By accessing and using this application, you accept and agree to be bound by the terms and conditions of this agreement.\n\n'
                '2. Use License\n'
                'Permission is granted to temporarily use this application for personal, non-commercial purposes only.\n\n'
                '3.  User Account\n'
                'You are responsible for maintaining the confidentiality of your account and password.\n\n'
                '4. Privacy\n'
                'Your use of the application is also governed by our Privacy Policy.\n\n'
                '5. Modifications\n'
                'We reserve the right to modify these terms at any time.\n\n'
                '6. Contact\n'
                'If you have any questions about these Terms, please contact us.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n. cancel),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _agreeToTerms = true;
              });
              Navigator. pop(context);
            },
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider. isDarkMode;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey. shade900, Colors.grey. shade800, Colors.grey.shade700]
                : [Colors.blue.shade700, Colors.blue. shade500, Colors.blue. shade300],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: FadeInUp(
                duration: const Duration(milliseconds: 500),
                child: Card(
                  elevation: 8,
                  color: isDark ? Colors.grey.shade800 : Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius. circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo/Icon
                          FadeInDown(
                            child: Icon(
                              Icons.person_add_outlined,
                              size: 80,
                              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            l10n.createAccount,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight. bold,
                              color: isDark ?  Colors.white : Colors.blue.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.signUpToGetStarted,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Error Message
                          if (_errorMessage.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.red. shade50,
                                borderRadius: BorderRadius. circular(8),
                                border: Border.all(color: Colors. red.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
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

                          // Name Field
                          TextFormField(
                            controller: _nameController,
                            textCapitalization: TextCapitalization.words,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: l10n.fullName,
                              hintText: l10n.enterFullName,
                              prefixIcon: const Icon(Icons.person_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors. grey.shade600 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade700,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.fieldRequired;
                              }
                              if (value.length < 2) {
                                return 'Name must be at least 2 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: isDark ? Colors. white : Colors.black),
                            decoration: InputDecoration(
                              labelText: l10n. email,
                              hintText: l10n.enterEmail,
                              prefixIcon: const Icon(Icons.email_outlined),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade700,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.fieldRequired;
                              }
                              if (!value.contains('@') || ! value.contains('.')) {
                                return l10n.invalidEmail;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
                            decoration: InputDecoration(
                              labelText: l10n.password,
                              hintText: l10n.enterPassword,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ?  Icons.visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = ! _obscurePassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors. grey.shade600 : Colors.grey. shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius. circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue. shade700,
                                  width: 2,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {}); // 🆕 NEW: Trigger rebuild for password strength
                            },
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.fieldRequired;
                              }
                              if (value.length < 6) {
                                return l10n.passwordTooShort;
                              }
                              return null;
                            },
                          ),

                          // 🆕 NEW: Password Strength Meter
                          PasswordStrengthWidget(
                            password: _passwordController. text,
                            isDark: isDark,
                          ),

                          const SizedBox(height: 16),

                          // Confirm Password Field
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: TextStyle(color: isDark ? Colors. white : Colors.black),
                            decoration: InputDecoration(
                              labelText: l10n. confirmPassword,
                              hintText: l10n.enterConfirmPassword,
                              prefixIcon: const Icon(Icons.lock_outlined),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword ? Icons. visibility_off : Icons.visibility,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius. circular(12),
                                borderSide: BorderSide(
                                  color: isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: Colors.blue.shade700,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.fieldRequired;
                              }
                              if (value != _passwordController.text) {
                                return l10n. passwordsDoNotMatch;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Terms & Conditions Checkbox
                          Row(
                            children: [
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _agreeToTerms,
                                  onChanged: (value) {
                                    setState(() {
                                      _agreeToTerms = value ??  false;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: GestureDetector(
                                  onTap: _showTermsDialog,
                                  child: RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        color: isDark ? Colors. grey.shade300 : Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                      children: [
                                        const TextSpan(text: 'I agree to the '),
                                        TextSpan(
                                          text: l10n.termsOfService,
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight. bold,
                                          ),
                                        ),
                                        const TextSpan(text: ' and '),
                                        TextSpan(
                                          text: l10n. privacyPolicy,
                                          style: TextStyle(
                                            color: Colors.blue.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Sign Up Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _signUp,
                              style: ElevatedButton. styleFrom(
                                backgroundColor: Colors.blue. shade700,
                                foregroundColor: Colors. white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  color: Colors. white,
                                  strokeWidth: 2,
                                ),
                              )
                                  : Text(
                                l10n.signUp,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // OR Divider
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark ?  Colors.grey.shade600 : Colors.grey.shade300,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  l10n.or,
                                  style: TextStyle(
                                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontWeight: FontWeight. w500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark ? Colors.grey. shade600 : Colors.grey.shade300,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Social Sign Up Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildSocialButton(
                                icon: Icons.g_mobiledata,
                                color: Colors.red,
                                isDark: isDark,
                                onTap: _signUpWithGoogle,
                              ),
                              _buildSocialButton(
                                icon: Icons.facebook,
                                color: Colors.blue. shade800,
                                isDark: isDark,
                                onTap: _signUpWithFacebook,
                              ),
                              _buildSocialButton(
                                icon: Icons. apple,
                                color: isDark ? Colors.white : Colors.black,
                                isDark: isDark,
                                onTap: _signUpWithApple,
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n.alreadyHaveAccount,
                                style: TextStyle(
                                  color: isDark ? Colors. grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.login,
                                  style: const TextStyle(fontWeight: FontWeight. bold),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius. circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? Colors.grey. shade600 : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDark ? Colors.grey.shade700 : Colors.white,
        ),
        child: Icon(icon, color: color, size: 32),
      ),
    );
  }
}