import 'package:flutter/material.dart';
import '../../../core/utils/image_proxy.dart';

/// Card for displaying trip information
class TripCard extends StatelessWidget {
  final String title;
  final String date;
  final String? location;
  final String difficulty;
  final int participants;
  final int maxParticipants;
  final String? imageUrl;
  final VoidCallback? onTap;
  final bool isJoined;

  const TripCard({
    super.key,
    required this.title,
    required this.date,
    this.location,
    required this.difficulty,
    required this.participants,
    required this.maxParticipants,
    this.imageUrl,
    this.onTap,
    this.isJoined = false,
  });

  Color _getDifficultyColor() {
    switch (difficulty.toLowerCase()) {
      case 'anit':
        return const Color(0xFF4CAF50); // Green for ANIT (first-timers)
      case 'easy':
        return const Color(0xFF42B883); // Green for Newbie
      case 'medium':
        return const Color(0xFFFFC107); // Amber
      case 'hard':
        return const Color(0xFFFF9800); // Orange
      case 'expert':
        return const Color(0xFFE53935); // Red
      default:
        return const Color(0xFF64B5F6);
    }
  }

  int _getStarCount() {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return 1;
      case 'medium':
        return 2;
      case 'hard':
        return 3;
      case 'expert':
        return 4;
      default:
        return 1;
    }
  }
  
  bool _isANIT() {
    // Check if this is ANIT level (use specific identifier)
    return difficulty.toLowerCase() == 'anit';
  }
  
  IconData _getDifficultyIcon() {
    if (_isANIT()) {
      return Icons.school; // Graduation cap for learning/first-timers
    }
    return Icons.star; // Stars for other levels
  }

  String _getLevelText() {
    switch (difficulty.toLowerCase()) {
      case 'anit':
        return 'ANIT';
      case 'easy':
        return 'Newbie';
      case 'medium':
        return 'Intermediate';
      case 'hard':
        return 'Advanced';
      case 'expert':
        return 'Expert';
      default:
        return difficulty.toUpperCase();
    }
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
                ImageProxy.getProxiedUrl(imageUrl),
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
                      // Difficulty badge with stars or ANIT icon
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getDifficultyColor().withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // ANIT icon or Star icons
                            if (_isANIT())
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  _getDifficultyIcon(),
                                  size: 14,
                                  color: _getDifficultyColor(),
                                ),
                              )
                            else
                              ...List.generate(_getStarCount(), (index) => Padding(
                                padding: EdgeInsets.only(right: index < _getStarCount() - 1 ? 2 : 6),
                                child: Icon(
                                  Icons.star,
                                  size: 14,
                                  color: _getDifficultyColor(),
                                ),
                              )),
                            // Level text
                            Text(
                              _getLevelText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _getDifficultyColor(),
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
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

                      if (isJoined) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'Joined',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
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
