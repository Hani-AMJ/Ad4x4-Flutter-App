import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/logbook_provider.dart';

/// Admin Trip Reports Screen
/// 
/// Create, view, edit, and delete post-trip marshal reports
/// Accessible by users with create_trip_report permission
class AdminTripReportsScreen extends ConsumerStatefulWidget {
  final int? preSelectedTripId;
  
  const AdminTripReportsScreen({super.key, this.preSelectedTripId});

  @override
  ConsumerState<AdminTripReportsScreen> createState() =>
      _AdminTripReportsScreenState();
}

class _AdminTripReportsScreenState
    extends ConsumerState<AdminTripReportsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _reportController = TextEditingController();
  final _safetyNotesController = TextEditingController();
  final _weatherController = TextEditingController();
  final _terrainController = TextEditingController();
  final _participantCountController = TextEditingController();
  
  int? _selectedTripId;
  List<Map<String, dynamic>> _trips = [];
  final List<String> _issues = [];
  final TextEditingController _issueController = TextEditingController();
  
  bool _isLoadingTrips = true;
  bool _isSubmitting = false;
  bool _showForm = false;
  
  // Edit mode
  TripReport? _editingReport;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load trip reports
      ref.read(tripReportsProvider.notifier).loadReports();
      
      // Load trips first, THEN set pre-selected trip
      await _loadTrips();
      
      // ✅ Pre-select trip AFTER trips are loaded AND mounted check
      if (mounted && widget.preSelectedTripId != null) {
        setState(() {
          _selectedTripId = widget.preSelectedTripId;
          _showForm = true; // Automatically show form
        });
      }
    });
  }

  @override
  void dispose() {
    _reportController.dispose();
    _safetyNotesController.dispose();
    _weatherController.dispose();
    _terrainController.dispose();
    _participantCountController.dispose();
    _issueController.dispose();
    super.dispose();
  }

  Future<void> _loadTrips() async {
    setState(() => _isLoadingTrips = true);
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripsResponse = await repository.getTrips(page: 1, pageSize: 50);
      final tripsList = (tripsResponse['results'] as List<dynamic>?)
          ?.map((t) => t as Map<String, dynamic>)
          .toList() ?? [];
      
      setState(() {
        _trips = tripsList;
        _isLoadingTrips = false;
      });
    } catch (e) {
      setState(() => _isLoadingTrips = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load trips: $e')),
        );
      }
    }
  }

  void _resetForm() {
    setState(() {
      _showForm = false;
      _editingReport = null;
      _selectedTripId = null;
      _issues.clear();
    });
    _formKey.currentState?.reset();
    _reportController.clear();
    _safetyNotesController.clear();
    _weatherController.clear();
    _terrainController.clear();
    _participantCountController.clear();
  }

  void _editReport(TripReport report) {
    // Parse structured data from reportText
    final parsed = report.parseStructuredReport();
    
    setState(() {
      _showForm = true;
      _editingReport = report;
      _selectedTripId = report.trip.id;
      
      // Populate form fields
      _reportController.text = parsed['mainReport'] as String? ?? '';
      _safetyNotesController.text = parsed['safetyNotes'] as String? ?? '';
      _weatherController.text = parsed['weatherConditions'] as String? ?? '';
      _terrainController.text = parsed['terrainNotes'] as String? ?? '';
      _participantCountController.text = 
          (parsed['participantCount'] as int?)?.toString() ?? '';
      
      _issues.clear();
      final issuesList = parsed['issues'] as List<String>?;
      if (issuesList != null) {
        _issues.addAll(issuesList);
      }
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedTripId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a trip')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final actionsNotifier = ref.read(logbookActionsProvider.notifier);
      
      if (_editingReport != null) {
        // Update existing report
        await actionsNotifier.updateTripReport(
          reportId: _editingReport!.id,
          tripId: _selectedTripId!,
          report: _reportController.text.trim(),
          safetyNotes: _safetyNotesController.text.trim().isNotEmpty
              ? _safetyNotesController.text.trim()
              : null,
          weatherConditions: _weatherController.text.trim().isNotEmpty
              ? _weatherController.text.trim()
              : null,
          terrainNotes: _terrainController.text.trim().isNotEmpty
              ? _terrainController.text.trim()
              : null,
          participantCount: int.tryParse(_participantCountController.text.trim()),
          issues: _issues.isNotEmpty ? _issues : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip report updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Create new report
        await actionsNotifier.createTripReport(
          tripId: _selectedTripId!,
          report: _reportController.text.trim(),
          safetyNotes: _safetyNotesController.text.trim().isNotEmpty
              ? _safetyNotesController.text.trim()
              : null,
          weatherConditions: _weatherController.text.trim().isNotEmpty
              ? _weatherController.text.trim()
              : null,
          terrainNotes: _terrainController.text.trim().isNotEmpty
              ? _terrainController.text.trim()
              : null,
          participantCount: int.tryParse(_participantCountController.text.trim()),
          issues: _issues.isNotEmpty ? _issues : null,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip report created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }

      _resetForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _confirmDelete(TripReport report) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Trip Report'),
        content: const Text(
          'Are you sure you want to delete this trip report? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(tripReportsProvider.notifier).deleteReport(report.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Trip report deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete report: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _showReportDetail(TripReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _ReportDetailSheet(
        report: report,
        onEdit: () {
          Navigator.of(context).pop();
          _editReport(report);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _confirmDelete(report);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final reportsState = ref.watch(tripReportsProvider);

    // Permission check
    final canCreateReport = user?.hasPermission('create_trip_report') ?? false;
    if (!canCreateReport) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Reports')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Access Denied', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              const Text('You don\'t have permission to create trip reports'),
            ],
          ),
        ),
      );
    }

    if (_isLoadingTrips) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip Reports')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Reports'),
        actions: _showForm
            ? null
            : [
                // Sort button
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sort',
                  onSelected: (value) {
                    ref.read(tripReportsProvider.notifier).setOrdering(value);
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: '-createdAt',
                      child: Row(
                        children: [
                          Icon(
                            reportsState.ordering == '-createdAt'
                                ? Icons.check
                                : Icons.access_time,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Newest First'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'createdAt',
                      child: Row(
                        children: [
                          Icon(
                            reportsState.ordering == 'createdAt'
                                ? Icons.check
                                : Icons.access_time,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Text('Oldest First'),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Filter button (if filters active)
                if (reportsState.tripFilter != null || 
                    reportsState.memberFilter != null)
                  IconButton(
                    icon: const Icon(Icons.filter_alt_off),
                    tooltip: 'Clear Filters',
                    onPressed: () {
                      ref.read(tripReportsProvider.notifier).clearFilters();
                    },
                  ),
              ],
      ),
      body: _showForm
          ? _buildReportForm(theme, colors)
          : _buildReportsList(theme, colors, reportsState),
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Create Report'),
            )
          : null,
    );
  }

  Widget _buildReportsList(
    ThemeData theme,
    ColorScheme colors,
    TripReportsState state,
  ) {
    if (state.isLoading && state.reports.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Error Loading Reports', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                ref.read(tripReportsProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.reports.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.description_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'No Trip Reports Yet',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first trip report using the button below',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(tripReportsProvider.notifier).refresh();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: state.reports.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == state.reports.length) {
            // Load more indicator
            if (!state.isLoading) {
              ref.read(tripReportsProvider.notifier).loadMore();
            }
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }

          final report = state.reports[index];
          return _TripReportCard(
            report: report,
            onTap: () => _showReportDetail(report),
            onEdit: () => _editReport(report),
            onDelete: () => _confirmDelete(report),
          );
        },
      ),
    );
  }

  Widget _buildReportForm(ThemeData theme, ColorScheme colors) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Back button
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _resetForm,
              ),
              Text(
                _editingReport != null ? 'Edit Trip Report' : 'Create Trip Report',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Trip selection
          DropdownButtonFormField<int>(
            value: _selectedTripId,
            decoration: InputDecoration(
              labelText: 'Select Trip',
              prefixIcon: const Icon(Icons.directions_car),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            items: _trips.map((trip) {
              final title = trip['title'] as String? ?? 'Unknown Trip';
              final id = trip['id'] as int;
              
              return DropdownMenuItem<int>(
                value: id,
                child: Text(title),
              );
            }).toList(),
            onChanged: _editingReport != null
                ? null // Disable trip change when editing
                : (value) {
                    setState(() {
                      _selectedTripId = value;
                    });
                  },
            validator: (value) {
              if (value == null) return 'Please select a trip';
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Main report
          TextFormField(
            controller: _reportController,
            maxLines: 8,
            maxLength: 2000,
            decoration: InputDecoration(
              labelText: 'Main Report *',
              hintText: 'Provide detailed trip report...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              alignLabelWithHint: true,
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter report content';
              }
              if (value.trim().length < 50) {
                return 'Report must be at least 50 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Safety notes
          TextFormField(
            controller: _safetyNotesController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Safety Notes (Optional)',
              hintText: 'Any safety concerns or incidents...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Weather conditions
          TextFormField(
            controller: _weatherController,
            maxLines: 2,
            maxLength: 200,
            decoration: InputDecoration(
              labelText: 'Weather Conditions (Optional)',
              hintText: 'Describe weather during trip...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Terrain notes
          TextFormField(
            controller: _terrainController,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              labelText: 'Terrain Notes (Optional)',
              hintText: 'Describe terrain conditions...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Participant count
          TextFormField(
            controller: _participantCountController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Participant Count (Optional)',
              hintText: 'Number of participants',
              prefixIcon: const Icon(Icons.people),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Issues section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Issues/Problems (${_issues.length})',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  
                  // Add issue field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _issueController,
                          decoration: const InputDecoration(
                            hintText: 'Add an issue...',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          if (_issueController.text.trim().isNotEmpty) {
                            setState(() {
                              _issues.add(_issueController.text.trim());
                              _issueController.clear();
                            });
                          }
                        },
                      ),
                    ],
                  ),
                  
                  // Issues list
                  if (_issues.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    ..._issues.asMap().entries.map((entry) {
                      final index = entry.key;
                      final issue = entry.value;
                      
                      return ListTile(
                        dense: true,
                        leading: const Icon(Icons.warning, size: 16),
                        title: Text(issue),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, size: 16),
                          onPressed: () {
                            setState(() => _issues.removeAt(index));
                          },
                        ),
                      );
                    }),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Submit button
          FilledButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(_editingReport != null ? 'Update Trip Report' : 'Create Trip Report'),
          ),
          
          if (_editingReport != null) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _isSubmitting ? null : _resetForm,
              child: const Text('Cancel'),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================================
// TRIP REPORT CARD
// ============================================================================

class _TripReportCard extends StatelessWidget {
  final TripReport report;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _TripReportCard({
    required this.report,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    // Get preview text (first 100 characters)
    final parsed = report.parseStructuredReport();
    final mainReport = parsed['mainReport'] as String? ?? '';
    final preview = mainReport.length > 100
        ? '${mainReport.substring(0, 100)}...'
        : mainReport;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trip info
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report.trip.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: colors.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              report.createdBy.displayName,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Link to trip details
                        InkWell(
                          onTap: () {
                            context.push('/trips/${report.trip.id}');
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.launch,
                                size: 14,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'View Trip Details',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit();
                          break;
                        case 'delete':
                          onDelete();
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Report preview
              Text(
                preview,
                style: theme.textTheme.bodyMedium,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 12),
              
              // Date
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    dateFormat.format(report.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// REPORT DETAIL SHEET
// ============================================================================

class _ReportDetailSheet extends StatelessWidget {
  final TripReport report;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ReportDetailSheet({
    required this.report,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('MMMM d, yyyy • h:mm a');
    final parsed = report.parseStructuredReport();

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip Report',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            report.trip.title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 24),
              
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    // Metadata
                    _buildMetadataCard(context, theme, colors, dateFormat),
                    
                    const SizedBox(height: 16),
                    
                    // Main Report
                    _buildSection(
                      context,
                      'Main Report',
                      parsed['mainReport'] as String? ?? 'No content',
                      Icons.description,
                    ),
                    
                    // Participant Count
                    if (parsed['participantCount'] != null &&
                        (parsed['participantCount'] as int) > 0)
                      _buildSection(
                        context,
                        'Participant Count',
                        '${parsed['participantCount']} participants',
                        Icons.people,
                      ),
                    
                    // Safety Notes
                    if (parsed['safetyNotes'] != null &&
                        (parsed['safetyNotes'] as String).isNotEmpty)
                      _buildSection(
                        context,
                        'Safety Notes',
                        parsed['safetyNotes'] as String,
                        Icons.health_and_safety,
                      ),
                    
                    // Weather Conditions
                    if (parsed['weatherConditions'] != null &&
                        (parsed['weatherConditions'] as String).isNotEmpty)
                      _buildSection(
                        context,
                        'Weather Conditions',
                        parsed['weatherConditions'] as String,
                        Icons.wb_sunny,
                      ),
                    
                    // Terrain Notes
                    if (parsed['terrainNotes'] != null &&
                        (parsed['terrainNotes'] as String).isNotEmpty)
                      _buildSection(
                        context,
                        'Terrain Notes',
                        parsed['terrainNotes'] as String,
                        Icons.terrain,
                      ),
                    
                    // Issues
                    if (parsed['issues'] != null &&
                        (parsed['issues'] as List<String>).isNotEmpty)
                      _buildIssuesSection(
                        context,
                        parsed['issues'] as List<String>,
                      ),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              
              // Action buttons
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.error,
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
      },
    );
  }

  Widget _buildMetadataCard(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    DateFormat dateFormat,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: report.createdBy.profilePicture != null
                      ? NetworkImage(report.createdBy.profilePicture!)
                      : null,
                  child: report.createdBy.profilePicture == null
                      ? Text('${report.createdBy.firstName[0]}${report.createdBy.lastName[0]}')
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report.createdBy.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Marshal',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 16,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(report.createdAt),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String content,
    IconData icon,
  ) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              content,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(BuildContext context, List<String> issues) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning, size: 20, color: colors.error),
              const SizedBox(width: 8),
              Text(
                'Issues / Problems',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: issues.map((issue) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: colors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          issue,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
