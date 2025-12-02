import 'package:flutter/material.dart';
import '../../../data/models/sponsor_model.dart';

/// Sponsor Detail Dialog
/// 
/// Displays full sponsor information including logo, description,
/// and additional details in a modal dialog
class SponsorDetailDialog extends StatelessWidget {
  final Sponsor sponsor;

  const SponsorDetailDialog({
    super.key,
    required this.sponsor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with close button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.business_rounded,
                    color: colors.primary,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Sponsor Details',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: colors.onPrimaryContainer),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Sponsor Logo
                    Center(
                      child: Container(
                        constraints: const BoxConstraints(
                          maxHeight: 200,
                          maxWidth: 400,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            sponsor.image,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                height: 150,
                                color: colors.surfaceContainerHighest,
                                child: Icon(
                                  Icons.business,
                                  size: 64,
                                  color: colors.onSurfaceVariant,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Sponsor Title
                    Text(
                      sponsor.title,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description Label
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 20,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'About',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Sponsor Description
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.outlineVariant,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        sponsor.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.6,
                          color: colors.onSurface,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Thank you message
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: colors.primary.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.favorite,
                            color: colors.primary,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Thank you for supporting AD4x4 Off-Road Club!',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Footer with close button
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Close'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
