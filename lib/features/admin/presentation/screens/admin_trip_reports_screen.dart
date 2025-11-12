import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/logbook_provider.dart';

/// Admin Trip Reports Screen
/// 
/// Create and view post-trip marshal reports
/// Accessible by users with create_trip_report permission
class AdminTripReportsScreen extends ConsumerStatefulWidget {
  const AdminTripReportsScreen({super.key});

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
  String? _selectedTripTitle;
  List<Map<String, dynamic>> _trips = [];
  final List<String> _issues = [];
  final TextEditingController _issueController = TextEditingController();
  
  bool _isLoadingTrips = true;
  bool _isSubmitting = false;
  bool _showForm = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrips();
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
      await ref.read(logbookActionsProvider.notifier).createTripReport(
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
          const SnackBar(content: Text('Trip report created successfully!')),
        );
        
        // Reset form
        setState(() {
          _showForm = false;
          _selectedTripId = null;
          _selectedTripTitle = null;
          _issues.clear();
        });
        _formKey.currentState?.reset();
        _reportController.clear();
        _safetyNotesController.clear();
        _weatherController.clear();
        _terrainController.clear();
        _participantCountController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create report: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

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
      ),
      body: _showForm
          ? _buildReportForm(theme, colors)
          : _buildReportsList(theme, colors),
      floatingActionButton: !_showForm
          ? FloatingActionButton.extended(
              onPressed: () => setState(() => _showForm = true),
              icon: const Icon(Icons.add),
              label: const Text('Create Report'),
            )
          : null,
    );
  }

  Widget _buildReportsList(ThemeData theme, ColorScheme colors) {
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
              color: colors.onSurface.withOpacity(0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
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
                onPressed: () => setState(() => _showForm = false),
              ),
              Text(
                'Create Trip Report',
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
            onChanged: (value) {
              setState(() {
                _selectedTripId = value;
                if (value != null) {
                  final trip = _trips.firstWhere((t) => t['id'] == value);
                  _selectedTripTitle = trip['title'] as String?;
                }
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
          ElevatedButton(
            onPressed: _isSubmitting ? null : _handleSubmit,
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create Trip Report'),
          ),
        ],
      ),
    );
  }
}
