import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/logbook_provider.dart';
import 'package:go_router/go_router.dart';

/// Quick Trip Report Screen
/// 
/// Enhanced trip report creation with auto-prefilled trip data and participant management
/// Features:
/// - Auto-fetch trip details and registrants
/// - Participant tagging with comments
/// - Quick tag buttons (Excellent, Needs Improvement, Safety Concern, etc.)
/// - Main report field for overall summary
/// - Consolidated serialization into reportText field
class QuickTripReportScreen extends ConsumerStatefulWidget {
  final int tripId;
  
  const QuickTripReportScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<QuickTripReportScreen> createState() => _QuickTripReportScreenState();
}

class _QuickTripReportScreenState extends ConsumerState<QuickTripReportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _mainReportController = TextEditingController();
  final _safetyNotesController = TextEditingController();
  final _weatherController = TextEditingController();
  final _terrainController = TextEditingController();
  
  // Trip data
  Trip? _trip;
  
  // Participant tracking
  final Map<int, bool> _selectedParticipants = {};
  final Map<int, String> _participantComments = {};
  final Map<int, Set<String>> _participantTags = {};
  
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _error;

  // Quick tag options
  static const quickTags = [
    {'label': 'Excellent Performance', 'icon': Icons.star, 'color': Colors.green},
    {'label': 'Needs Improvement', 'icon': Icons.warning, 'color': Colors.orange},
    {'label': 'Safety Concern', 'icon': Icons.health_and_safety, 'color': Colors.red},
    {'label': 'Standout Moment', 'icon': Icons.emoji_events, 'color': Colors.amber},
    {'label': 'Helpful', 'icon': Icons.volunteer_activism, 'color': Colors.blue},
    {'label': 'First Timer', 'icon': Icons.new_releases, 'color': Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTripData();
    });
  }

  @override
  void dispose() {
    _mainReportController.dispose();
    _safetyNotesController.dispose();
    _weatherController.dispose();
    _terrainController.dispose();
    super.dispose();
  }

  Future<void> _loadTripData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripData = await repository.getTripDetail(widget.tripId);
      
      final trip = Trip.fromJson(tripData);
      
      // Filter for confirmed registrations only
      final confirmedRegistrants = trip.registered
          .where((reg) => reg.status == 'confirmed' || reg.status == 'checked_in')
          .toList();
      
      setState(() {
        _trip = trip;
        
        // Initialize participant data - all selected by default
        for (final reg in confirmedRegistrants) {
          final memberId = reg.member.id;
          _selectedParticipants[memberId] = true;
          _participantComments[memberId] = '';
          _participantTags[memberId] = {};
        }
        
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load trip details: $e';
        _isLoading = false;
      });
    }
  }

  void _toggleTag(int memberId, String tag) {
    setState(() {
      if (_participantTags[memberId]!.contains(tag)) {
        _participantTags[memberId]!.remove(tag);
      } else {
        _participantTags[memberId]!.add(tag);
      }
    });
  }

  String _buildConsolidatedReport() {
    final buffer = StringBuffer();
    
    // Main report header
    buffer.writeln('=== TRIP REPORT ===');
    buffer.writeln();
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln();
    
    // Marshal's main report
    if (_mainReportController.text.trim().isNotEmpty) {
      buffer.writeln('MAIN REPORT:');
      buffer.writeln(_mainReportController.text.trim());
      buffer.writeln();
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
    }
    
    // Participants section
    final selectedCount = _selectedParticipants.values.where((v) => v).length;
    if (selectedCount > 0 && _trip != null) {
      buffer.writeln('PARTICIPANTS ($selectedCount):');
      buffer.writeln();
      
      // Get confirmed registrants
      final confirmedRegistrants = _trip!.registered
          .where((reg) => reg.status == 'confirmed' || reg.status == 'checked_in')
          .toList();
      
      for (final reg in confirmedRegistrants) {
        final memberId = reg.member.id;
        
        if (_selectedParticipants[memberId] == true) {
          final username = reg.member.username;
          final displayName = reg.member.displayName;
          
          buffer.writeln('@$username ($displayName)');
          
          // Add tags if any
          final tags = _participantTags[memberId] ?? {};
          if (tags.isNotEmpty) {
            buffer.writeln('  Tags: ${tags.join(', ')}');
          }
          
          // Add comment if any
          final comment = _participantComments[memberId]?.trim() ?? '';
          if (comment.isNotEmpty) {
            buffer.writeln('  • $comment');
          }
          
          buffer.writeln();
        }
      }
      
      buffer.writeln('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      buffer.writeln();
    }
    
    // Safety notes
    if (_safetyNotesController.text.trim().isNotEmpty) {
      buffer.writeln('SAFETY NOTES:');
      buffer.writeln(_safetyNotesController.text.trim());
      buffer.writeln();
    }
    
    // Weather conditions
    if (_weatherController.text.trim().isNotEmpty) {
      buffer.writeln('WEATHER CONDITIONS:');
      buffer.writeln(_weatherController.text.trim());
      buffer.writeln();
    }
    
    // Terrain notes
    if (_terrainController.text.trim().isNotEmpty) {
      buffer.writeln('TERRAIN NOTES:');
      buffer.writeln(_terrainController.text.trim());
      buffer.writeln();
    }
    
    return buffer.toString().trim();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Validate that at least main report is filled
    if (_mainReportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide a main report summary'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if trip exists and is in the past
    if (_trip == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Trip data not available'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Warn if trip hasn't ended yet
    if (_trip!.endTime.isAfter(DateTime.now())) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Trip Not Completed'),
          content: Text(
            'This trip has not ended yet (ends ${DateFormat('MMM dd, yyyy HH:mm').format(_trip!.endTime)}). '
            'Trip reports are typically created after the trip completes. Continue anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continue'),
            ),
          ],
        ),
      );
      
      if (shouldContinue != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      final consolidatedReport = _buildConsolidatedReport();
      final selectedCount = _selectedParticipants.values.where((v) => v).length;
      
      if (kDebugMode) {
        debugPrint('📝 [QuickTripReport] Creating report for trip ${widget.tripId}');
        debugPrint('   Trip title: ${_trip!.title}');
        debugPrint('   Trip status: ${_trip!.approvalStatus}');
        debugPrint('   Trip end time: ${_trip!.endTime}');
        debugPrint('   Selected participants: $selectedCount');
        debugPrint('   Report length: ${consolidatedReport.length} chars');
      }
      
      final actionsNotifier = ref.read(logbookActionsProvider.notifier);
      
      await actionsNotifier.createTripReport(
        tripId: widget.tripId,
        report: consolidatedReport,
        participantCount: selectedCount,
        safetyNotes: _safetyNotesController.text.trim().isNotEmpty
            ? _safetyNotesController.text.trim()
            : null,
        weatherConditions: _weatherController.text.trim().isNotEmpty
            ? _weatherController.text.trim()
            : null,
        terrainNotes: _terrainController.text.trim().isNotEmpty
            ? _terrainController.text.trim()
            : null,
      );

      // ✅ Invalidate provider cache to refresh report button visibility
      ref.invalidate(tripReportsByTripProvider(widget.tripId));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trip report created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Failed to create report: $e';
        
        // Provide more helpful error messages
        if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
          errorMessage = 'Permission denied. Trip reports can only be created by the trip lead/marshal for completed trips.';
        } else if (e.toString().contains('400') || e.toString().contains('Bad Request')) {
          errorMessage = 'Invalid report data. Please check all required fields.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Trip Report')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Trip Report')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadTripData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trip == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Trip Report')),
        body: const Center(child: Text('Trip not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Trip Report'),
        actions: [
          if (_isSubmitting)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton.icon(
              onPressed: _handleSubmit,
              icon: const Icon(Icons.check),
              label: const Text('Submit'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildTripInfoCard(theme, colors),
            const SizedBox(height: 16),
            _buildMainReportField(theme, colors),
            const SizedBox(height: 16),
            _buildParticipantsSection(theme, colors),
            const SizedBox(height: 16),
            _buildAdditionalFieldsCard(theme, colors),
            const SizedBox(height: 80), // Space for submit button
          ],
        ),
      ),
    );
  }

  Widget _buildTripInfoCard(ThemeData theme, ColorScheme colors) {
    final dateFormat = DateFormat('EEEE, MMM dd, yyyy • h:mm a');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.directions_car, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _trip!.title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'Marshal', _trip!.lead.displayName),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.calendar_today, 'Date', dateFormat.format(_trip!.startTime)),
            if (_trip!.meetingPoint != null) ...[
              const SizedBox(height: 8),
              _buildInfoRow(Icons.location_on, 'Meeting Point', _trip!.meetingPoint!.name),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800]),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainReportField(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.description, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Main Report Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mainReportController,
              maxLines: 8,
              maxLength: 2000,
              decoration: InputDecoration(
                hintText: 'Provide an overall summary of the trip, key highlights, challenges faced, and general observations...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Main report is required';
                }
                if (value.trim().length < 50) {
                  return 'Report must be at least 50 characters';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantsSection(ThemeData theme, ColorScheme colors) {
    if (_trip == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Filter for confirmed registrations only
    final confirmedRegistrants = _trip!.registered
        .where((reg) => reg.status == 'confirmed' || reg.status == 'checked_in')
        .toList();

    if (confirmedRegistrants.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Text(
              'No confirmed registrants found',
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    final selectedCount = _selectedParticipants.values.where((v) => v).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.people, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Participants ($selectedCount/${confirmedRegistrants.length})',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      final allSelected = _selectedParticipants.values.every((v) => v);
                      for (final key in _selectedParticipants.keys) {
                        _selectedParticipants[key] = !allSelected;
                      }
                    });
                  },
                  child: Text(
                    _selectedParticipants.values.every((v) => v) ? 'Deselect All' : 'Select All',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...confirmedRegistrants.map((reg) => _buildParticipantCard(reg, theme, colors)),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantCard(TripRegistration reg, ThemeData theme, ColorScheme colors) {
    final member = reg.member;
    final memberId = member.id;
    final username = member.username;
    final displayName = member.displayName;
    final isSelected = _selectedParticipants[memberId] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 2 : 0,
      color: isSelected ? null : colors.surfaceContainerHighest.withValues(alpha: 0.3),
      child: ExpansionTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) {
            setState(() {
              _selectedParticipants[memberId] = value ?? false;
            });
          },
        ),
        title: Text(
          displayName,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? null : colors.onSurfaceVariant,
          ),
        ),
        subtitle: Text('@$username'),
        children: [
          if (isSelected) ...[
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Tags:',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: quickTags.map((tag) {
                      final label = tag['label'] as String;
                      final isActive = _participantTags[memberId]?.contains(label) ?? false;
                      return FilterChip(
                        label: Text(label),
                        avatar: Icon(tag['icon'] as IconData, size: 16),
                        selected: isActive,
                        onSelected: (selected) => _toggleTag(memberId, label),
                        selectedColor: (tag['color'] as Color).withValues(alpha: 0.3),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _participantComments[memberId],
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      labelText: 'Comment (Optional)',
                      hintText: 'Add specific observations, feedback, or notes about this participant...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      _participantComments[memberId] = value;
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdditionalFieldsCard(ThemeData theme, ColorScheme colors) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note_add, color: colors.primary),
                const SizedBox(width: 8),
                Text(
                  'Additional Details (Optional)',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Safety Notes
            TextFormField(
              controller: _safetyNotesController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Safety Notes',
                hintText: 'Any safety concerns, incidents, or precautions taken...',
                prefixIcon: const Icon(Icons.health_and_safety),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Weather Conditions
            TextFormField(
              controller: _weatherController,
              maxLines: 2,
              maxLength: 200,
              decoration: InputDecoration(
                labelText: 'Weather Conditions',
                hintText: 'Weather during the trip...',
                prefixIcon: const Icon(Icons.wb_sunny),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Terrain Notes
            TextFormField(
              controller: _terrainController,
              maxLines: 3,
              maxLength: 500,
              decoration: InputDecoration(
                labelText: 'Terrain Notes',
                hintText: 'Terrain conditions, difficulty, notable sections...',
                prefixIcon: const Icon(Icons.terrain),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
