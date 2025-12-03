import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/trip_request_model.dart';
import '../../../../data/models/level_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/auth_provider_v2.dart';

class TripRequestsScreen extends ConsumerStatefulWidget {
  const TripRequestsScreen({super.key});

  @override
  ConsumerState<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends ConsumerState<TripRequestsScreen> {
  final MainApiRepository _repository = MainApiRepository();
  bool _isLoading = false;
  bool _hasError = false;
  List<TripRequest> _requests = [];

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      // Get current user ID
      final user = ref.read(authProviderV2).user;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 🔍 DEBUG: Log API call details
      print('📡 [TripRequest] Loading requests for member ID: ${user.id}');
      print('   API Endpoint: /api/members/${user.id}/triprequests');

      Map<String, dynamic> response;
      
      try {
        // Try member-specific endpoint first
        response = await _repository.getMemberTripRequests(
          memberId: user.id,
          pageSize: 100,
        );
      } catch (memberEndpointError) {
        // 🔧 WORKAROUND: If member endpoint fails (500 error), 
        // fetch all requests and filter by user
        print('⚠️ [TripRequest] Member endpoint failed, using fallback: $memberEndpointError');
        print('🔄 [TripRequest] Fetching all requests and filtering...');
        
        final allResponse = await _repository.getAllTripRequests(pageSize: 100);
        final allResults = allResponse['results'] as List<dynamic>? ?? [];
        
        // Filter to only this user's requests
        final userResults = allResults.where((json) {
          final memberData = json['member'];
          if (memberData is Map<String, dynamic>) {
            final memberId = memberData['id'];
            return memberId.toString() == user.id.toString();
          }
          return false;
        }).toList();
        
        response = {
          'count': userResults.length,
          'results': userResults,
          'next': null,
          'previous': null,
        };
        
        print('✅ [TripRequest] Fallback successful: Found ${userResults.length} requests for this user');
      }

      // 🔍 DEBUG: Log API response
      print('📥 [TripRequest] API Response received:');
      print('   Response keys: ${response.keys.toList()}');
      print('   Count: ${response['count']}');
      print('   Results length: ${(response['results'] as List?)?.length ?? 0}');

      final results = response['results'] as List<dynamic>? ?? [];
      final requests = results
          .map((json) => TripRequest.fromJson(json as Map<String, dynamic>))
          .toList();

      // Sort by created date (newest first)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      // 🔍 DEBUG: Log parsed requests
      print('✅ [TripRequest] Parsed ${requests.length} requests');

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e) {
      // 🔍 DEBUG: Log error details
      print('❌ [TripRequest] Failed to load requests: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load requests: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  void _showRequestTripDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestTripForm(
        onSubmitted: (date, levelId, timeOfDay, area) async {
          try {
            // 🔍 DEBUG: Log submission data
            print('🚀 [TripRequest] Submitting trip request...');
            print('   Date: $date');
            print('   Level ID: $levelId');
            print('   Time of Day: $timeOfDay');
            print('   Area: $area');
            
            // Submit to API
            final response = await _repository.createTripRequest(
              date: date,
              levelId: levelId,
              timeOfDay: timeOfDay,
              area: area,
            );
            
            // 🔍 DEBUG: Log API response
            print('✅ [TripRequest] API Response:');
            print('   Response: $response');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Trip request submitted successfully!'),
                  backgroundColor: Colors.green,
                ),
              );
              Navigator.of(context).pop();
              
              // 🔍 DEBUG: Log reload attempt
              print('🔄 [TripRequest] Reloading requests list...');
              await _loadRequests();
              print('✅ [TripRequest] Reload complete. Total requests: ${_requests.length}');
            }
          } catch (e) {
            // 🔍 DEBUG: Log error details
            print('❌ [TripRequest] Submission failed: $e');
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to submit request: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('About Trip Requests'),
                  content: const Text(
                    'Request trips by selecting your preferred level, area, time, and date. Our marshals review all requests and will approve trips that fit the club\'s schedule and safety requirements.\n\nApproved requests will be converted to official trips.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Got it'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _hasError
                ? _buildErrorState()
                : _requests.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildRequestsList(colors),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestTripDialog,
        icon: const Icon(Icons.add),
        label: const Text('Request Trip'),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          const Text(
            'Failed to load trip requests',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 80,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Trip Requests',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Want to go on a trip?\nRequest one and our marshals will review it!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: _showRequestTripDialog,
              icon: const Icon(Icons.add),
              label: const Text('Request Your First Trip'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(ColorScheme colors) {
    return RefreshIndicator(
      onRefresh: _loadRequests,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _TripRequestCard(request: request, colors: colors);
        },
      ),
    );
  }
}

class _TripRequestCard extends StatelessWidget {
  final TripRequest request;
  final ColorScheme colors;

  const _TripRequestCard({
    required this.request,
    required this.colors,
  });

  Color _getStatusColor() {
    switch (request.status) {
      case TripRequestStatus.pending:
        return Colors.orange;
      case TripRequestStatus.approved:
        return Colors.green;
      case TripRequestStatus.declined:
        return Colors.red;
      case TripRequestStatus.converted:
        return Colors.blue;
    }
  }

  IconData _getStatusIcon() {
    switch (request.status) {
      case TripRequestStatus.pending:
        return Icons.schedule;
      case TripRequestStatus.approved:
        return Icons.check_circle;
      case TripRequestStatus.declined:
        return Icons.cancel;
      case TripRequestStatus.converted:
        return Icons.done_all;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showRequestDetails(context);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badge and date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getStatusIcon(),
                          size: 14,
                          color: statusColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          request.status.displayName,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(request.createdAt),
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Title (synthesized from level and area)
              Text(
                '${request.level.displayName} in ${request.areaDisplayName}',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 12),

              // Details chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(
                    icon: Icons.location_on,
                    label: request.areaDisplayName,
                    colors: colors,
                  ),
                  _InfoChip(
                    icon: Icons.terrain,
                    label: request.level.shortName,
                    colors: colors,
                  ),
                  if (request.timeOfDay != null)
                    _InfoChip(
                      icon: Icons.access_time,
                      label: request.timeOfDayDisplayName!,
                      colors: colors,
                    ),
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: _formatDate(request.date),
                    colors: colors,
                  ),
                ],
              ),

              // Admin notes (if any)
              if (request.adminNotes != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          request.adminNotes!,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showRequestDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailsSheet(request: request),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${(diff / 7).floor()} weeks ago';

    return '${date.day}/${date.month}/${date.year}';
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final ColorScheme colors;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestDetailsSheet extends StatelessWidget {
  final TripRequest request;

  const _RequestDetailsSheet({required this.request});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                '${request.level.displayName} in ${request.areaDisplayName}',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Details
              _DetailRow(
                icon: Icons.terrain,
                label: 'Trip Level',
                value: request.level.displayName,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.location_on,
                label: 'Area',
                value: request.areaDisplayName,
                colors: colors,
              ),
              const SizedBox(height: 12),
              if (request.timeOfDay != null) ...[
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Preferred Time',
                  value: request.timeOfDayDisplayName!,
                  colors: colors,
                ),
                const SizedBox(height: 12),
              ],
              _DetailRow(
                icon: Icons.calendar_today,
                label: 'Requested Date',
                value: _formatFullDate(request.date),
                colors: colors,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.person,
                label: 'Requested By',
                value: request.memberName,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.schedule,
                label: 'Submitted',
                value: _formatFullDate(request.createdAt),
                colors: colors,
              ),

              // Admin notes
              if (request.adminNotes != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.admin_panel_settings,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Admin Response',
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        request.adminNotes!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.9),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme colors;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: colors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  color: colors.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RequestTripForm extends StatefulWidget {
  final Future<void> Function(
    DateTime date,
    int? levelId,
    String? timeOfDay,
    String? area,
  ) onSubmitted;

  const _RequestTripForm({required this.onSubmitted});

  @override
  State<_RequestTripForm> createState() => _RequestTripFormState();
}

class _RequestTripFormState extends State<_RequestTripForm> {
  final _formKey = GlobalKey<FormState>();
  final MainApiRepository _repository = MainApiRepository();
  
  List<Level> _levels = [];
  bool _loadingLevels = true;
  
  int? _selectedLevelId;
  String? _selectedTimeOfDay;
  String? _selectedArea;
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fetchLevels();
  }

  Future<void> _fetchLevels() async {
    try {
      final results = await _repository.getLevels();
      setState(() {
        _levels = results
            .map((json) => Level.fromJson(json as Map<String, dynamic>))
            .toList();
        _loadingLevels = false;
      });
    } catch (e) {
      print('Failed to fetch levels: $e');
      setState(() {
        _loadingLevels = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a trip date'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmitted(
        _selectedDate!,
        _selectedLevelId,
        _selectedTimeOfDay,
        _selectedArea,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colors.onSurface.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  'Request a New Trip',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your preferences and our marshals will review',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Date picker (REQUIRED)
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Trip Date *',
                      prefixIcon: const Icon(Icons.calendar_today),
                      suffixIcon: const Icon(Icons.arrow_drop_down),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select a date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null
                            ? colors.onSurface.withValues(alpha: 0.5)
                            : colors.onSurface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Level dropdown (Optional)
                if (_loadingLevels)
                  const Center(child: CircularProgressIndicator())
                else
                  DropdownButtonFormField<int>(
                    initialValue: _selectedLevelId,
                    decoration: InputDecoration(
                      labelText: 'Trip Level (Optional)',
                      prefixIcon: const Icon(Icons.terrain),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      helperText: 'Select difficulty level if you have a preference',
                    ),
                    items: _levels.map((level) {
                      return DropdownMenuItem(
                        value: level.id,
                        child: Text(level.displayName),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => _selectedLevelId = value),
                  ),
                const SizedBox(height: 16),

                // Time of Day dropdown (Optional)
                DropdownButtonFormField<String>(
                  initialValue: _selectedTimeOfDay,
                  decoration: InputDecoration(
                    labelText: 'Time of Day (Optional)',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'When would you prefer the trip?',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'MOR', child: Text('Morning')),
                    DropdownMenuItem(value: 'MID', child: Text('Mid-day')),
                    DropdownMenuItem(value: 'AFT', child: Text('Afternoon')),
                    DropdownMenuItem(value: 'EVE', child: Text('Evening')),
                    DropdownMenuItem(value: 'ANY', child: Text('Any Time')),
                  ],
                  onChanged: (value) => setState(() => _selectedTimeOfDay = value),
                ),
                const SizedBox(height: 16),

                // Area dropdown (Optional)
                DropdownButtonFormField<String>(
                  initialValue: _selectedArea,
                  decoration: InputDecoration(
                    labelText: 'Area (Optional)',
                    prefixIcon: const Icon(Icons.location_on),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    helperText: 'Preferred trip area',
                  ),
                  items: const [
                    DropdownMenuItem(value: 'DXB', child: Text('Dubai')),
                    DropdownMenuItem(value: 'NOR', child: Text('Northern Emirates')),
                    DropdownMenuItem(value: 'AUH', child: Text('Abu Dhabi')),
                    DropdownMenuItem(value: 'AAN', child: Text('Al Ain')),
                    DropdownMenuItem(value: 'LIW', child: Text('Liwa')),
                  ],
                  onChanged: (value) => setState(() => _selectedArea = value),
                ),
                const SizedBox(height: 24),

                // Info text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 20, color: colors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only the date is required. Optional fields help marshals plan better trips.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Submit button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSubmitting ? null : _submit,
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Submit Request'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
