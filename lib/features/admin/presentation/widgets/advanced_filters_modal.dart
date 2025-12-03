import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../providers/admin_trips_search_provider.dart';
import '../../../trips/presentation/providers/levels_provider.dart';
import 'trip_lead_autocomplete.dart';
import 'package:intl/intl.dart';

/// Advanced Filters Modal
/// 
/// Full-screen modal for selecting advanced search filters
/// Shows as bottom sheet on mobile, dialog on desktop
class AdvancedFiltersModal extends ConsumerStatefulWidget {
  const AdvancedFiltersModal({super.key});

  @override
  ConsumerState<AdvancedFiltersModal> createState() => _AdvancedFiltersModalState();
}

class _AdvancedFiltersModalState extends ConsumerState<AdvancedFiltersModal> {
  // Local state for filter selections (not applied until user clicks "Apply")
  DateTime? _dateFrom;
  DateTime? _dateTo;
  List<int> _selectedLevels = [];
  String? _leadUsername;
  String? _meetingPointArea;

  @override
  void initState() {
    super.initState();
    // Initialize with current criteria
    final criteria = ref.read(adminTripsSearchProvider).criteria;
    _dateFrom = criteria.dateFrom;
    _dateTo = criteria.dateTo;
    _selectedLevels = List.from(criteria.levelIds);
    _leadUsername = criteria.leadUsername;
    _meetingPointArea = criteria.meetingPointArea;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 900;

    return Container(
      height: size.height * 0.9, // 90% of screen height
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Header with title and close button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(Icons.tune, color: colors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Advanced Filters',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.primary,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Close',
                ),
              ],
            ),
          ),

          // Scrollable filters content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Range Section
                  _buildSectionHeader(context, '📅 Date Range'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _DateField(
                          label: 'From',
                          date: _dateFrom,
                          onChanged: (date) => setState(() => _dateFrom = date),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DateField(
                          label: 'To',
                          date: _dateTo,
                          onChanged: (date) => setState(() => _dateTo = date),
                        ),
                      ),
                    ],
                  ),
                  if (_dateFrom != null || _dateTo != null) ...[
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _dateFrom = null;
                          _dateTo = null;
                        });
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('Clear dates'),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Difficulty Levels Section
                  _buildSectionHeader(context, '🏔️ Difficulty Levels'),
                  const SizedBox(height: 12),
                  _buildLevelSelector(),
                  if (_selectedLevels.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => setState(() => _selectedLevels.clear()),
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text('Clear levels'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          onPressed: () {
                            final levelsAsync = ref.read(levelsProvider);
                            levelsAsync.whenData((levels) {
                              setState(() {
                                _selectedLevels = levels.map((l) => l.id).toList();
                              });
                            });
                          },
                          icon: const Icon(Icons.select_all, size: 16),
                          label: const Text('Select all'),
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 24),

                  // Trip Lead Section
                  _buildSectionHeader(context, '👤 Trip Lead'),
                  const SizedBox(height: 12),
                  TripLeadAutocomplete(
                    initialValue: _leadUsername,
                    onSelected: (username) => setState(() => _leadUsername = username),
                  ),
                  const SizedBox(height: 24),

                  // Location Section
                  _buildSectionHeader(context, '📍 Location'),
                  const SizedBox(height: 12),
                  _buildAreaDropdown(),
                  const SizedBox(height: 24),

                  // Summary of selected filters
                  if (_hasFilters) ...[
                    const Divider(),
                    const SizedBox(height: 16),
                    Text(
                      'Active Filters Summary',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFiltersSummary(context),
                  ],
                ],
              ),
            ),
          ),

          // Bottom action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  // Clear all button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hasFilters
                          ? () {
                              setState(() {
                                _dateFrom = null;
                                _dateTo = null;
                                _selectedLevels.clear();
                                _leadUsername = null;
                                _meetingPointArea = null;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.clear_all),
                      label: const Text('Clear All'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Apply filters button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Filters'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildLevelSelector() {
    // ✅ Load actual levels from database
    final levelsAsync = ref.watch(levelsProvider);

    return levelsAsync.when(
      data: (levels) {
        if (levels.isEmpty) {
          return const Text('No levels available', style: TextStyle(color: Colors.grey));
        }

        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: levels.map((level) {
            final isSelected = _selectedLevels.contains(level.id);
            // ✅ Using centralized helper for consistent icons and colors
            final color = LevelDisplayHelper.getLevelColor(level.numericLevel);
            final icon = LevelDisplayHelper.getLevelIcon(level.numericLevel);
            
            return FilterChip(
              selected: isSelected,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 16, color: color),
                  const SizedBox(width: 6),
                  Text(level.name), // ✅ Show actual name (Club Event, Newbie, etc.)
                ],
              ),
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedLevels.add(level.id);
                  } else {
                    _selectedLevels.remove(level.id);
                  }
                });
              },
              backgroundColor: color.withValues(alpha: 0.1),
              selectedColor: color.withValues(alpha: 0.25),
              checkmarkColor: color,
              side: BorderSide(
                color: isSelected ? color : color.withValues(alpha: 0.5),
                width: isSelected ? 2 : 1,
              ),
              labelStyle: TextStyle(
                color: Colors.white,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            );
          }).toList(),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stack) => Text(
        'Error loading levels: $error',
        style: const TextStyle(color: Colors.red),
      ),
    );
  }

  Widget _buildAreaDropdown() {
    const areas = [
      'DXB', // Dubai
      'AUH', // Abu Dhabi
      'NOR', // Northern Emirates
      'AAN', // Al Ain
      'LIW', // Liwa
    ];

    return DropdownButtonFormField<String>(
      initialValue: _meetingPointArea,
      decoration: InputDecoration(
        labelText: 'Meeting Point Area',
        hintText: 'All areas',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.location_on),
      ),
      items: [
        const DropdownMenuItem<String>(
          value: null,
          child: Text('All areas'),
        ),
        ...areas.map((area) {
          return DropdownMenuItem<String>(
            value: area,
            child: Text(area),
          );
        }),
      ],
      onChanged: (value) {
        setState(() {
          _meetingPointArea = value;
        });
      },
    );
  }

  Widget _buildFiltersSummary(BuildContext context) {
    final theme = Theme.of(context);
    final chips = <Widget>[];

    if (_dateFrom != null || _dateTo != null) {
      final dateFormat = DateFormat('MMM dd, yyyy');
      final fromStr = _dateFrom != null ? dateFormat.format(_dateFrom!) : '...';
      final toStr = _dateTo != null ? dateFormat.format(_dateTo!) : '...';
      chips.add(Chip(
        label: Text('$fromStr - $toStr'),
        avatar: const Icon(Icons.date_range, size: 16),
        visualDensity: VisualDensity.compact,
      ));
    }

    if (_selectedLevels.isNotEmpty) {
      chips.add(Chip(
        label: Text('${_selectedLevels.length} Level${_selectedLevels.length > 1 ? 's' : ''}'),
        avatar: const Icon(Icons.terrain, size: 16),
        visualDensity: VisualDensity.compact,
      ));
    }

    if (_leadUsername != null) {
      chips.add(Chip(
        label: Text(_leadUsername!),
        avatar: const Icon(Icons.person, size: 16),
        visualDensity: VisualDensity.compact,
      ));
    }

    if (_meetingPointArea != null) {
      chips.add(Chip(
        label: Text(_meetingPointArea!),
        avatar: const Icon(Icons.location_on, size: 16),
        visualDensity: VisualDensity.compact,
      ));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  bool get _hasFilters =>
      _dateFrom != null ||
      _dateTo != null ||
      _selectedLevels.isNotEmpty ||
      _leadUsername != null ||
      _meetingPointArea != null;

  void _applyFilters() {
    // Apply all filters at once
    final newCriteria = ref.read(adminTripsSearchProvider).criteria.copyWith(
          dateFrom: _dateFrom,
          dateTo: _dateTo,
          levelIds: _selectedLevels,
          leadUsername: _leadUsername,
          meetingPointArea: _meetingPointArea,
        );

    // Execute search with new criteria
    ref.read(adminTripsSearchProvider.notifier).updateCriteria(newCriteria);

    // Close modal
    Navigator.of(context).pop();
  }
}

/// Date Field Widget
class _DateField extends StatelessWidget {
  final String label;
  final DateTime? date;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    this.date,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime(2030),
        );
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          suffixIcon: date != null
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 20),
                  onPressed: () => onChanged(null),
                )
              : const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(
          date != null ? dateFormat.format(date!) : 'Select date',
          style: TextStyle(
            color: date != null ? null : Theme.of(context).hintColor,
          ),
        ),
      ),
    );
  }
}
