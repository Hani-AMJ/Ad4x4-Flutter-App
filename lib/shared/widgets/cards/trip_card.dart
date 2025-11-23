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
  final bool hasReport; // ✅ NEW: Trip has at least one report
  final bool canCreateReport; // ✅ NEW: User can create report for this trip
  final bool isCompleted; // ✅ NEW: Trip is completed (for report eligibility)
  final bool isEligible; // ✅ NEW: User meets level requirement
  final bool isLocked; // ✅ NEW: User doesn't meet level requirement
  final bool isLead; // ✅ NEW: User is the trip lead

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
    this.hasReport = false, // ✅ NEW: Default no report
    this.canCreateReport = false, // ✅ NEW: Default no permission
    this.isCompleted = false, // ✅ NEW: Default not completed
    this.isEligible = true, // ✅ NEW: Default eligible
    this.isLocked = false, // ✅ NEW: Default not locked
    this.isLead = false, // ✅ NEW: Default not lead
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
            // Image or placeholder with report badge overlay
            Stack(
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
                
                // Report badge overlay (top-right corner)
                if (isCompleted && (hasReport || canCreateReport))
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildReportBadge(context, hasReport, canCreateReport),
                  ),
                
                // ✅ NEW: Eligibility badge overlay (top-left corner)
                if (isLocked)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _buildEligibilityBadge(context),
                  ),
                
                // ✅ NEW: Lead badge overlay (bottom-right corner)
                if (isLead)
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _buildLeadBadge(context),
                  ),
              ],
            ),

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

  /// Build report badge for completed trips
  Widget _buildReportBadge(BuildContext context, bool hasReport, bool canCreate) {
    final theme = Theme.of(context);
    
    if (hasReport) {
      // Green badge: Report available
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.description,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'Report',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    } else if (canCreate) {
      // Blue badge: Can create report
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.blue.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.add_circle_outline,
              size: 14,
              color: Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              'Create Report',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
  
  /// ✅ NEW: Build eligibility badge for locked trips
  Widget _buildEligibilityBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.lock,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Level Required',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
  
  /// ✅ NEW: Build lead badge for trips where user is the lead
  Widget _buildLeadBadge(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star,
            size: 14,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            'Lead',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
