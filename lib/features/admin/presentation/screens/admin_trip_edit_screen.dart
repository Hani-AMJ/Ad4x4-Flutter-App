import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';

/// Admin Trip Edit Screen
/// 
/// Full-featured trip editing form for administrators.
/// Features:
/// - Load existing trip data
/// - Edit all trip fields
/// - Validation
/// - Save with permission check
class AdminTripEditScreen extends ConsumerStatefulWidget {
  final int tripId;

  const AdminTripEditScreen({
    super.key,
    required this.tripId,
  });

  @override
  ConsumerState<AdminTripEditScreen> createState() => _AdminTripEditScreenState();
}

class _AdminTripEditScreenState extends ConsumerState<AdminTripEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  // Form controllers
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _capacityController;
  late TextEditingController _requirementsController;

  // Form state
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _cutOff;
  int? _selectedLevelId;
  int? _selectedMeetingPointId;
  bool _allowWaitlist = true;

  // Reference data
  List<TripLevel> _levels = [];
  List<MeetingPoint> _meetingPoints = [];
  Trip? _originalTrip;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _capacityController = TextEditingController();
    _requirementsController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _capacityController.dispose();
    _requirementsController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load trip data, levels, and meeting points in parallel
      final results = await Future.wait([
        repository.getTripDetail(widget.tripId),
        repository.getLevels(),
        repository.getMeetingPoints(),
      ]);

      final tripJson = results[0] as Map<String, dynamic>;
      final levelsJson = results[1] as List<dynamic>;
      final meetingPointsJson = results[2] as List<dynamic>;

      final trip = Trip.fromJson(tripJson);
      final levels = levelsJson.map((json) => TripLevel.fromJson(json as Map<String, dynamic>)).toList();
      final meetingPoints = meetingPointsJson.map((json) => MeetingPoint.fromJson(json as Map<String, dynamic>)).toList();

      setState(() {
        _originalTrip = trip;
        _levels = levels;
        _meetingPoints = meetingPoints;

        // Populate form with trip data
        _titleController.text = trip.title;
        _descriptionController.text = trip.description;
        _capacityController.text = trip.capacity.toString();
        _requirementsController.text = trip.requirements.join('\n');
        
        _startTime = trip.startTime;
        _endTime = trip.endTime;
        _cutOff = trip.cutOff;
        _selectedLevelId = trip.level.id;
        _selectedMeetingPointId = trip.meetingPoint?.id;
        _allowWaitlist = trip.allowWaitlist;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load trip: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _saveTrip() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate dates
    if (_startTime == null || _endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end times')),
      );
      return;
    }

    if (_endTime!.isBefore(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time')),
      );
      return;
    }

    if (_cutOff != null && _cutOff!.isAfter(_startTime!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cut-off must be before start time')),
      );
      return;
    }

    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a difficulty level')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Parse requirements (split by newlines)
      final requirements = _requirementsController.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Prepare update data
      final updateData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'start_time': _startTime!.toIso8601String(),
        'end_time': _endTime!.toIso8601String(),
        if (_cutOff != null) 'cut_off': _cutOff!.toIso8601String(),
        'capacity': int.parse(_capacityController.text),
        'level': _selectedLevelId,
        if (_selectedMeetingPointId != null) 'meeting_point': _selectedMeetingPointId,
        'allow_waitlist': _allowWaitlist,
        'requirements': requirements,
      };

      // Use PATCH for partial update
      await repository.patchTrip(widget.tripId, updateData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Trip updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        final errorMessage = e.toString().toLowerCase();
        final isPermissionError = errorMessage.contains('permission') ||
            errorMessage.contains('unauthorized') ||
            errorMessage.contains('403');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isPermissionError
                  ? '🚫 You are not authorized to edit trips'
                  : '❌ Failed to update trip: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;
    
    // Check permission - user must have edit_trips permission
    final canEdit = user?.hasPermission('edit_trips') ?? false;
    
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin/trips/all'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Trip Edit Permission Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to edit trips.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin/trips/all'),
                child: const Text('Back to Trips'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Trip'),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveTrip,
              child: const Text('Save'),
            ),
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildBasicInfoSection(),
          const SizedBox(height: 24),
          _buildDateTimeSection(),
          const SizedBox(height: 24),
          _buildDetailsSection(),
          const SizedBox(height: 24),
          _buildCapacitySection(),
          const SizedBox(height: 24),
          _buildRequirementsSection(),
          const SizedBox(height: 32),
          _buildSaveButton(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Trip Title *',
                hintText: 'e.g., Desert Adventure',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe the trip...',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateTimeSection() {
    final dateFormat = DateFormat('MMM dd, yyyy • h:mm a');

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Date & Time',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Start Time
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('Start Time *'),
              subtitle: Text(_startTime != null ? dateFormat.format(_startTime!) : 'Not set'),
              trailing: const Icon(Icons.edit),
              onTap: () => _selectDateTime(context, 'start'),
            ),
            const Divider(),
            
            // End Time
            ListTile(
              leading: const Icon(Icons.event),
              title: const Text('End Time *'),
              subtitle: Text(_endTime != null ? dateFormat.format(_endTime!) : 'Not set'),
              trailing: const Icon(Icons.edit),
              onTap: () => _selectDateTime(context, 'end'),
            ),
            const Divider(),
            
            // Cut-off Time
            ListTile(
              leading: const Icon(Icons.schedule),
              title: const Text('Registration Cut-off (Optional)'),
              subtitle: Text(_cutOff != null ? dateFormat.format(_cutOff!) : 'No cut-off'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_cutOff != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _cutOff = null),
                    ),
                  const Icon(Icons.edit),
                ],
              ),
              onTap: () => _selectDateTime(context, 'cutoff'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trip Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Difficulty Level
            DropdownButtonFormField<int>(
              value: _selectedLevelId,
              decoration: const InputDecoration(
                labelText: 'Difficulty Level *',
                border: OutlineInputBorder(),
              ),
              items: _levels.map((level) {
                return DropdownMenuItem<int>(
                  value: level.id,
                  child: Text('${level.name} (Level ${level.numericLevel})'),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedLevelId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Please select a difficulty level';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Meeting Point
            DropdownButtonFormField<int>(
              value: _selectedMeetingPointId,
              decoration: const InputDecoration(
                labelText: 'Meeting Point (Optional)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int>(
                  value: null,
                  child: Text('No meeting point'),
                ),
                ..._meetingPoints.map((mp) {
                  return DropdownMenuItem<int>(
                    value: mp.id,
                    child: Text(mp.displayName),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedMeetingPointId = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCapacitySection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Capacity & Waitlist',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _capacityController,
              decoration: InputDecoration(
                labelText: 'Maximum Capacity *',
                hintText: 'e.g., 20',
                border: const OutlineInputBorder(),
                helperText: _originalTrip != null
                    ? 'Current registrations: ${_originalTrip!.registeredCount}'
                    : null,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter capacity';
                }
                final capacity = int.tryParse(value);
                if (capacity == null || capacity < 1) {
                  return 'Please enter a valid number';
                }
                if (_originalTrip != null && capacity < _originalTrip!.registeredCount) {
                  return 'Cannot reduce below ${_originalTrip!.registeredCount} (current registrations)';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            SwitchListTile(
              title: const Text('Allow Waitlist'),
              subtitle: const Text('Members can join waitlist when trip is full'),
              value: _allowWaitlist,
              onChanged: (value) {
                setState(() {
                  _allowWaitlist = value;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Requirements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter each requirement on a new line',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _requirementsController,
              decoration: const InputDecoration(
                labelText: 'Trip Requirements (Optional)',
                hintText: 'e.g.,\n4x4 vehicle required\nMinimum Level 3\nRecovery equipment',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: FilledButton.icon(
        onPressed: _isSaving ? null : _saveTrip,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.save),
        label: Text(_isSaving ? 'Saving...' : 'Save Changes'),
      ),
    );
  }

  Future<void> _selectDateTime(BuildContext context, String type) async {
    DateTime? initialDate;
    String title;

    switch (type) {
      case 'start':
        initialDate = _startTime ?? DateTime.now();
        title = 'Select Start Time';
        break;
      case 'end':
        initialDate = _endTime ?? _startTime?.add(const Duration(hours: 4)) ?? DateTime.now();
        title = 'Select End Time';
        break;
      case 'cutoff':
        initialDate = _cutOff ?? _startTime?.subtract(const Duration(hours: 24)) ?? DateTime.now();
        title = 'Select Cut-off Time';
        break;
      default:
        return;
    }

    // Show date picker
    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: title,
    );

    if (date == null || !mounted) return;

    // Show time picker
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
      helpText: title,
    );

    if (time == null || !mounted) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    setState(() {
      switch (type) {
        case 'start':
          _startTime = selectedDateTime;
          break;
        case 'end':
          _endTime = selectedDateTime;
          break;
        case 'cutoff':
          _cutOff = selectedDateTime;
          break;
      }
    });
  }
}
