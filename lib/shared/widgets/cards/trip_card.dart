import 'package:flutter/material.dart';
import '../../../core/utils/level_display_helper.dart';

/// Card for displaying trip information
class TripCard extends StatelessWidget {
  final String title;
  final String date;
  final String? location;
  final String difficulty;
  final int? levelNumeric; // ✅ NEW: Numeric level for icon/color mapping
  final int participants;
  final int maxParticipants;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isJoined;
  final bool isWaitlisted;

  const TripCard({
    super.key,
    required this.title,
    required this.date,
    this.location,
    required this.difficulty,
    this.levelNumeric, // ✅ NEW: Optional numeric level
    required this.participants,
    required this.maxParticipants,
    this.imageUrl,
    this.onTap,
    this.isJoined = false,
    this.isWaitlisted = false,
  });

  // Get icon and color using LevelDisplayHelper
  ({IconData icon, Color color}) _getLevelIconAndColor() {
    // Use levelNumeric if provided (preferred)
    if (levelNumeric != null) {
      return (
        icon: LevelDisplayHelper.getLevelIcon(levelNumeric!),
        color: LevelDisplayHelper.getLevelColor(levelNumeric!)
      );
    }
    
    // Fallback: use default values if numericLevel not available
    return (icon: Icons.terrain, color: const Color(0xFF64B5F6));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image or placeholder
            if (imageUrl != null)
              Image.network(
                imageUrl!,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder(colors);
                },
              )
            else
              _buildImagePlaceholder(colors),

            // Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),

                  // Date
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        date,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Location
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location ?? 'Location TBA',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Footer: Difficulty, Participants, Status
                  Row(
                    children: [
                      // Difficulty badge with level-specific icon and color
                      Builder(
                        builder: (context) {
                          final levelData = _getLevelIconAndColor();
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: levelData.color.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Level-specific icon
                                Icon(
                                  levelData.icon,
                                  size: 16,
                                  color: levelData.color,
                                ),
                                const SizedBox(width: 6),
                                // Level text
                                Text(
                                  difficulty,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: levelData.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const Spacer(),

                      // Participants
                      Icon(
                        Icons.people,
                        size: 16,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$participants/$maxParticipants',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),

                      // Show Registered or Waitlisted badge
                      if (isJoined) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.green, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 12, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Registered',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (isWaitlisted) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.orange, width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.schedule, size: 12, color: Colors.orange),
                              const SizedBox(width: 4),
                              Text(
                                'Waitlisted',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder(ColorScheme colors) {
    return Container(
      height: 160,
      width: double.infinity,
      color: colors.surfaceContainerHighest,
      child: Icon(
        Icons.terrain,
        size: 64,
        color: colors.onSurface.withValues(alpha: 0.3),
      ),
    );
  }
}
