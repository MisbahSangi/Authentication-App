import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:animate_do/animate_do.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _auth = FirebaseAuth. instance;

  bool _isLoading = false;
  bool _emailSent = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (! _formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      await _auth.sendPasswordResetEmail(
        email: _emailController.text.trim(),
      );

      setState(() {
        _emailSent = true;
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = _getErrorMessage(e. code);
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

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email. ';
      case 'invalid-email':
        return 'The email address is invalid. ';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Failed to send reset email.  Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    final l10n = AppLocalizations. of(context)! ;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey. shade900, Colors. grey.shade800, Colors.grey.shade700]
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
                    child: _emailSent
                        ? _buildSuccessContent(isDark, l10n)
                        : _buildFormContent(isDark, l10n),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent(bool isDark, AppLocalizations l10n) {
    return Column(
      mainAxisSize: MainAxisSize. min,
      children: [
        FadeInDown(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 60,
              color: Colors.green.shade700,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          l10n.success,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight. bold,
            color: isDark ? Colors.white : Colors. green.shade700,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.checkYourEmail,
          textAlign: TextAlign. center,
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors. grey.shade400 : Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _emailController.text.trim(),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight. bold,
            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              l10n.login,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: Text(
            'Send again',
            style: TextStyle(
              color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(bool isDark, AppLocalizations l10n) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Back Button
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: isDark ? Colors.white : Colors.black87,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          const SizedBox(height: 8),

          // Icon
          FadeInDown(
            child: Icon(
              Icons.lock_reset,
              size: 80,
              color: isDark ? Colors. blue.shade300 : Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            l10n. resetPassword,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors. white : Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.resetPasswordDesc,
            textAlign: TextAlign. center,
            style: TextStyle(
              fontSize: 16,
              color: isDark ? Colors. grey.shade400 : Colors.grey. shade600,
            ),
          ),
          const SizedBox(height: 32),

          // Error Message
          if (_errorMessage.isNotEmpty)
            Container(
              padding: const EdgeInsets. all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red. shade50,
                borderRadius: BorderRadius.circular(8),
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

          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: l10n.email,
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
                borderRadius: BorderRadius. circular(12),
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
              if (! value.contains('@')) {
                return l10n.invalidEmail;
              }
              return null;
            },
          ),
          const SizedBox(height: 24),

          // Send Reset Link Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _sendResetEmail,
              style: ElevatedButton. styleFrom(
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
                      l10n.sendResetLink,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight. bold,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 16),

          // Back to Login
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              l10n.login,
              style: TextStyle(
                color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}