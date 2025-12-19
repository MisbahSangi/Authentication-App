import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/activity_service.dart';
import '../services/session_service.dart';
import '../services/biometric_service.dart';
import '../services/two_factor_service.dart';
import '../services/login_alert_service.dart';
import '../services/social_auth_service.dart';
import 'home_screen.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import 'phone_auth_screen.dart';
import 'two_factor_verify_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth. instance;
  final _firestore = FirebaseFirestore.instance;
  final _biometricService = BiometricService();
  final _twoFactorService = TwoFactorService();
  final _loginAlertService = LoginAlertService();
  final _sessionService = SessionService();
  final _socialAuthService = SocialAuthService();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _errorMessage = '';
  bool _biometricPromptShown = false;
  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _checkAppleSignInAvailability();
    WidgetsBinding. instance.addPostFrameCallback((_) {
      _checkBiometricLogin();
    });
  }

  Future<void> _checkAppleSignInAvailability() async {
    final isAvailable = await _socialAuthService.isAppleSignInAvailable();
    if (mounted) {
      setState(() {
        _isAppleSignInAvailable = isAvailable;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs. getString('saved_email');
    final savedPassword = prefs.getString('saved_password');
    final rememberMe = prefs.getBool('remember_me') ?? false;

    if (rememberMe && savedEmail != null && savedPassword != null) {
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberMe = true;
        });
      }
    }
  }

  Future<void> _checkBiometricLogin() async {
    if (_biometricPromptShown) return;

    try {
      final biometricEnabled = await _biometricService.isBiometricEnabled();
      if (! biometricEnabled) return;

      final biometricAvailable = await _biometricService.isBiometricAvailable();
      if (!biometricAvailable) return;

      final credentials = await _biometricService.getSavedCredentials();
      if (credentials == null) return;

      _biometricPromptShown = true;

      final authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to login to AuthApp',
      );

      if (authenticated && mounted) {
        setState(() {
          _emailController.text = credentials['email']! ;
          _passwordController.text = credentials['password']!;
        });
        await _loginWithBiometric(credentials['email']!, credentials['password']!);
      }
    } catch (e) {
      debugPrint('🔒 Error in biometric check: $e');
    }
  }

  Future<void> _loginWithBiometric(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      await _handlePostLogin('biometric');
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e. code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Biometric login failed.  Please login manually.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    if (_rememberMe) {
      await prefs.setString('saved_email', _emailController.text. trim());
      await prefs.setString('saved_password', _passwordController.text);
      await prefs.setBool('remember_me', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.remove('saved_password');
      await prefs.setBool('remember_me', false);
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email. ';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled. ';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with the same email.  Try a different sign-in method.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.  Please contact support.';
      case 'popup-closed-by-user':
        return 'Sign-in was cancelled. ';
      case 'popup-blocked':
        return 'Sign-in popup was blocked.  Please allow popups for this site.';
      default:
        return 'Login failed. Please try again.';
    }
  }

  Future<void> _login() async {
    if (! _formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth. signInWithEmailAndPassword(
        email: _emailController. text.trim(),
        password: _passwordController.text,
      );

      await _saveCredentials();

      final biometricEnabled = await _biometricService.isBiometricEnabled();
      if (biometricEnabled) {
        await _biometricService.saveCredentials(
          _emailController.text. trim(),
          _passwordController.text,
        );
      }

      final twoFactorEnabled = await _twoFactorService.is2FAEnabledForEmail(
        _emailController.text.trim(),
      );

      if (twoFactorEnabled) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => TwoFactorVerifyScreen(
                email: _emailController. text.trim(),
                password: _passwordController. text,
              ),
            ),
          );
        }
        return;
      }

      await _handlePostLogin('email');
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e.code);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================
  // SOCIAL LOGIN METHODS
  // ============================================

  Future<void> _loginWithGoogle() async {
    await _handleSocialLogin(
          () => _socialAuthService.signInWithGoogle(),
      'Google',
      'google',
    );
  }

  Future<void> _loginWithFacebook() async {
    await _handleSocialLogin(
          () => _socialAuthService.signInWithFacebook(),
      'Facebook',
      'facebook',
    );
  }

  Future<void> _loginWithTwitter() async {
    await _handleSocialLogin(
          () => _socialAuthService.signInWithTwitter(),
      'Twitter',
      'twitter',
    );
  }

  Future<void> _loginWithApple() async {
    await _handleSocialLogin(
          () => _socialAuthService.signInWithApple(),
      'Apple',
      'apple',
    );
  }

  Future<void> _handleSocialLogin(
      Future<UserCredential?> Function() signInMethod,
      String providerName,
      String providerId,
      ) async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final userCredential = await signInMethod();

      if (userCredential == null) {
        // User cancelled
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
        return;
      }

      // Save user to Firestore
      await _saveUserToFirestore(userCredential, providerId);

      // Handle post-login tasks
      await _handlePostLogin(providerId);

      // Navigate to home
      _navigateToHome();
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = _getErrorMessage(e.code);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '$providerName sign-in failed: ${e.toString()}';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveUserToFirestore(UserCredential userCredential, String provider) async {
    final user = userCredential.user! ;

    await _firestore.collection('users'). doc(user.uid).set({
      'name': user.displayName ?? '',
      'email': user.email ??  '',
      'photoUrl': user.photoURL,
      'phone': user.phoneNumber ?? '',
      'lastLoginAt': FieldValue.serverTimestamp(),
      'provider': provider,
    }, SetOptions(merge: true));
  }

  Future<void> _handlePostLogin(String provider) async {
    try {
      final activityService = ActivityService();
      await activityService.logActivity(
        type: 'login',
        description: 'Logged in with $provider',
      );
      await _loginAlertService.recordLoginAndAlert();
      await _sessionService.createSession();
    } catch (e) {
      debugPrint('Error in post-login tasks: $e');
    }
  }

  void _navigateToHome() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    }
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
                : [themeProvider.primaryColor, themeProvider. primaryColor.withValues(alpha:0.8), themeProvider.primaryColor.withValues(alpha:0.6)],
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
                        mainAxisSize: MainAxisSize. min,
                        children: [
                          // Logo/Icon
                          FadeInDown(
                            child: Icon(
                              Icons.lock_outlined,
                              size: 80,
                              color: themeProvider.primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Title
                          Text(
                            l10n.welcomeBack,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight. bold,
                              color: isDark ? Colors.white : themeProvider. primaryColor,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            l10n.signInToContinue,
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark ? Colors.grey. shade400 : Colors.grey.shade600,
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
                                border: Border.all(color: Colors. red. shade200),
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

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: isDark ? Colors.white : Colors.black),
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
                                  color: isDark ? Colors. grey.shade600 : Colors.grey.shade300,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                  color: themeProvider.primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.fieldRequired;
                              }
                              if (!value.contains('@') || !value.contains('.')) {
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
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
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
                                  color: themeProvider. primaryColor,
                                  width: 2,
                                ),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n. fieldRequired;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Remember Me & Forgot Password
                          Row(
                            mainAxisAlignment: MainAxisAlignment. spaceBetween,
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _rememberMe,
                                      onChanged: (value) {
                                        setState(() {
                                          _rememberMe = value ??  false;
                                        });
                                      },
                                      activeColor: themeProvider.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.rememberMe,
                                    style: TextStyle(
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
                                    ),
                                  ),
                                ],
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n. forgotPassword,
                                  style: TextStyle(color: themeProvider.primaryColor),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeProvider. primaryColor,
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
                                l10n.login,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone Login Button
                          SizedBox(
                            width: double. infinity,
                            height: 50,
                            child: OutlinedButton. icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const PhoneAuthScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons. phone),
                              label: Text(l10n.phoneLogin),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: themeProvider.primaryColor,
                                side: BorderSide(color: themeProvider. primaryColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
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
                                  color: isDark ?  Colors.grey.shade600 : Colors. grey.shade300,
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

                          // Social Login Buttons
                          _buildSocialLoginButtons(isDark, themeProvider),
                          const SizedBox(height: 24),

                          // Sign Up Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                l10n. dontHaveAccount,
                                style: TextStyle(
                                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SignupScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  l10n.signUp,
                                  style: TextStyle(
                                    fontWeight: FontWeight. bold,
                                    color: themeProvider.primaryColor,
                                  ),
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

  Widget _buildSocialLoginButtons(bool isDark, ThemeProvider themeProvider) {
    return Wrap(
      alignment: WrapAlignment. center,
      spacing: 12,
      runSpacing: 12,
      children: [
        // Google - Always show
        _buildSocialButton(
          icon: Icons.g_mobiledata,
          color: Colors.red,
          isDark: isDark,
          onTap: _loginWithGoogle,
          tooltip: 'Sign in with Google',
        ),

        // Facebook - Always show
        _buildSocialButton(
          icon: Icons. facebook,
          color: Colors.blue. shade800,
          isDark: isDark,
          onTap: _loginWithFacebook,
          tooltip: 'Sign in with Facebook',
        ),

        // Twitter - Always show
        _buildSocialButton(
          icon: Icons.close, // X logo
          color: isDark ? Colors.white : Colors.black,
          isDark: isDark,
          onTap: _loginWithTwitter,
          tooltip: 'Sign in with X (Twitter)',
        ),

        // Apple - Only show if available
        if (_isAppleSignInAvailable)
          _buildSocialButton(
            icon: Icons.apple,
            color: isDark ? Colors.white : Colors.black,
            isDark: isDark,
            onTap: _loginWithApple,
            tooltip: 'Sign in with Apple',
          ),
      ],
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: _isLoading ? null : onTap,
        borderRadius: BorderRadius. circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? Colors.grey. shade600 : Colors.grey.shade300,
            ),
            borderRadius: BorderRadius.circular(12),
            color: isDark ?  Colors.grey.shade700 : Colors.white,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
      ),
    );
  }
}