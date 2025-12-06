import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/level_model.dart';
import '../../../../core/providers/repository_providers.dart';

/// Trip Search Autocomplete Widget
/// 
/// Interactive search field for finding trips with:
/// - Real-time search as you type (debounced)
/// - Default display of 5 most recent trips
/// - Search by title only (fast and focused)
/// - Optional level and date range filters
/// - Material Design 3 styling
/// 
/// Usage:
/// ```dart
/// TripSearchAutocomplete(
///   initialTripId: selectedTripId,
///   onTripSelected: (trip) => setState(() => _selectedTripId = trip?.id),
///   showFilters: true, // Optional level and date filters
/// )
/// ```
class TripSearchAutocomplete extends ConsumerStatefulWidget {
  final int? initialTripId;
  final ValueChanged<Trip?> onTripSelected;
  final String? approvalStatus;
  final bool showFilters;
  final String? hintText;

  const TripSearchAutocomplete({
    super.key,
    this.initialTripId,
    required this.onTripSelected,
    this.approvalStatus = 'A', // Default: approved trips only
    this.showFilters = false,
    this.hintText,
  });

  @override
  ConsumerState<TripSearchAutocomplete> createState() => _TripSearchAutocompleteState();
}

class _TripSearchAutocompleteState extends ConsumerState<TripSearchAutocomplete> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  Timer? _debounceTimer;
  List<Trip> _recentTrips = [];
  List<Trip> _searchResults = [];
  Trip? _selectedTrip;
  bool _isLoading = false;
  bool _showOptions = false;
  String? _errorMessage;
  
  // Available levels from API
  List<Level> _availableLevels = [];
  
  // Filter states
  int? _selectedLevelId;
  DateTime? _startDateFrom;
  DateTime? _startDateTo;

  @override
  void initState() {
    super.initState();
    
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecentTrips();
      _loadAvailableLevels();
      if (widget.initialTripId != null) {
        _loadInitialTrip(widget.initialTripId!);
      }
    });

    // Listen for focus changes
    _focusNode.addListener(() {
      if (_focusNode.hasFocus && _searchController.text.isEmpty) {
        setState(() => _showOptions = true);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Load available levels from API
  Future<void> _loadAvailableLevels() async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final levelsList = await repository.getLevels();
      
      final levels = levelsList
          .map((json) => Level.fromJson(json as Map<String, dynamic>))
          .where((level) => level.active)  // Only active levels
          .toList();
      
      if (mounted) {
        setState(() => _availableLevels = levels);
      }
    } catch (e) {
      // Silently fail - filter will just show no levels
    }
  }

  /// Load 5 most recent trips for default display
  Future<void> _loadRecentTrips() async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getTrips(
        approvalStatus: widget.approvalStatus,
        ordering: '-start_time', // ✅ Newest first by registration start date
        pageSize: 5,
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final trips = results.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();

      if (mounted) {
        setState(() {
          _recentTrips = trips;
          if (_searchController.text.isEmpty) {
            _searchResults = trips;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load recent trips';
        });
      }
    }
  }

  /// Load initial trip by ID (for pre-selection)
  Future<void> _loadInitialTrip(int tripId) async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final response = await repository.getTripDetail(tripId);
      final trip = Trip.fromJson(response);

      if (mounted) {
        setState(() {
          _selectedTrip = trip;
          _searchController.text = trip.title;
        });
      }
    } catch (e) {
      // Silently fail - trip might not exist
    }
  }

  /// Search trips with debouncing (300ms delay)
  void _onSearchChanged(String query) {
    // Cancel previous timer
    _debounceTimer?.cancel();

    // Clear results if query too short
    if (query.length < 3) {
      setState(() {
        _searchResults = _recentTrips;
        _showOptions = true;
        _isLoading = false;
      });
      return;
    }

    // Show loading
    setState(() {
      _isLoading = true;
      _showOptions = true;
    });

    // Debounce: wait 300ms after user stops typing
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      _performSearch(query);
    });
  }

  /// Perform actual search via API
  Future<void> _performSearch(String query) async {
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Build query parameters
      final response = await repository.getTrips(
        search: query, // ✅ Search title only (backend optimized)
        approvalStatus: widget.approvalStatus,
        ordering: '-start_time', // ✅ Always newest first
        pageSize: 20, // ✅ 20 results per search
        // Apply filters if set
        levelId: _selectedLevelId,
        startTimeAfter: _startDateFrom?.toIso8601String(),
        startTimeBefore: _startDateTo?.toIso8601String(),
      );

      final results = response['results'] as List<dynamic>? ?? [];
      final trips = results.map((json) => Trip.fromJson(json as Map<String, dynamic>)).toList();

      if (mounted) {
        setState(() {
          _searchResults = trips;
          _isLoading = false;
          _errorMessage = trips.isEmpty ? 'No trips found matching "$query"' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Search failed. Please try again.';
        });
      }
    }
  }

  /// Handle trip selection
  void _onTripSelected(Trip trip) {
    setState(() {
      _selectedTrip = trip;
      _searchController.text = trip.title;
      _showOptions = false;
    });
    
    _focusNode.unfocus();
    widget.onTripSelected(trip);
  }

  /// Clear selection
  void _clearSelection() {
    setState(() {
      _selectedTrip = null;
      _searchController.clear();
      _searchResults = _recentTrips;
      _showOptions = false;
    });
    
    widget.onTripSelected(null);
  }

  /// Show filter dialog
  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _FilterDialog(
        initialLevelId: _selectedLevelId,
        initialStartDateFrom: _startDateFrom,
        initialStartDateTo: _startDateTo,
        availableLevels: _availableLevels,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLevelId = result['levelId'] as int?;
        _startDateFrom = result['startDateFrom'] as DateTime?;
        _startDateTo = result['startDateTo'] as DateTime?;
      });

      // Re-run search with filters
      if (_searchController.text.length >= 3) {
        _performSearch(_searchController.text);
      } else {
        _loadRecentTrips();
      }
    }
  }

  /// Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedLevelId = null;
      _startDateFrom = null;
      _startDateTo = null;
    });

    // Reload data
    if (_searchController.text.length >= 3) {
      _performSearch(_searchController.text);
    } else {
      _loadRecentTrips();
    }
  }

  /// Check if any filters are active
  bool get _hasActiveFilters =>
      _selectedLevelId != null || _startDateFrom != null || _startDateTo != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search field
        TextField(
          controller: _searchController,
          focusNode: _focusNode,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Search trips by title...',
            helperText: _selectedTrip == null
                ? 'Start typing to search or select from recent trips'
                : null,
            prefixIcon: const Icon(Icons.search),
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Filter button
                if (widget.showFilters)
                  IconButton(
                    icon: Badge(
                      isLabelVisible: _hasActiveFilters,
                      child: const Icon(Icons.filter_list),
                    ),
                    tooltip: 'Filters',
                    onPressed: _showFilterDialog,
                  ),
                // Clear button
                if (_searchController.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    tooltip: 'Clear',
                    onPressed: _clearSelection,
                  ),
              ],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: _onSearchChanged,
          onTap: () {
            setState(() => _showOptions = true);
          },
        ),

        // Active filters chips
        if (_hasActiveFilters)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(
              spacing: 8,
              children: [
                if (_selectedLevelId != null)
                  Chip(
                    label: Text(
                      'Level: ${_availableLevels.firstWhere(
                        (l) => l.id == _selectedLevelId,
                        orElse: () => Level(id: 0, name: 'Unknown', numericLevel: 0),
                      ).displayName}',
                    ),
                    onDeleted: () {
                      setState(() => _selectedLevelId = null);
                      _performSearch(_searchController.text);
                    },
                  ),
                if (_startDateFrom != null || _startDateTo != null)
                  Chip(
                    label: Text(
                      'Date: ${_startDateFrom != null ? DateFormat('MMM d').format(_startDateFrom!) : '...'} - ${_startDateTo != null ? DateFormat('MMM d').format(_startDateTo!) : '...'}',
                    ),
                    onDeleted: () {
                      setState(() {
                        _startDateFrom = null;
                        _startDateTo = null;
                      });
                      _performSearch(_searchController.text);
                    },
                  ),
                TextButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.clear_all, size: 16),
                  label: const Text('Clear all'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: const Size(0, 32),
                  ),
                ),
              ],
            ),
          ),

        // Options dropdown
        if (_showOptions && !_focusNode.hasFocus)
          Container()
        else if (_showOptions)
          _buildOptionsPanel(theme, colors),
      ],
    );
  }

  /// Build options panel with search results or recent trips
  Widget _buildOptionsPanel(ThemeData theme, ColorScheme colors) {
    return Card(
      margin: const EdgeInsets.only(top: 8),
      elevation: 4,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        child: _isLoading
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            : _errorMessage != null && _searchResults.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.search_off, size: 48, color: colors.outline),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage!,
                            style: theme.textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(8),
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Text(
                          _searchController.text.isEmpty
                              ? '📅 Recent Trips (5 newest)'
                              : '🔍 Search Results (${_searchResults.length})',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const Divider(height: 1),
                      
                      // Trip list
                      ..._searchResults.map((trip) => _buildTripOption(trip, theme, colors)),
                      
                      // Footer helper text
                      if (_searchController.text.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            '💡 Tip: Type at least 3 characters to search all trips',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.outline,
                              fontStyle: FontStyle.italic,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
      ),
    );
  }

  /// Build individual trip option
  Widget _buildTripOption(Trip trip, ThemeData theme, ColorScheme colors) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isSelected = _selectedTrip?.id == trip.id;

    return ListTile(
      selected: isSelected,
      leading: CircleAvatar(
        backgroundColor: isSelected ? colors.primary : colors.primaryContainer,
        child: Icon(
          Icons.directions_car,
          color: isSelected ? colors.onPrimary : colors.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        trip.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text(
        '#${trip.id} • ${dateFormat.format(trip.startTime)} • ${trip.registeredCount}/${trip.capacity} registered',
        style: theme.textTheme.bodySmall,
      ),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: colors.primary)
          : null,
      onTap: () => _onTripSelected(trip),
    );
  }
}

/// Filter Dialog for Level and Date Range
class _FilterDialog extends StatefulWidget {
  final int? initialLevelId;
  final DateTime? initialStartDateFrom;
  final DateTime? initialStartDateTo;
  final List<Level> availableLevels;

  const _FilterDialog({
    this.initialLevelId,
    this.initialStartDateFrom,
    this.initialStartDateTo,
    required this.availableLevels,
  });

  @override
  State<_FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<_FilterDialog> {
  int? _levelId;
  DateTime? _startDateFrom;
  DateTime? _startDateTo;

  @override
  void initState() {
    super.initState();
    _levelId = widget.initialLevelId;
    _startDateFrom = widget.initialStartDateFrom;
    _startDateTo = widget.initialStartDateTo;
  }

  Future<void> _selectDate(bool isFrom) async {
    final initialDate = isFrom ? _startDateFrom : _startDateTo;
    final firstDate = DateTime(2020);
    final lastDate = DateTime(2030);

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate,
      lastDate: lastDate,
    );

    if (picked != null) {
      setState(() {
        if (isFrom) {
          _startDateFrom = picked;
        } else {
          _startDateTo = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM d, yyyy');

    return AlertDialog(
      title: const Text('Filter Trips'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level filter
            Text('Trip Level', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<int>(
              initialValue: _levelId,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'All levels',
                isDense: true,
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('All levels'),
                ),
                ...widget.availableLevels.map((level) {
                  return DropdownMenuItem<int>(
                    value: level.id,
                    child: Text(level.displayName),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _levelId = value);
              },
            ),

            const SizedBox(height: 24),

            // Date range filter
            Text('Date Range', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(true),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDateFrom != null
                          ? dateFormat.format(_startDateFrom!)
                          : 'From date',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _selectDate(false),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _startDateTo != null
                          ? dateFormat.format(_startDateTo!)
                          : 'To date',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            setState(() {
              _levelId = null;
              _startDateFrom = null;
              _startDateTo = null;
            });
          },
          child: const Text('Clear All'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context, {
              'levelId': _levelId,
              'startDateFrom': _startDateFrom,
              'startDateTo': _startDateTo,
            });
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
