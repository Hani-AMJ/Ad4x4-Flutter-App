import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/meeting_point_constants.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../trips/presentation/providers/meeting_points_provider.dart';

/// Meeting Points Screen - Member view for browsing meeting points
class MeetingPointsScreen extends ConsumerStatefulWidget {
  const MeetingPointsScreen({super.key});

  @override
  ConsumerState<MeetingPointsScreen> createState() => _MeetingPointsScreenState();
}

class _MeetingPointsScreenState extends ConsumerState<MeetingPointsScreen> {
  String _searchQuery = '';
  String? _selectedArea;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final meetingPointsAsync = ref.watch(meetingPointsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Points'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(meetingPointsProvider);
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search meeting points...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Area Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: MeetingPointConstants.allAreaOptions.map((entry) {
                final isSelected = _selectedArea == entry.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(entry.value),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedArea = selected ? entry.key : null;
                      });
                    },
                    backgroundColor: isSelected ? colors.primary.withValues(alpha: 0.2) : null,
                    selectedColor: colors.primary.withValues(alpha: 0.3),
                  ),
                );
              }).toList(),
            ),
          ),
          
          const SizedBox(height: 16),

          // Meeting Points List
          Expanded(
            child: meetingPointsAsync.when(
              data: (meetingPoints) {
                // Apply filters
                final filteredPoints = meetingPoints.where((point) {
                  // Search filter
                  if (_searchQuery.isNotEmpty) {
                    final searchLower = _searchQuery.toLowerCase();
                    final matchesName = point.name.toLowerCase().contains(searchLower);
                    final matchesArea = point.area?.toLowerCase().contains(searchLower) ?? false;
                    if (!matchesName && !matchesArea) return false;
                  }
                  
                  // Area filter
                  if (_selectedArea != null && point.area != _selectedArea) {
                    return false;
                  }
                  
                  return true;
                }).toList();

                if (filteredPoints.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.location_off,
                          size: 64,
                          color: colors.onSurface.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No meeting points found',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isNotEmpty || _selectedArea != null
                              ? 'Try adjusting your filters'
                              : 'No meeting points available',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filteredPoints.length,
                  itemBuilder: (context, index) {
                    final point = filteredPoints[index];
                    return _MeetingPointCard(
                      meetingPoint: point,
                      onTap: () {
                        context.push('/meeting-points/${point.id}', extra: point);
                      },
                    );
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: colors.error,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load meeting points',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      onPressed: () {
                        ref.invalidate(meetingPointsProvider);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Meeting Point Card Widget
class _MeetingPointCard extends StatelessWidget {
  final MeetingPoint meetingPoint;
  final VoidCallback onTap;

  const _MeetingPointCard({
    required this.meetingPoint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Use shared color utility
    final areaColor = MeetingPointConstants.getAreaColor(meetingPoint.area);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Location Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: areaColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.location_on,
                  color: areaColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              
              // Meeting Point Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meetingPoint.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (meetingPoint.area != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: areaColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          meetingPoint.area!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: areaColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (meetingPoint.lat != null && meetingPoint.lon != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.pin_drop,
                            size: 14,
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${meetingPoint.lat}, ${meetingPoint.lon}',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              // Arrow Icon
              Icon(
                Icons.chevron_right,
                color: colors.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
