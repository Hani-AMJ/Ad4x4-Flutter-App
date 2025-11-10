import 'package:flutter/material.dart';
import '../../../../data/models/trip_request_model.dart';

class TripRequestsScreen extends StatefulWidget {
  const TripRequestsScreen({super.key});

  @override
  State<TripRequestsScreen> createState() => _TripRequestsScreenState();
}

class _TripRequestsScreenState extends State<TripRequestsScreen> {
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
      // TODO: Replace with actual API call
      // final repo = ref.read(mainApiRepositoryProvider);
      // final response = await repo.getMemberTripRequests(memberId: currentUserId);
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 800));

      // Sample data
      setState(() {
        _requests = [
          TripRequest(
            id: 1,
            title: 'Al Wathba Fossil Dunes Adventure',
            description: 'Would love to explore the fossil dunes at Al Wathba. Great spot for beginners to intermediate level drivers with interesting geological formations.',
            suggestedLocation: 'Al Wathba Fossil Dunes',
            suggestedDate: DateTime.now().add(const Duration(days: 20)),
            requestedBy: '1',
            requestedByName: 'Hani Al-Mansouri',
            status: TripRequestStatus.pending,
            createdAt: DateTime.now().subtract(const Duration(days: 3)),
          ),
          TripRequest(
            id: 2,
            title: 'Liwa Sunset Photography Trip',
            description: 'Photography-focused trip to Liwa Oasis during golden hour. Perfect for capturing the stunning dune landscapes.',
            suggestedLocation: 'Liwa Oasis',
            suggestedDate: DateTime.now().add(const Duration(days: 35)),
            requestedBy: '1',
            requestedByName: 'Hani Al-Mansouri',
            status: TripRequestStatus.approved,
            createdAt: DateTime.now().subtract(const Duration(days: 12)),
            adminNotes: 'Approved! Marshal Ahmed will lead this trip. Check your notifications for details.',
          ),
          TripRequest(
            id: 3,
            title: 'Night Navigation Challenge - Mleiha',
            description: 'Advanced night driving with GPS navigation challenges. Members can practice their night desert skills in a safe, controlled environment.',
            suggestedLocation: 'Mleiha Desert',
            suggestedDate: DateTime.now().add(const Duration(days: 10)),
            requestedBy: '1',
            requestedByName: 'Hani Al-Mansouri',
            status: TripRequestStatus.declined,
            createdAt: DateTime.now().subtract(const Duration(days: 18)),
            adminNotes: 'Unfortunately we need more marshals for night trips. Please suggest daytime alternatives.',
          ),
          TripRequest(
            id: 4,
            title: 'Family-Friendly Camping Weekend',
            description: 'Two-day camping trip with family activities, BBQ, and easy desert driving routes suitable for all family members.',
            suggestedLocation: 'Sweihan Desert',
            requestedBy: '1',
            requestedByName: 'Hani Al-Mansouri',
            status: TripRequestStatus.converted,
            createdAt: DateTime.now().subtract(const Duration(days: 45)),
            adminNotes: 'Converted to official trip #187! Check Trips page.',
          ),
        ];
        _isLoading = false;
      });
    } catch (e) {
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
        onSubmitted: (title, description, location, date) async {
          // TODO: Submit to API
          // await repo.createTripRequest(...);
          
          // Simulate submission
          await Future.delayed(const Duration(milliseconds: 500));
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Trip request submitted successfully!'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop();
            _loadRequests();
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
                    'Submit your ideas for new trips! Our marshals review all requests and will approve trips that fit the club\'s schedule and safety requirements.\n\nApproved requests will be converted to official trips.',
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
              'Have an idea for a new trip?\nSubmit a request and our marshals will review it!',
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

              // Title
              Text(
                request.title,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                request.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.7),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),

              // Location and Date chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (request.suggestedLocation != null)
                    _InfoChip(
                      icon: Icons.location_on,
                      label: request.suggestedLocation!,
                      colors: colors,
                    ),
                  if (request.suggestedDate != null)
                    _InfoChip(
                      icon: Icons.calendar_today,
                      label: _formatDate(request.suggestedDate!),
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
                request.title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                'Description',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                request.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.8),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),

              // Details
              if (request.suggestedLocation != null) ...[
                _DetailRow(
                  icon: Icons.location_on,
                  label: 'Suggested Location',
                  value: request.suggestedLocation!,
                  colors: colors,
                ),
                const SizedBox(height: 12),
              ],
              if (request.suggestedDate != null) ...[
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Suggested Date',
                  value: _formatFullDate(request.suggestedDate!),
                  colors: colors,
                ),
                const SizedBox(height: 12),
              ],
              _DetailRow(
                icon: Icons.person,
                label: 'Requested By',
                value: request.requestedByName,
                colors: colors,
              ),
              const SizedBox(height: 12),
              _DetailRow(
                icon: Icons.access_time,
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
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
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
    String title,
    String description,
    String? location,
    DateTime? date,
  ) onSubmitted;

  const _RequestTripForm({required this.onSubmitted});

  @override
  State<_RequestTripForm> createState() => _RequestTripFormState();
}

class _RequestTripFormState extends State<_RequestTripForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  DateTime? _selectedDate;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
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

    setState(() => _isSubmitting = true);

    try {
      await widget.onSubmitted(
        _titleController.text,
        _descriptionController.text,
        _locationController.text.isEmpty ? null : _locationController.text,
        _selectedDate,
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
                  'Share your trip idea with our marshals',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),

                // Trip title field
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Trip Title',
                    hintText: 'e.g., Desert Sunset Photography',
                    prefixIcon: Icon(Icons.title),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a trip title';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText:
                        'Describe your trip idea, what makes it special...',
                    prefixIcon: Icon(Icons.description),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a description';
                    }
                    if (value.trim().length < 20) {
                      return 'Description must be at least 20 characters';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),

                // Location field (optional)
                TextFormField(
                  controller: _locationController,
                  decoration: const InputDecoration(
                    labelText: 'Suggested Location (Optional)',
                    hintText: 'e.g., Liwa Desert, Al Wathba',
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                // Date picker (optional)
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Suggested Date (Optional)',
                      prefixIcon: Icon(Icons.calendar_today),
                      suffixIcon: Icon(Icons.arrow_drop_down),
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
