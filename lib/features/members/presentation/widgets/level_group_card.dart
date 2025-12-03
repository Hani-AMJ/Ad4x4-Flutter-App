import 'package:flutter/material.dart';
import '../../../../data/models/member_level_stats.dart';
import '../../../../core/utils/level_display_helper.dart';

/// Level Group Card Widget
/// 
/// Displays a beautiful card representing a member level group.
/// Shows level name, icon, member count, and uses consistent colors
/// from LevelDisplayHelper for visual consistency across the app.
/// 
/// Features:
/// - Gradient background with level color
/// - Level icon in colored container
/// - Member count display
/// - Tap to navigate to filtered member list
class LevelGroupCard extends StatelessWidget {
  final MemberLevelStats stats;
  final VoidCallback onTap;

  const LevelGroupCard({
    super.key,
    required this.stats,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = LevelDisplayHelper.getLevelColor(stats.numericLevel);
    final icon = LevelDisplayHelper.getLevelIcon(stats.numericLevel);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                color.withValues(alpha: 0.12),
                color.withValues(alpha: 0.04),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.25),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              // Level Icon - Smaller
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 14),
              
              // Level Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stats.displayName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${stats.memberCount} members',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Arrow Icon - Smaller
              Icon(
                Icons.arrow_forward_ios,
                color: color.withValues(alpha: 0.6),
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
