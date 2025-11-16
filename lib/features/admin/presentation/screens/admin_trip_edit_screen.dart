import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/trip_area_provider.dart';
import '../../../../data/models/vehicle_modifications_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/vehicle_modifications_cache_service.dart';
import '../../../../core/utils/level_display_helper.dart';

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
  String? _selectedAreaValue;  // NEW: Selected trip area
  bool _allowWaitlist = true;

  // Vehicle Requirements state
  bool _hasVehicleRequirements = false;
  LiftKitType? _minLiftKit;
  ShocksType? _minShocksType;
  bool? _requireLongTravelArms;
  TyreSizeType? _minTyreSize;
  HorsepowerType? _minHorsepower;
  bool? _requirePerformanceIntake;
  bool? _requirePerformanceCatback;
  bool? _requireOffRoadLight;
  bool? _requireWinch;
  bool? _requireArmor;
  late VehicleModificationsCacheService _vehicleModsService;

  // Reference data
  List<TripLevel> _levels = [];
  List<MeetingPoint> _meetingPoints = [];
  Trip? _originalTrip;
  
  // Image handling
  File? _newImage;
  Uint8List? _newImageBytes;
  String? _currentImageUrl;
  bool _imageChanged = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _capacityController = TextEditingController();
    _requirementsController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
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

  Future<void> _initializeServices() async {
    final prefs = await SharedPreferences.getInstance();
    _vehicleModsService = VehicleModificationsCacheService(prefs);
    await _loadData();
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
        repository.getMeetingPoints(pageSize: 100), // Get all meeting points
      ]);

      final tripJson = results[0] as Map<String, dynamic>;
      final levelsJson = results[1] as List<dynamic>;
      final meetingPointsResponse = results[2] as Map<String, dynamic>;
      final meetingPointsJson = meetingPointsResponse['results'] as List<dynamic>;

      final trip = Trip.fromJson(tripJson);
      final levels = levelsJson.map((json) => TripLevel.fromJson(json as Map<String, dynamic>)).toList();
      final meetingPoints = meetingPointsJson.map((json) => MeetingPoint.fromJson(json as Map<String, dynamic>)).toList();

      // Populate form with trip data
      _originalTrip = trip;
      _levels = levels;
      _meetingPoints = meetingPoints;
      _titleController.text = trip.title;
      _descriptionController.text = trip.description;
      _currentImageUrl = trip.imageUrl;
      _capacityController.text = trip.capacity.toString();
      _requirementsController.text = trip.requirements.join('\n');
      
      _startTime = trip.startTime;
      _endTime = trip.endTime;
      _cutOff = trip.cutOff;
      _selectedLevelId = trip.level.id;
      _selectedMeetingPointId = trip.meetingPoint?.id;
      _allowWaitlist = trip.allowWaitlist;

      // Load vehicle requirements if they exist
      await _loadVehicleRequirements();

      setState(() {
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
        if (_selectedAreaValue != null) 'area': _selectedAreaValue,  // NEW: Trip area field
        'allow_waitlist': _allowWaitlist,
        'requirements': requirements,
        // Include image if changed
        if (_imageChanged && (_newImage != null || _newImageBytes != null))
          'image': await _encodeImage(),
      };

      // Use PATCH for partial update
      await repository.patchTrip(widget.tripId, updateData);

      // Save vehicle requirements (separate cache operation)
      await _saveVehicleRequirements();

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

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // For web platform
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _newImageBytes = bytes;
          _imageChanged = true;
        });
      } else {
        // For mobile platforms
        setState(() {
          _newImage = File(pickedFile.path);
          _imageChanged = true;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Image selected'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _encodeImage() async {
    try {
      Uint8List bytes;
      
      if (kIsWeb) {
        if (_newImageBytes == null) return null;
        bytes = _newImageBytes!;
      } else {
        if (_newImage == null) return null;
        bytes = await _newImage!.readAsBytes();
      }
      
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to encode image: $e');
      }
      return null;
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
          const SizedBox(height: 24),
          _buildVehicleRequirementsSection(),
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
            const SizedBox(height: 16),
            // Trip Image Section
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Trip Image',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(width: 8),
                    if (_imageChanged)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'Changed',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                // Current or new image preview
                if (_newImageBytes != null || _newImage != null || _currentImageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _newImageBytes != null
                        ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                        : _newImage != null
                            ? Image.file(_newImage!, fit: BoxFit.cover)
                            : _currentImageUrl != null
                                ? Image.network(_currentImageUrl!, fit: BoxFit.cover)
                                : const SizedBox(),
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.image),
                      label: Text(_currentImageUrl != null || _imageChanged ? 'Change Image' : 'Select Image'),
                    ),
                    if (_imageChanged) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _newImage = null;
                            _newImageBytes = null;
                            _imageChanged = false;
                          });
                        },
                        icon: const Icon(Icons.undo),
                        label: const Text('Revert'),
                      ),
                    ],
                  ],
                ),
              ],
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
                final color = LevelDisplayHelper.getLevelColor(level.numericLevel);
                final icon = LevelDisplayHelper.getLevelIcon(level.numericLevel);
                final displayText = LevelDisplayHelper.getDisplayText(level);
                
                return DropdownMenuItem<int>(
                  value: level.id,
                  child: Row(
                    children: [
                      Icon(icon, size: 18, color: color),
                      const SizedBox(width: 8),
                      Text(
                        displayText,
                        style: TextStyle(color: color, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
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
            
            // NEW: Trip Area Dropdown
            Consumer(
              builder: (context, ref, _) {
                final areasAsync = ref.watch(tripAreaChoicesProvider);
                
                return areasAsync.when(
                  data: (areas) => DropdownButtonFormField<String>(
                    value: _selectedAreaValue,
                    decoration: const InputDecoration(
                      labelText: 'Trip Area (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Select the primary terrain type',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('Not specified'),
                      ),
                      ...areas.map((area) {
                        // Parse color
                        Color areaColor;
                        try {
                          if (area.color != null && area.color!.startsWith('#')) {
                            final hexColor = area.color!.substring(1);
                            areaColor = Color(int.parse('FF$hexColor', radix: 16));
                          } else {
                            areaColor = Theme.of(context).colorScheme.primary;
                          }
                        } catch (e) {
                          areaColor = Theme.of(context).colorScheme.primary;
                        }
                        
                        // Map icon
                        IconData areaIcon;
                        switch (area.icon?.toLowerCase()) {
                          case 'desert':
                            areaIcon = Icons.wb_sunny;
                            break;
                          case 'terrain':
                            areaIcon = Icons.terrain;
                            break;
                          case 'water':
                            areaIcon = Icons.water;
                            break;
                          case 'beach_access':
                            areaIcon = Icons.beach_access;
                            break;
                          case 'layers':
                            areaIcon = Icons.layers;
                            break;
                          default:
                            areaIcon = Icons.landscape;
                        }
                        
                        return DropdownMenuItem<String>(
                          value: area.value,
                          child: Row(
                            children: [
                              Icon(areaIcon, size: 18, color: areaColor),
                              const SizedBox(width: 8),
                              Text(
                                area.label,
                                style: TextStyle(color: areaColor, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAreaValue = value;
                      });
                    },
                  ),
                  loading: () => DropdownButtonFormField<String>(
                    value: null,
                    decoration: const InputDecoration(
                      labelText: 'Trip Area (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Loading areas...',
                    ),
                    items: const [],
                    onChanged: null,
                  ),
                  error: (e, s) => DropdownButtonFormField<String>(
                    value: _selectedAreaValue,
                    decoration: const InputDecoration(
                      labelText: 'Trip Area (Optional)',
                      border: OutlineInputBorder(),
                      helperText: 'Failed to load areas',
                    ),
                    items: const [
                      DropdownMenuItem<String>(
                        value: null,
                        child: Text('Not specified'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedAreaValue = value;
                      });
                    },
                  ),
                );
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

  Future<void> _loadVehicleRequirements() async {
    try {
      final requirements = await _vehicleModsService.getRequirementsByTripId(widget.tripId);
      if (requirements != null && requirements.hasRequirements) {
        setState(() {
          _hasVehicleRequirements = true;
          _minLiftKit = requirements.minLiftKit;
          _minShocksType = requirements.minShocksType;
          _requireLongTravelArms = requirements.requireLongTravelArms;
          _minTyreSize = requirements.minTyreSize;
          _minHorsepower = requirements.minHorsepower;
          _requirePerformanceIntake = requirements.requirePerformanceIntake;
          _requirePerformanceCatback = requirements.requirePerformanceCatback;
          _requireOffRoadLight = requirements.requireOffRoadLight;
          _requireWinch = requirements.requireWinch;
          _requireArmor = requirements.requireArmor;
        });
      }
    } catch (e) {
      // Requirements not found is OK - this is optional
      if (mounted) {
        debugPrint('No vehicle requirements found for trip: $e');
      }
    }
  }

  Future<void> _saveVehicleRequirements() async {
    if (!_hasVehicleRequirements) {
      // Delete requirements if toggle is off
      try {
        await _vehicleModsService.deleteRequirements(widget.tripId);
      } catch (e) {
        // OK if requirements don't exist
      }
      return;
    }

    // Save requirements if toggle is on
    final requirements = TripVehicleRequirements(
      id: '', // Will be generated by service
      tripId: widget.tripId,
      minLiftKit: _minLiftKit,
      minShocksType: _minShocksType,
      requireLongTravelArms: _requireLongTravelArms,
      minTyreSize: _minTyreSize,
      minHorsepower: _minHorsepower,
      requirePerformanceIntake: _requirePerformanceIntake,
      requirePerformanceCatback: _requirePerformanceCatback,
      requireOffRoadLight: _requireOffRoadLight,
      requireWinch: _requireWinch,
      requireArmor: _requireArmor,
      createdAt: DateTime.now(),
    );

    await _vehicleModsService.saveRequirements(requirements);
  }

  Widget _buildVehicleRequirementsSection() {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    // Only show for Advanced (200) and Expert (300) trips
    final isAdvancedOrExpert = _selectedLevelId != null &&
        (_levels.any((l) => l.id == _selectedLevelId && (l.numericLevel >= 200 && l.numericLevel <= 300)));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vehicle Requirements',
                    style: theme.textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Set minimum vehicle modification requirements for this trip (optional)',
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            
            if (!isAdvancedOrExpert) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Vehicle requirements are only available for Advanced and Expert level trips',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            if (isAdvancedOrExpert) ...[
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Require Vehicle Modifications'),
                subtitle: Text(
                  _hasVehicleRequirements
                      ? 'Members must meet requirements to register'
                      : 'No vehicle requirements (backward compatible)',
                  style: theme.textTheme.bodySmall,
                ),
                value: _hasVehicleRequirements,
                onChanged: (value) {
                  setState(() {
                    _hasVehicleRequirements = value;
                  });
                },
              ),
              
              if (_hasVehicleRequirements) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Only members with verified modifications meeting these requirements can register',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Suspension & Tires',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildRequirementDropdown<LiftKitType>(
                  label: 'Minimum Lift Kit',
                  value: _minLiftKit,
                  items: LiftKitType.values,
                  onChanged: (value) => setState(() => _minLiftKit = value),
                  getDisplay: (item) => item.displayName,
                ),
                const SizedBox(height: 12),
                
                _buildRequirementDropdown<ShocksType>(
                  label: 'Minimum Shocks Type',
                  value: _minShocksType,
                  items: ShocksType.values,
                  onChanged: (value) => setState(() => _minShocksType = value),
                  getDisplay: (item) => item.displayName,
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Require Long Travel Arms'),
                  value: _requireLongTravelArms ?? false,
                  onChanged: (value) => setState(() => _requireLongTravelArms = value),
                ),
                const SizedBox(height: 12),
                
                _buildRequirementDropdown<TyreSizeType>(
                  label: 'Minimum Tyre Size',
                  value: _minTyreSize,
                  items: TyreSizeType.values,
                  onChanged: (value) => setState(() => _minTyreSize = value),
                  getDisplay: (item) => item.displayName,
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Engine',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                _buildRequirementDropdown<HorsepowerType>(
                  label: 'Minimum Horsepower',
                  value: _minHorsepower,
                  items: HorsepowerType.values,
                  onChanged: (value) => setState(() => _minHorsepower = value),
                  getDisplay: (item) => item.displayName,
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Require Performance Air Intake'),
                  value: _requirePerformanceIntake ?? false,
                  onChanged: (value) => setState(() => _requirePerformanceIntake = value),
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Require Performance Catback Exhaust'),
                  value: _requirePerformanceCatback ?? false,
                  onChanged: (value) => setState(() => _requirePerformanceCatback = value),
                ),
                const SizedBox(height: 16),
                
                Text(
                  'Equipment',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Require Off-Road Lights'),
                  value: _requireOffRoadLight ?? false,
                  onChanged: (value) => setState(() => _requireOffRoadLight = value),
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Require Winch'),
                  value: _requireWinch ?? false,
                  onChanged: (value) => setState(() => _requireWinch = value),
                ),
                const SizedBox(height: 12),
                
                SwitchListTile(
                  title: const Text('Require Armor (skid plates, rock sliders, etc.)'),
                  value: _requireArmor ?? false,
                  onChanged: (value) => setState(() => _requireArmor = value),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
    required String Function(T) getDisplay,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: [
        DropdownMenuItem<T>(
          value: null,
          child: Text('No requirement', style: TextStyle(color: Colors.grey.shade600)),
        ),
        ...items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(getDisplay(item)),
          );
        }).toList(),
      ],
      onChanged: onChanged,
    );
  }
}
