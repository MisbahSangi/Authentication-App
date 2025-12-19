import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/theme_provider.dart';
import '../services/two_factor_service.dart';

class TwoFactorSetupScreen extends StatefulWidget {
  const TwoFactorSetupScreen({super.key});

  @override
  State<TwoFactorSetupScreen> createState() => _TwoFactorSetupScreenState();
}

class _TwoFactorSetupScreenState extends State<TwoFactorSetupScreen> {
  final _twoFactorService = TwoFactorService();
  final _codeController = TextEditingController();
  final _auth = FirebaseAuth. instance;

  String _secretKey = '';
  String _qrData = '';
  List<String> _backupCodes = [];
  int _currentStep = 0;
  bool _isLoading = false;
  String _errorMessage = '';
  String _debugInfo = '';

  @override
  void initState() {
    super.initState();
    _generateSecret();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super. dispose();
  }

  void _generateSecret() {
    final email = _auth.currentUser?.email ??  '';
    _secretKey = _twoFactorService.generateSecretKey();
    _qrData = _twoFactorService. generateQRCodeData(_secretKey, email);
    _backupCodes = _twoFactorService.generateBackupCodes();
    setState(() {});
  }

  Future<void> _verifyAndEnable() async {
    final code = _codeController.text. trim(). replaceAll(' ', '');

    if (code.length != 6) {
      setState(() {
        _errorMessage = 'Please enter a 6-digit code';
      });
      return;
    }

    // Check if code contains only digits
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      setState(() {
        _errorMessage = 'Code must contain only numbers';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _debugInfo = '';
    });

    try {
      // Generate current expected code for debugging
      final expectedCode = _twoFactorService.generateTOTP(_secretKey);

      final isValid = _twoFactorService.verifyTOTP(_secretKey, code);

      if (isValid) {
        await _twoFactorService.enable2FA(_secretKey);
        await _twoFactorService.saveBackupCodes(_backupCodes);
        setState(() {
          _currentStep = 2;
        });
      } else {
        setState(() {
          _errorMessage = 'Invalid code. Please try again.';
          _debugInfo = 'Expected: $expectedCode (may vary due to time)';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context). showSnackBar(
      const SnackBar(content: Text('Copied to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider. of<ThemeProvider>(context);
    final isDark = themeProvider. isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup 2FA'),
        backgroundColor: isDark ? Colors.grey. shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [Colors.grey.shade900, Colors.grey.shade800]
                : [Colors.grey.shade100, Colors.white],
          ),
        ),
        child: Stepper(
          currentStep: _currentStep,
          onStepContinue: () {
            if (_currentStep == 0) {
              setState(() => _currentStep = 1);
            } else if (_currentStep == 1) {
              _verifyAndEnable();
            } else {
              Navigator.pop(context, true);
            }
          },
          onStepCancel: () {
            if (_currentStep > 0 && _currentStep < 2) {
              setState(() => _currentStep--);
            } else {
              Navigator.pop(context);
            }
          },
          controlsBuilder: (context, details) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  ElevatedButton(
                    onPressed: _isLoading ? null : details.onStepContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : Text(_currentStep == 2 ? 'Done' : 'Continue'),
                  ),
                  if (_currentStep < 2) ...[
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: details.onStepCancel,
                      child: const Text('Back'),
                    ),
                  ],
                ],
              ),
            );
          },
          steps: [
            // Step 1: Scan QR Code
            Step(
              title: const Text('Scan QR Code'),
              subtitle: const Text('Use your authenticator app'),
              isActive: _currentStep >= 0,
              state: _currentStep > 0 ? StepState.complete : StepState. indexed,
              content: Column(
                children: [
                  const Text(
                    'Scan this QR code with your authenticator app (Google Authenticator, Authy, etc. )',
                    textAlign: TextAlign. center,
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius. circular(12),
                    ),
                    child: QrImageView(
                      data: _qrData,
                      version: QrVersions.auto,
                      size: 200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Or enter this code manually:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                      borderRadius: BorderRadius. circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: SelectableText(
                            _secretKey,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 14,
                              fontWeight: FontWeight. bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.copy),
                          onPressed: () => _copyToClipboard(_secretKey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Step 2: Verify Code
            Step(
              title: const Text('Verify Code'),
              subtitle: const Text('Enter the code from your app'),
              isActive: _currentStep >= 1,
              state: _currentStep > 1 ?  StepState.complete : StepState. indexed,
              content: Column(
                children: [
                  const Text(
                    'Enter the 6-digit code from your authenticator app to verify setup.',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign. center,
                    style: TextStyle(
                      fontSize: 24,
                      letterSpacing: 8,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                    decoration: InputDecoration(
                      hintText: '000000',
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: isDark ? Colors.grey. shade700 : Colors.white,
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red. shade50,
                        borderRadius: BorderRadius. circular(8),
                        border: Border.all(color: Colors. red.shade200),
                      ),
                      child: Column(
                        children: [
                          Row(
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
                          if (_debugInfo.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              _debugInfo,
                              style: TextStyle(
                                color: Colors.red.shade400,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Make sure your device time is accurate',
                    style: TextStyle(
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            // Step 3: Save Backup Codes
            Step(
              title: const Text('Save Backup Codes'),
              subtitle: const Text('Keep these safe! '),
              isActive: _currentStep >= 2,
              state: _currentStep > 2 ?  StepState.complete : StepState. indexed,
              content: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors. green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '2FA has been enabled successfully! ',
                            style: TextStyle(color: Colors.green. shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Save these backup codes in a safe place.  You can use them to access your account if you lose your authenticator device.',
                    textAlign: TextAlign. center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey.shade700 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _backupCodes. map((code) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade600 : Colors.white,
                                borderRadius: BorderRadius. circular(4),
                              ),
                              child: Text(
                                code,
                                style: const TextStyle(fontFamily: 'monospace'),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 12),
                        TextButton. icon(
                          onPressed: () => _copyToClipboard(_backupCodes. join('\n')),
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy All Codes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}