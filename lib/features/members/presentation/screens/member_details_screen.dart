import 'package:flutter/material.dart';
import '../../../../shared/widgets/widgets.dart';

class MemberDetailsScreen extends StatelessWidget {
  final String memberId;

  const MemberDetailsScreen({super.key, required this.memberId});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // TODO: Fetch actual member data
    const memberName = 'Hani Al-Mansouri';
    const memberRole = 'Marshal';
    const memberSince = '2020';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Member Profile'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.2),
                    colors.surface,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Column(
                children: [
                  const UserAvatar(name: memberName, radius: 60),
                  const SizedBox(height: 16),
                  Text(
                    memberName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      memberRole,
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Member since $memberSince',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),

            // Stats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const InfoCard(
                    icon: Icons.directions_car,
                    title: 'Total Trips',
                    subtitle: '24 trips completed',
                  ),
                  const SizedBox(height: 12),
                  const InfoCard(
                    icon: Icons.photo_library,
                    title: 'Photos Shared',
                    subtitle: '156 photos',
                  ),
                  const SizedBox(height: 12),
                  const InfoCard(
                    icon: Icons.local_fire_department,
                    title: 'Club Points',
                    subtitle: '1,240 points',
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
