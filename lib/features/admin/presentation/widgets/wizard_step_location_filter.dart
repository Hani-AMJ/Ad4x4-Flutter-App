import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../providers/admin_wizard_provider.dart';

/// Wizard Step 4: Location Filter (Optional)
/// 
/// Mobile-optimized location selection for filtering trips by area
class WizardStepLocationFilter extends ConsumerStatefulWidget {
  const WizardStepLocationFilter({super.key});

  @override
  ConsumerState<WizardStepLocationFilter> createState() =>
      _WizardStepLocationFilterState();
}

class _WizardStepLocationFilterState
    extends ConsumerState<WizardStepLocationFilter> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<MeetingPoint>? _meetingPoints;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadMeetingPoints();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeetingPoints() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final pointsData = await repository.getMeetingPoints();

      final points = pointsData
          .map((json) => MeetingPoint.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by area name (handle nullable area)
      points.sort((a, b) {
        final aArea = a.area ?? '';
        final bArea = b.area ?? '';
        return aArea.compareTo(bArea);
      });

      setState(() {
        _meetingPoints = points;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  /// Get unique areas with meeting point counts
  Map<String, int> get _areaGroups {
    if (_meetingPoints == null) return {};

    final areas = <String, int>{};
    for (final point in _meetingPoints!) {
      final area = point.area ?? 'Unknown';
      areas[area] = (areas[area] ?? 0) + 1;
    }
    return areas;
  }

  List<String> get _filteredAreas {
    final areas = _areaGroups.keys.toList();
    if (_searchQuery.isEmpty) return areas;

    final query = _searchQuery.toLowerCase();
    return areas.where((area) => area.toLowerCase().contains(query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wizardState = ref.watch(adminWizardProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isTablet = size.width >= 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Padding(
          padding: EdgeInsets.all(isTablet ? 24 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter by location',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Optional: Select a city or meeting point area',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),

        // All Locations option
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: FilterChip(
            label: const Text('All Locations'),
            selected: wizardState.meetingPointArea == null,
            onSelected: (selected) {
              if (selected) {
                ref.read(adminWizardProvider.notifier).setAreaFilter(null);
              }
            },
          ),
        ),
        const SizedBox(height: 16),

        // Search bar
        Padding(
          padding: EdgeInsets.symmetric(horizontal: isTablet ? 24 : 16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by city or area...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
          ),
        ),
        const SizedBox(height: 16),

        // Areas list
        Expanded(
          child: _buildAreasList(),
        ),
      ],
    );
  }

  Widget _buildAreasList() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading locations'),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadMeetingPoints,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final filteredAreas = _filteredAreas;
    final areaGroups = _areaGroups;

    if (filteredAreas.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No locations found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    final wizardState = ref.watch(adminWizardProvider);

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: filteredAreas.length,
      itemBuilder: (context, index) {
        final area = filteredAreas[index];
        final pointCount = areaGroups[area] ?? 0;
        final isSelected = wizardState.meetingPointArea == area;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: isSelected ? 4 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.location_on,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            title: Text(
              area,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
            subtitle: Text(
              '$pointCount meeting point${pointCount == 1 ? '' : 's'}',
              style: TextStyle(
                color:
                    Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            trailing: isSelected
                ? Icon(
                    Icons.check_circle,
                    color: Theme.of(context).colorScheme.primary,
                  )
                : Icon(
                    Icons.chevron_right,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.3),
                  ),
            onTap: () {
              if (isSelected) {
                ref.read(adminWizardProvider.notifier).setAreaFilter(null);
              } else {
                ref.read(adminWizardProvider.notifier).setAreaFilter(area);
              }
            },
          ),
        );
      },
    );
  }
}
