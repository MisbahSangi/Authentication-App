import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/two_factor_service.dart';
import 'home_screen.dart';

class TwoFactorVerifyScreen extends StatefulWidget {
  final String email;
  final String password;

  const TwoFactorVerifyScreen({
    super.key,
    required this. email,
    required this.password,
  });

  @override
  State<TwoFactorVerifyScreen> createState() => _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends State<TwoFactorVerifyScreen> {
  final _codeController = TextEditingController();
  final _twoFactorService = TwoFactorService();

  bool _isLoading = false;
  bool _useBackupCode = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _codeController.dispose();
    super. dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text. trim();
    
    if (_useBackupCode) {
      if (code.length != 8) {
        setState(() {
          _errorMessage = 'Please enter an 8-digit backup code';
        });
        return;
      }
    } else {
      if (code.length != 6) {
        setState(() {
          _errorMessage = 'Please enter a 6-digit code';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      bool isValid = false;

      if (_useBackupCode) {
        isValid = await _twoFactorService. verifyBackupCode(code);
      } else {
        final secret = await _twoFactorService.getSecretByEmail(widget.email);
        if (secret != null) {
          isValid = _twoFactorService.verifyTOTP(secret, code);
        }
      }

      if (isValid) {
        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } else {
        setState(() {
          _errorMessage = _useBackupCode
              ? 'Invalid backup code. Please try again.'
              : 'Invalid code. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Verification failed. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider. isDarkMode;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment. topCenter,
            end: Alignment. bottomCenter,
            colors: isDark
                ? [Colors. grey.shade900, Colors.grey.shade800, Colors.grey.shade700]
                : [Colors.blue.shade700, Colors.blue.shade500, Colors.blue. shade300],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Card(
                elevation: 8,
                color: isDark ? Colors.grey.shade800 : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius. circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize. min,
                    children: [
                      Icon(
                        Icons.security,
                        size: 80,
                        color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Two-Factor Authentication',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight. bold,
                          color: isDark ?  Colors.white : Colors.blue.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _useBackupCode
                            ? 'Enter one of your backup codes'
                            : 'Enter the code from your authenticator app',
                        textAlign: TextAlign. center,
                        style: TextStyle(
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Code Input
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        maxLength: _useBackupCode ?  8 : 6,
                        textAlign: TextAlign. center,
                        style: TextStyle(
                          fontSize: 24,
                          letterSpacing: 8,
                          color: isDark ?  Colors.white : Colors.black,
                        ),
                        decoration: InputDecoration(
                          hintText: _useBackupCode ? '00000000' : '000000',
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius. circular(12),
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
                      ),
                      const SizedBox(height: 16),

                      // Error Message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius. circular(8),
                            border: Border.all(color: Colors.red.shade200),
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

                      // Verify Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCode,
                          style: ElevatedButton. styleFrom(
                            backgroundColor: Colors. blue.shade700,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius. circular(12),
                            ),
                          ),
                          child: _isLoading
                              ?  const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors. white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Verify',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Toggle Backup Code
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _useBackupCode = !_useBackupCode;
                            _codeController.clear();
                            _errorMessage = '';
                          });
                        },
                        child: Text(
                          _useBackupCode
                              ? 'Use authenticator app instead'
                              : 'Use a backup code instead',
                          style: TextStyle(
                            color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          ),
                        ),
                      ),

                      // Back to Login
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}