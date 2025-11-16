import 'package:flutter/material.dart';
import '../../../data/models/vehicle_modifications_model.dart';

/// Verification Method Selection Dialog
/// 
/// Shown before submitting vehicle modifications.
/// Member chooses between On-Trip or Expedited verification.

class VerificationMethodDialog extends StatefulWidget {
  const VerificationMethodDialog({super.key});

  @override
  State<VerificationMethodDialog> createState() => _VerificationMethodDialogState();
}

class _VerificationMethodDialogState extends State<VerificationMethodDialog> {
  VerificationType _selectedType = VerificationType.onTrip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      title: const Text('Choose Verification Method'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your modifications must be verified by a Marshal before they become active. Choose your preferred verification method:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // On-Trip Verification Option
            _VerificationMethodCard(
              type: VerificationType.onTrip,
              isSelected: _selectedType == VerificationType.onTrip,
              onTap: () => setState(() => _selectedType = VerificationType.onTrip),
              icon: Icons.directions_car,
              title: 'On-Trip Verification',
              subtitle: 'Standard method (Free)',
              description: '• Marshal will inspect your vehicle on your next trip\n'
                  '• Visual verification during trip check-in\n'
                  '• No rush, take your time\n'
                  '• Completely free of charge',
              estimatedTime: 'Verified on next trip',
              color: Colors.blue,
            ),
            const SizedBox(height: 16),

            // Expedited Verification Option
            _VerificationMethodCard(
              type: VerificationType.expedited,
              isSelected: _selectedType == VerificationType.expedited,
              onTap: () => setState(() => _selectedType = VerificationType.expedited),
              icon: Icons.bolt,
              title: 'Expedited Online Verification',
              subtitle: 'Faster approval',
              description: '• Marshal will contact you for online verification\n'
                  '• Submit photos/videos of modifications\n'
                  '• Faster approval (within 48 hours)\n'
                  '• May require video call for confirmation',
              estimatedTime: 'Within 48 hours',
              color: Colors.purple,
            ),
            const SizedBox(height: 20),

            // Important note
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_outlined, color: colors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You cannot register for trips with vehicle requirements until your modifications are verified.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.8),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _selectedType),
          child: const Text('Confirm'),
        ),
      ],
    );
  }
}

/// Verification Method Card (Selection Option)
class _VerificationMethodCard extends StatelessWidget {
  final VerificationType type;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String estimatedTime;
  final Color color;

  const _VerificationMethodCard({
    required this.type,
    required this.isSelected,
    required this.onTap,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.estimatedTime,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? color : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and radio
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? color : null,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Radio<VerificationType>(
                    value: type,
                    groupValue: isSelected ? type : null,
                    onChanged: (_) => onTap(),
                    activeColor: color,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 12),

              // Estimated time
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(
                    'Estimated: $estimatedTime',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show verification method dialog
/// 
/// Returns selected VerificationType or null if cancelled
Future<VerificationType?> showVerificationMethodDialog(BuildContext context) {
  return showDialog<VerificationType>(
    context: context,
    builder: (context) => const VerificationMethodDialog(),
  );
}
