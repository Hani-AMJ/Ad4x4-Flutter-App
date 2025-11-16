import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Vehicle Requirement Dialogs
/// 
/// Various dialogs shown during trip registration when vehicle requirements
/// are not met or modifications are pending verification.

/// Dialog: Requirements Not Met
/// 
/// Shows when member's vehicle doesn't meet trip requirements
class RequirementsNotMetDialog extends StatelessWidget {
  final List<String> unmetRequirements;
  final int vehicleId;

  const RequirementsNotMetDialog({
    super.key,
    required this.unmetRequirements,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.block, color: Colors.red),
          SizedBox(width: 8),
          Expanded(child: Text('Vehicle Requirements Not Met')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your vehicle does not meet the minimum requirements for this trip:',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ...unmetRequirements.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.close, color: Colors.red, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Update your vehicle modifications to meet these requirements.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
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
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to edit vehicle modifications
            context.push('/vehicles/$vehicleId/edit-modifications');
          },
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Update Vehicle'),
        ),
      ],
    );
  }
}

/// Dialog: Modifications Pending Verification
/// 
/// Shows when member has submitted mods but they're not yet verified
class ModificationsPendingDialog extends StatelessWidget {
  final String verificationType;
  final int vehicleId;

  const ModificationsPendingDialog({
    super.key,
    required this.verificationType,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isExpedited = verificationType.toLowerCase().contains('expedited');

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.pending_outlined, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(child: Text('Modifications Pending Verification')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your vehicle modifications are awaiting marshal verification.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  isExpedited ? Icons.bolt : Icons.directions_car,
                  color: isExpedited ? Colors.purple : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isExpedited
                        ? 'Expedited Verification: A marshal will contact you within 48 hours'
                        : 'On-Trip Verification: Will be verified on your next trip',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Registration Blocked',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'You cannot register for this trip until your modifications are verified.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ),
            if (!isExpedited) ...[
              const SizedBox(height: 16),
              Text(
                'Need faster verification?',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can request expedited online verification to get approved within 48 hours.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        if (!isExpedited)
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to vehicle edit to change verification type
              context.push('/vehicles/$vehicleId/edit-modifications');
            },
            icon: const Icon(Icons.bolt, size: 18),
            label: const Text('Request Expedited'),
          )
        else
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to contact marshal or support
            },
            icon: const Icon(Icons.chat, size: 18),
            label: const Text('Contact Marshal'),
          ),
      ],
    );
  }
}

/// Dialog: No Modifications Recorded
/// 
/// Shows when member hasn't recorded any vehicle modifications
class NoModificationsDialog extends StatelessWidget {
  final List<String> requiredMods;
  final int vehicleId;

  const NoModificationsDialog({
    super.key,
    required this.requiredMods,
    required this.vehicleId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue),
          SizedBox(width: 8),
          Expanded(child: Text('Vehicle Modifications Required')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This trip requires specific vehicle modifications.',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Required modifications:',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            ...requiredMods.map((req) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: Colors.blue.shade700, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      req,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            )),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'What to do:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '1. Add your vehicle modifications to your profile\n'
                    '2. Choose verification method (On-Trip or Expedited)\n'
                    '3. Wait for marshal verification\n'
                    '4. Once verified, you can register for this trip',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      height: 1.5,
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
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            // Navigate to add vehicle modifications
            context.push('/vehicles/$vehicleId/edit-modifications');
          },
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Add Modifications'),
        ),
      ],
    );
  }
}

/// Helper functions to show dialogs

Future<void> showRequirementsNotMetDialog(
  BuildContext context, {
  required List<String> unmetRequirements,
  required int vehicleId,
}) {
  return showDialog(
    context: context,
    builder: (context) => RequirementsNotMetDialog(
      unmetRequirements: unmetRequirements,
      vehicleId: vehicleId,
    ),
  );
}

Future<void> showModificationsPendingDialog(
  BuildContext context, {
  required String verificationType,
  required int vehicleId,
}) {
  return showDialog(
    context: context,
    builder: (context) => ModificationsPendingDialog(
      verificationType: verificationType,
      vehicleId: vehicleId,
    ),
  );
}

Future<void> showNoModificationsDialog(
  BuildContext context, {
  required List<String> requiredMods,
  required int vehicleId,
}) {
  return showDialog(
    context: context,
    builder: (context) => NoModificationsDialog(
      requiredMods: requiredMods,
      vehicleId: vehicleId,
    ),
  );
}
