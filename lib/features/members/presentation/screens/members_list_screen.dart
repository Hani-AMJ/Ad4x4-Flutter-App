import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/utils/level_display_helper.dart';
import 'dart:async';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({super.key});

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _repository = MainApiRepository();
  final _searchController = TextEditingController();
  Timer? _debounceTimer;
  
  List<UserModel> _members = [];
  bool _isLoading = true;
  bool _isSearching = false;
  String? _error;
  
  // Pagination
  int _currentPage = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  // ✅ NEW: Advanced Filters
  String? _selectedCarBrand;
  String? _selectedCity;
  String? _selectedNationality;
  String? _selectedLevel;
  int? _minTripCount;
  int? _maxTripCount;
  int? _minCarYear;
  int? _maxCarYear;
  bool _hasActiveFilters = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Load members from API
  Future<void> _loadMembers({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      print('📋 [Members] Fetching page $_currentPage...');
      
      final response = await _repository.getMembers(
        page: _currentPage,
        pageSize: 20,
        firstNameContains: _searchController.text.isNotEmpty ? _searchController.text : null,
        // ✅ NEW: Apply advanced filters
        carBrand: _selectedCarBrand,
        city: _selectedCity,
        nationality: _selectedNationality,
        levelName: _selectedLevel,
        tripCountRange: _buildTripCountRange(),
        carYearRange: _buildCarYearRange(),
      );

      // Parse response
      final List<UserModel> newMembers = [];
      final data = response['data'] ?? response['results'] ?? response;
      
      if (data is List) {
        for (var item in data) {
          try {
            newMembers.add(UserModel.fromJson(item as Map<String, dynamic>));
          } catch (e) {
            print('⚠️ [Members] Error parsing member: $e');
          }
        }
      }

      print('✅ [Members] Loaded ${newMembers.length} members');

      setState(() {
        if (isLoadMore) {
          _members.addAll(newMembers);
        } else {
          _members = newMembers;
        }
        _isLoading = false;
        _isSearching = false;
        _hasMore = newMembers.length >= 20;  // Has more if we got a full page
      });
    } catch (e) {
      print('❌ [Members] Error: $e');
      setState(() {
        _error = 'Failed to load members';
        _isLoading = false;
        _isSearching = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load members: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Scroll listener for pagination
  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore && !_isSearching) {
        _currentPage++;
        _loadMembers(isLoadMore: true);
      }
    }
  }

  /// Handle search with debounce
  void _onSearchChanged(String query) {
    setState(() => _isSearching = true);
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _currentPage = 1;
      _loadMembers();
    });
  }

  /// Clear search
  void _clearSearch() {
    _searchController.clear();
    _currentPage = 1;
    _loadMembers();
  }

  // ✅ NEW: Build trip count range string
  String? _buildTripCountRange() {
    if (_minTripCount == null && _maxTripCount == null) return null;
    final min = _minTripCount ?? '';
    final max = _maxTripCount ?? '';
    return '$min,$max';
  }

  // ✅ NEW: Build car year range string
  String? _buildCarYearRange() {
    if (_minCarYear == null && _maxCarYear == null) return null;
    final min = _minCarYear ?? '';
    final max = _maxCarYear ?? '';
    return '$min,$max';
  }

  // ✅ NEW: Show filter bottom sheet
  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _FilterBottomSheet(
        selectedCarBrand: _selectedCarBrand,
        selectedCity: _selectedCity,
        selectedNationality: _selectedNationality,
        selectedLevel: _selectedLevel,
        minTripCount: _minTripCount,
        maxTripCount: _maxTripCount,
        minCarYear: _minCarYear,
        maxCarYear: _maxCarYear,
        onApply: (filters) {
          setState(() {
            _selectedCarBrand = filters['carBrand'];
            _selectedCity = filters['city'];
            _selectedNationality = filters['nationality'];
            _selectedLevel = filters['level'];
            _minTripCount = filters['minTripCount'];
            _maxTripCount = filters['maxTripCount'];
            _minCarYear = filters['minCarYear'];
            _maxCarYear = filters['maxCarYear'];
            _hasActiveFilters = _selectedCarBrand != null ||
                _selectedCity != null ||
                _selectedNationality != null ||
                _selectedLevel != null ||
                _minTripCount != null ||
                _maxTripCount != null ||
                _minCarYear != null ||
                _maxCarYear != null;
            _currentPage = 1;
          });
          _loadMembers();
        },
      ),
    );
  }

  // ✅ NEW: Clear all filters
  void _clearFilters() {
    setState(() {
      _selectedCarBrand = null;
      _selectedCity = null;
      _selectedNationality = null;
      _selectedLevel = null;
      _minTripCount = null;
      _maxTripCount = null;
      _minCarYear = null;
      _maxCarYear = null;
      _hasActiveFilters = false;
      _currentPage = 1;
    });
    _loadMembers();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          // ✅ NEW: Filter button with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: _showFilterSheet,
              ),
              if (_hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _currentPage = 1;
              _loadMembers();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search members by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: colors.surfaceContainerHighest,
              ),
            ),
          ),

          // ✅ NEW: Active Filters Chips
          if (_hasActiveFilters)
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  if (_selectedCarBrand != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Car: $_selectedCarBrand'),
                        onDeleted: () {
                          setState(() => _selectedCarBrand = null);
                          _currentPage = 1;
                          _loadMembers();
                        },
                      ),
                    ),
                  if (_selectedLevel != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('Level: $_selectedLevel'),
                        onDeleted: () {
                          setState(() => _selectedLevel = null);
                          _currentPage = 1;
                          _loadMembers();
                        },
                      ),
                    ),
                  if (_selectedCity != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text('City: $_selectedCity'),
                        onDeleted: () {
                          setState(() => _selectedCity = null);
                          _currentPage = 1;
                          _loadMembers();
                        },
                      ),
                    ),
                  if (_minTripCount != null || _maxTripCount != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Chip(
                        label: Text(
                          'Trips: ${_minTripCount ?? "0"}-${_maxTripCount ?? "∞"}',
                        ),
                        onDeleted: () {
                          setState(() {
                            _minTripCount = null;
                            _maxTripCount = null;
                          });
                          _currentPage = 1;
                          _loadMembers();
                        },
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: ActionChip(
                      label: const Text('Clear All'),
                      onPressed: _clearFilters,
                      avatar: const Icon(Icons.clear, size: 18),
                    ),
                  ),
                ],
              ),
            ),

          // Loading Indicator (first load)
          if (_isLoading && _members.isEmpty)
            const Expanded(
              child: LoadingIndicator(message: 'Loading members...'),
            ),

          // Error State
          if (_error != null && _members.isEmpty)
            Expanded(
              child: ErrorState(
                message: _error!,
                onRetry: () {
                  _currentPage = 1;
                  _loadMembers();
                },
              ),
            ),

          // Members List
          if (!_isLoading || _members.isNotEmpty)
            Expanded(
              child: _members.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      title: 'No Members Found',
                      message: _searchController.text.isNotEmpty
                          ? 'No members match your search'
                          : 'No members available',
                    )
                  : RefreshIndicator(
                      onRefresh: () async {
                        _currentPage = 1;
                        await _loadMembers();
                      },
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _members.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          // Loading indicator at bottom
                          if (index == _members.length) {
                            return const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }

                          final member = _members[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _MemberCard(
                              member: member,
                              onTap: () => context.push('/members/${member.id}'),
                            ),
                          );
                        },
                      ),
                    ),
            ),
        ],
      ),
    );
  }
}

/// Enhanced Member Card Widget
class _MemberCard extends StatelessWidget {
  final UserModel member;
  final VoidCallback onTap;

  const _MemberCard({
    required this.member,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    final memberName = '${member.firstName} ${member.lastName}'.trim();

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Avatar
              UserAvatar(
                name: memberName,
                imageUrl: member.avatar != null && member.avatar!.isNotEmpty
                    ? (member.avatar!.startsWith('http')
                        ? member.avatar
                        : 'https://media.ad4x4.com${member.avatar}')
                    : null,
                radius: 30,
              ),
              const SizedBox(width: 16),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name
                    Text(
                      memberName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Level + Stats
                    Row(
                      children: [
                        // Level Badge - using centralized helper for UserLevel
                        if (member.level != null)
                          LevelDisplayHelper.buildCompactBadgeFromString(
                            levelName: member.level!.displayName ?? member.level!.name,
                            numericLevel: member.level!.numericLevel,
                          ),
                        
                        const SizedBox(width: 8),

                        // Trip Count
                        Icon(
                          Icons.directions_car,
                          size: 14,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${member.tripCount ?? 0} trips',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
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

/// ✅ NEW: Filter Bottom Sheet Widget
class _FilterBottomSheet extends StatefulWidget {
  final String? selectedCarBrand;
  final String? selectedCity;
  final String? selectedNationality;
  final String? selectedLevel;
  final int? minTripCount;
  final int? maxTripCount;
  final int? minCarYear;
  final int? maxCarYear;
  final Function(Map<String, dynamic>) onApply;

  const _FilterBottomSheet({
    required this.selectedCarBrand,
    required this.selectedCity,
    required this.selectedNationality,
    required this.selectedLevel,
    required this.minTripCount,
    required this.maxTripCount,
    required this.minCarYear,
    required this.maxCarYear,
    required this.onApply,
  });

  @override
  State<_FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<_FilterBottomSheet> {
  late String? _carBrand;
  late String? _city;
  late String? _nationality;
  late String? _level;
  late TextEditingController _minTripController;
  late TextEditingController _maxTripController;
  late TextEditingController _minYearController;
  late TextEditingController _maxYearController;

  // Popular car brands for AD4x4
  final List<String> _popularCarBrands = [
    'Land Rover',
    'Toyota',
    'Nissan',
    'Jeep',
    'Ford',
    'Chevrolet',
    'GMC',
    'Mitsubishi',
  ];

  // UAE cities
  final List<String> _popularCities = [
    'Dubai',
    'Abu Dhabi',
    'Sharjah',
    'Ajman',
    'Ras Al Khaimah',
    'Fujairah',
    'Umm Al Quwain',
    'Al Ain',
  ];

  // Common levels
  final List<String> _levels = [
    'Newbie',
    'Member',
    'Intermediate',
    'Advanced',
    'Explorer',
    'Marshal',
  ];

  @override
  void initState() {
    super.initState();
    _carBrand = widget.selectedCarBrand;
    _city = widget.selectedCity;
    _nationality = widget.selectedNationality;
    _level = widget.selectedLevel;
    _minTripController = TextEditingController(
      text: widget.minTripCount?.toString() ?? '',
    );
    _maxTripController = TextEditingController(
      text: widget.maxTripCount?.toString() ?? '',
    );
    _minYearController = TextEditingController(
      text: widget.minCarYear?.toString() ?? '',
    );
    _maxYearController = TextEditingController(
      text: widget.maxCarYear?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _minTripController.dispose();
    _maxTripController.dispose();
    _minYearController.dispose();
    _maxYearController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = <String, dynamic>{
      'carBrand': _carBrand,
      'city': _city,
      'nationality': _nationality,
      'level': _level,
      'minTripCount': _minTripController.text.isNotEmpty
          ? int.tryParse(_minTripController.text)
          : null,
      'maxTripCount': _maxTripController.text.isNotEmpty
          ? int.tryParse(_maxTripController.text)
          : null,
      'minCarYear': _minYearController.text.isNotEmpty
          ? int.tryParse(_minYearController.text)
          : null,
      'maxCarYear': _maxYearController.text.isNotEmpty
          ? int.tryParse(_maxYearController.text)
          : null,
    };
    widget.onApply(filters);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colors.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Filter Members',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _carBrand = null;
                          _city = null;
                          _nationality = null;
                          _level = null;
                          _minTripController.clear();
                          _maxTripController.clear();
                          _minYearController.clear();
                          _maxYearController.clear();
                        });
                      },
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ),

              // Filters Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Car Brand
                    Text(
                      'Car Brand',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularCarBrands.map((brand) {
                        final isSelected = _carBrand == brand;
                        return FilterChip(
                          label: Text(brand),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _carBrand = selected ? brand : null;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Level
                    Text(
                      'Member Level',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _levels.map((level) {
                        final isSelected = _level == level;
                        return FilterChip(
                          label: Text(level),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _level = selected ? level : null;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // City
                    Text(
                      'City',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _popularCities.map((city) {
                        final isSelected = _city == city;
                        return FilterChip(
                          label: Text(city),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              _city = selected ? city : null;
                            });
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: 24),

                    // Trip Count Range
                    Text(
                      'Trip Count',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minTripController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              border: OutlineInputBorder(),
                              hintText: '0',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('to'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxTripController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              border: OutlineInputBorder(),
                              hintText: '∞',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Car Year Range
                    Text(
                      'Car Year',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minYearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Min',
                              border: OutlineInputBorder(),
                              hintText: '2000',
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('to'),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _maxYearController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Max',
                              border: OutlineInputBorder(),
                              hintText: '2025',
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Apply Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: colors.outlineVariant,
                      width: 1,
                    ),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _applyFilters,
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
