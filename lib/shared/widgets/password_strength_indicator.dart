import 'package:flutter/material.dart';
import '../../core/utils/password_validator.dart';

/// Visual password strength indicator widget
/// 
/// Shows:
/// - Strength bar (color-coded)
/// - Strength label (Very Weak to Very Strong)
/// - Requirement checklist with checkmarks
class PasswordStrengthIndicator extends StatelessWidget {
  final String password;
  final String? username;
  final String? email;

  const PasswordStrengthIndicator({
    super.key,
    required this.password,
    this.username,
    this.email,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Don't show anything if password is empty
    if (password.isEmpty) {
      return const SizedBox.shrink();
    }

    final strength = PasswordValidator.getStrength(
      password,
      username: username,
      email: email,
    );
    final strengthLabel = PasswordValidator.getStrengthLabel(strength);
    final errors = PasswordValidator.validate(
      password,
      username: username,
      email: email,
    );

    // Get color based on strength
    Color strengthColor;
    if (strength <= 1) {
      strengthColor = Colors.red;
    } else if (strength == 2) {
      strengthColor = Colors.orange;
    } else if (strength == 3) {
      strengthColor = Colors.amber;
    } else if (strength == 4) {
      strengthColor = Colors.lightGreen;
    } else {
      strengthColor = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Strength bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: strength / 5,
                  backgroundColor: colors.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                  minHeight: 8,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              strengthLabel,
              style: TextStyle(
                color: strengthColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Requirements checklist
        _buildRequirementsList(theme, colors, errors),
      ],
    );
  }

  Widget _buildRequirementsList(
    ThemeData theme,
    ColorScheme colors,
    List<String> errors,
  ) {
    // All requirements
    final requirements = [
      'At least 8 characters',
      'One uppercase letter',
      'One lowercase letter',
      'One number',
      'One special character',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Password Requirements:',
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 8),
        ...requirements.map((requirement) {
          final isMet = !errors.contains(requirement);
          return _buildRequirementItem(
            theme,
            colors,
            PasswordValidator.getRequirementText(requirement),
            isMet,
          );
        }),
      ],
    );
  }

  Widget _buildRequirementItem(
    ThemeData theme,
    ColorScheme colors,
    String text,
    bool isMet,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: isMet ? Colors.green : colors.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isMet
                    ? colors.onSurface.withValues(alpha: 0.8)
                    : colors.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
