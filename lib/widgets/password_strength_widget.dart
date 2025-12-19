import 'package:flutter/material.dart';

class PasswordStrengthWidget extends StatelessWidget {
  final String password;
  final bool isDark;

  const PasswordStrengthWidget({
    super.key,
    required this. password,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final strength = _calculateStrength(password);
    final strengthInfo = _getStrengthInfo(strength);

    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        // Strength Bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength,
                  minHeight: 6,
                  backgroundColor: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(strengthInfo.color),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthInfo.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: strengthInfo.color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Requirements Checklist
        _buildRequirements(),
      ],
    );
  }

  double _calculateStrength(String password) {
    if (password.isEmpty) return 0;

    double strength = 0;
    
    // Length checks
    if (password.length >= 6) strength += 0.2;
    if (password.length >= 8) strength += 0.1;
    if (password.length >= 12) strength += 0.1;

    // Character type checks
    if (password.contains(RegExp(r'[a-z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[A-Z]'))) strength += 0.15;
    if (password.contains(RegExp(r'[0-9]'))) strength += 0.15;
    if (password.contains(RegExp(r'[! @#$%^&*(),.?":{}|<>]'))) strength += 0.15;

    return strength. clamp(0.0, 1.0);
  }

  _StrengthInfo _getStrengthInfo(double strength) {
    if (strength < 0.3) {
      return _StrengthInfo('Weak', Colors.red);
    } else if (strength < 0.5) {
      return _StrengthInfo('Fair', Colors.orange);
    } else if (strength < 0.7) {
      return _StrengthInfo('Good', Colors.yellow. shade700);
    } else if (strength < 0.9) {
      return _StrengthInfo('Strong', Colors.lightGreen);
    } else {
      return _StrengthInfo('Very Strong', Colors.green);
    }
  }

  Widget _buildRequirements() {
    final requirements = [
      _Requirement('At least 6 characters', password.length >= 6),
      _Requirement('Lowercase letter (a-z)', password.contains(RegExp(r'[a-z]'))),
      _Requirement('Uppercase letter (A-Z)', password.contains(RegExp(r'[A-Z]'))),
      _Requirement('Number (0-9)', password. contains(RegExp(r'[0-9]'))),
      _Requirement('Special character (!@#\$... )', password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: requirements.map((req) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              req.isMet ? Icons.check_circle : Icons.circle_outlined,
              size: 14,
              color: req.isMet ? Colors.green : (isDark ? Colors.grey. shade500 : Colors.grey.shade400),
            ),
            const SizedBox(width: 4),
            Text(
              req.text,
              style: TextStyle(
                fontSize: 11,
                color: req.isMet 
                    ? Colors.green 
                    : (isDark ?  Colors.grey.shade400 : Colors.grey.shade600),
              ),
            ),
            const SizedBox(width: 8),
          ],
        );
      }).toList(),
    );
  }
}

class _StrengthInfo {
  final String label;
  final Color color;

  _StrengthInfo(this.label, this. color);
}

class _Requirement {
  final String text;
  final bool isMet;

  _Requirement(this. text, this.isMet);
}