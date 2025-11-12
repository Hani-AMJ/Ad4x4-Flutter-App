import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../data/models/level_model.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/status_helpers.dart';

/// Create Trip Screen - Complete multi-step trip creation form
/// 
/// Features:
/// - 4-step form with validation
/// - Meeting point and level selection
/// - Date/time pickers with validation
/// - Image upload with crop feature
/// - Permission-based auto-approval
class CreateTripScreen extends ConsumerStatefulWidget {
  final String? tripId;
  
  const CreateTripScreen({super.key, this.tripId});

  @override
  ConsumerState<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends ConsumerState<CreateTripScreen> {
  int _currentStep = 0;
  final _formKeys = List.generate(4, (_) => GlobalKey<FormState>());
  
  // Loading states
  bool _isLoadingData = true;
  bool _isSubmitting = false;
  String? _errorMessage;
  
  // Step 1: Basic Info
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  int? _selectedLevelId;
  String? _tripImagePath;  // Local path to cropped image
  String? _tripImageUrl;   // Uploaded image URL
  bool _isUploadingImage = false;
  
  // Step 2: Schedule & Location
  DateTime? _startTime;
  DateTime? _endTime;
  DateTime? _cutOff;
  int? _selectedMeetingPointId;
  
  // Step 3: Capacity & Requirements
  final _capacityController = TextEditingController(text: '20');
  bool _allowWaitlist = true;
  final _requirementsController = TextEditingController();
  
  // Reference data from APIs
  List<Level> _levels = [];
  List<MeetingPoint> _meetingPoints = [];
  
  @override
  void initState() {
    super.initState();
    
    // Pre-fill requirements template
    _requirementsController.text = '''- 4x4 vehicle required
- Recovery gear mandatory
- Spare tire required
- First aid kit recommended
- Valid club membership''';
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadReferenceData();
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
  
  /// Load levels and meeting points from API
  Future<void> _loadReferenceData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load levels with aggressive debugging
      print('🔍 [CREATE TRIP] Fetching levels from API...');
      final levelsList = await repository.getLevels();
      print('🔍 [CREATE TRIP] Total levels in response: ${levelsList.length}');
      
      if (levelsList.isNotEmpty) {
        print('🔍 [CREATE TRIP] First level: ${levelsList[0]}');
      }
      
      // Parse with detailed logging
      List<Level> levels = [];
      for (var i = 0; i < levelsList.length; i++) {
        try {
          print('🔍 [CREATE TRIP] Parsing level $i...');
          final json = levelsList[i] as Map<String, dynamic>;
          final level = Level.fromJson(json);
          print('✅ [CREATE TRIP] Level $i parsed: ${level.name}, active: ${level.active}');
          if (level.active) {
            levels.add(level);
            print('✅ [CREATE TRIP] Level ${level.name} added to list');
          } else {
            print('⚠️ [CREATE TRIP] Level ${level.name} skipped (inactive)');
          }
        } catch (e, stack) {
          print('❌ [CREATE TRIP] Level $i parsing FAILED!');
          print('❌ [CREATE TRIP] Error: $e');
          print('❌ [CREATE TRIP] Stack: $stack');
          rethrow; // Re-throw to show in UI
        }
      }
      
      print('🔍 [CREATE TRIP] Total active levels: ${levels.length}');
      
      // Load meeting points
      print('🔍 [CREATE TRIP] Fetching meeting points...');
      final meetingPointsResponse = await repository.getMeetingPoints();
      final meetingPoints = (meetingPointsResponse as List<dynamic>?)
          ?.map((m) => MeetingPoint.fromJson(m as Map<String, dynamic>))
          .toList() ?? [];
      print('🔍 [CREATE TRIP] Meeting points loaded: ${meetingPoints.length}');
      
      if (!mounted) return;
      
      setState(() {
        _levels = levels;
        _meetingPoints = meetingPoints;
        _isLoadingData = false;
      });
      
      print('✅ [CREATE TRIP] Data loaded successfully!');
    } catch (e, stackTrace) {
      print('❌ [CREATE TRIP] EXCEPTION CAUGHT!');
      print('❌ [CREATE TRIP] Error: $e');
      print('❌ [CREATE TRIP] Stack: $stackTrace');
      
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Failed to load data: $e\n\nCheck browser console for details.';
        _isLoadingData = false;
      });
    }
  }
  
  /// Pick and crop trip image
  Future<void> _pickTripImage() async {
    try {
      setState(() => _isUploadingImage = true);
      
      final imageService = ref.read(imageUploadServiceProvider);
      
      // Pick image
      final pickedImage = await imageService.pickImage(source: ImageSource.gallery);
      if (pickedImage == null) {
        setState(() => _isUploadingImage = false);
        return;
      }
      
      if (kDebugMode) {
        print('📸 [CREATE TRIP] Image picked: ${pickedImage.path}');
      }
      
      // Crop image with 16:9 aspect ratio (landscape for trip cards)
      final croppedImage = await imageService.cropImage(
        pickedImage.path,
        aspectRatio: const CropAspectRatio(ratioX: 16, ratioY: 9),
        context: context,
      );
      
      if (croppedImage == null) {
        setState(() => _isUploadingImage = false);
        return;
      }
      
      if (kDebugMode) {
        print('✂️  [CREATE TRIP] Image cropped: ${croppedImage.path}');
      }
      
      // Store local path (will upload when submitting trip)
      setState(() {
        _tripImagePath = croppedImage.path;
        _isUploadingImage = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              kIsWeb 
                ? '✅ Image selected successfully!'
                : '✅ Image selected and cropped successfully!',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [CREATE TRIP] Error picking image: $e');
      }
      
      setState(() => _isUploadingImage = false);
      
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
  
  /// Remove selected trip image
  void _removeTripImage() {
    setState(() {
      _tripImagePath = null;
      _tripImageUrl = null;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Trip'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Create Trip'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadReferenceData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.tripId == null ? 'Create Trip' : 'Edit Trip'),
        actions: [
          if (_currentStep > 0)
            TextButton(
              onPressed: () => setState(() => _currentStep--),
              child: const Text('Back'),
            ),
        ],
      ),
      body: Stack(
        children: [
          Stepper(
            currentStep: _currentStep,
            onStepContinue: _currentStep < 3 ? _nextStep : null,
            onStepCancel: _currentStep > 0 ? () => setState(() => _currentStep--) : null,
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    if (_currentStep < 3)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                        child: const Text('Next'),
                      ),
                    if (_currentStep == 3)
                      ElevatedButton(
                        onPressed: _submitTrip,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Create Trip'),
                      ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('Basic Info'),
                subtitle: const Text('Title, description, difficulty'),
                content: _buildStep1BasicInfo(),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Schedule'),
                subtitle: const Text('Dates and meeting point'),
                content: _buildStep2Schedule(),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Capacity'),
                subtitle: const Text('Participants and requirements'),
                content: _buildStep3Capacity(),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
              ),
              Step(
                title: const Text('Review'),
                subtitle: const Text('Verify and submit'),
                content: _buildStep4Review(),
                isActive: _currentStep >= 3,
              ),
            ],
          ),
          
          // Loading overlay during submission
          if (_isSubmitting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Card(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Creating trip...'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Step 1: Basic Information
  Widget _buildStep1BasicInfo() {
    print('🔍 [BUILD] Step1 building with ${_levels.length} levels available');
    print('🔍 [BUILD] _isLoadingData = $_isLoadingData');
    
    return Form(
      key: _formKeys[0],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Trip Title *',
              hintText: 'e.g., Weekend Desert Adventure',
              prefixIcon: Icon(Icons.title),
              helperText: 'Short, descriptive name for your trip',
            ),
            maxLength: 200,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Title is required';
              }
              if (value.trim().length < 10) {
                return 'Title must be at least 10 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description *',
              hintText: 'Describe the route, difficulty, and what to expect...',
              prefixIcon: Icon(Icons.description),
              alignLabelWithHint: true,
              helperText: 'Detailed trip information',
            ),
            maxLines: 8,
            maxLength: 2000,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Description is required';
              }
              if (value.trim().length < 50) {
                return 'Description must be at least 50 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Difficulty Level
          DropdownButtonFormField<int>(
            value: _selectedLevelId,
            decoration: const InputDecoration(
              labelText: 'Difficulty Level *',
              prefixIcon: Icon(Icons.trending_up),
              helperText: 'Select appropriate skill level',
            ),
            // Selected value display (when dropdown is closed) - shows name only
            selectedItemBuilder: (BuildContext context) {
              return _levels.map((level) {
                return Text(level.name);
              }).toList();
            },
            // Dropdown items (when dropdown is open) - shows icon + name
            items: _levels.isEmpty 
              ? null  // Disable dropdown if no levels loaded
              : _levels.map((level) {
                  print('🔍 [DROPDOWN] Building item for level: ${level.name} (ID: ${level.id})');
                  return DropdownMenuItem(
                    value: level.id,
                    child: Row(
                      children: [
                        _buildLevelBadge(level),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(level.name),
                              if (level.description != null)
                                Text(
                                  level.description!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
            onChanged: _levels.isEmpty 
              ? null  // Disable onChanged if no levels
              : (value) {
                  print('🔍 [DROPDOWN] Level selected: $value');
                  setState(() => _selectedLevelId = value);
                },
            validator: (value) => value == null ? 'Level is required' : null,
          ),
          const SizedBox(height: 24),
          
          // Trip Image (Optional)
          const Text(
            'Trip Image (Optional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an image to make your trip more appealing',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          if (_tripImagePath != null)
            // Image preview with remove button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: kIsWeb
                      ? Image.network(
                          _tripImagePath!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(_tripImagePath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: IconButton(
                    onPressed: _removeTripImage,
                    icon: const Icon(Icons.close, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ],
            )
          else
            // Image picker button
            OutlinedButton.icon(
              onPressed: _isUploadingImage ? null : _pickTripImage,
              icon: _isUploadingImage
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_photo_alternate),
              label: Text(_isUploadingImage ? 'Processing...' : 'Add Trip Image'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Build level badge widget with icons
  Widget _buildLevelBadge(Level level) {
    Color badgeColor;
    Widget iconWidget;
    
    // Uniform icon size for consistency
    const double iconSize = 20.0;
    
    // Map level names to icons (case-insensitive)
    final levelName = level.name.toLowerCase();
    
    if (levelName.contains('club event')) {
      // Club Event (5) → Calendar/Event icon
      badgeColor = Colors.purple;
      iconWidget = const Icon(Icons.event, size: iconSize, color: Colors.purple);
    } else if (levelName.contains('anit') || level.numericLevel == 10) {
      // ANIT (10) → Education/School icon (learning/training)
      badgeColor = Colors.green;
      iconWidget = const Icon(Icons.school, size: iconSize, color: Colors.green);
    } else if (levelName.contains('newbie')) {
      // Newbie (10) → Halo star (star with border)
      badgeColor = Colors.amber;
      iconWidget = const Icon(Icons.star_border, size: iconSize, color: Colors.amber);
    } else if (levelName.contains('intermediate')) {
      // Intermediate (100) → Progress/Trending up icon
      badgeColor = Colors.blue;
      iconWidget = const Icon(Icons.trending_up, size: iconSize, color: Colors.blue);
    } else if (levelName.contains('advanced')) {
      // Advanced (200) → Racing/Speed icon
      badgeColor = Colors.deepOrange;
      iconWidget = const Icon(Icons.speed, size: iconSize, color: Colors.deepOrange);
    } else if (levelName.contains('explorer')) {
      // Explorer (400) → Explore/Compass icon (adventure)
      badgeColor = Colors.red;
      iconWidget = const Icon(Icons.explore, size: iconSize, color: Colors.red);
    } else if (levelName.contains('marshal')) {
      // Marshal (600) → Shield icon (ORANGE)
      badgeColor = Colors.orange;
      iconWidget = const Icon(Icons.shield, size: iconSize, color: Colors.orange);
    } else if (levelName.contains('board')) {
      // Board Member (800) → Crown/Admin icon
      badgeColor = Colors.indigo;
      iconWidget = const Icon(Icons.workspace_premium, size: iconSize, color: Colors.indigo);
    } else {
      // Default fallback
      badgeColor = Colors.grey;
      iconWidget = Text(
        level.numericLevel.toString(),
        style: const TextStyle(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1.5),
      ),
      child: iconWidget,
    );
  }
  
  /// Step 2: Schedule & Location
  Widget _buildStep2Schedule() {
    return Form(
      key: _formKeys[1],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Start Date/Time
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Start Date & Time *'),
              subtitle: Text(
                _startTime != null
                    ? DateFormat('EEE, MMM d, y - h:mm a').format(_startTime!)
                    : 'Tap to select start time',
                style: TextStyle(
                  color: _startTime != null ? null : Colors.grey,
                ),
              ),
              trailing: _startTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _startTime = null),
                    )
                  : null,
              onTap: _selectStartTime,
            ),
          ),
          const SizedBox(height: 8),
          
          // End Date/Time
          Card(
            child: ListTile(
              leading: const Icon(Icons.event),
              title: const Text('End Date & Time *'),
              subtitle: Text(
                _endTime != null
                    ? DateFormat('EEE, MMM d, y - h:mm a').format(_endTime!)
                    : 'Tap to select end time',
                style: TextStyle(
                  color: _endTime != null ? null : Colors.grey,
                ),
              ),
              trailing: _endTime != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endTime = null),
                    )
                  : null,
              onTap: _selectEndTime,
            ),
          ),
          const SizedBox(height: 8),
          
          // Registration Cutoff
          Card(
            child: ListTile(
              leading: const Icon(Icons.alarm),
              title: const Text('Registration Cutoff'),
              subtitle: Text(
                _cutOff != null
                    ? DateFormat('EEE, MMM d, y - h:mm a').format(_cutOff!)
                    : 'Defaults to 24h before start',
                style: TextStyle(
                  color: _cutOff != null ? null : Colors.grey,
                ),
              ),
              trailing: _cutOff != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _cutOff = null),
                    )
                  : null,
              onTap: _selectCutOffTime,
            ),
          ),
          const SizedBox(height: 16),
          
          // Meeting Point - Searchable
          Autocomplete<MeetingPoint>(
            optionsBuilder: (TextEditingValue textEditingValue) {
              if (textEditingValue.text.isEmpty) {
                return _meetingPoints;
              }
              return _meetingPoints.where((mp) {
                return mp.name.toLowerCase().contains(textEditingValue.text.toLowerCase()) ||
                    (mp.area?.toLowerCase().contains(textEditingValue.text.toLowerCase()) ?? false);
              });
            },
            displayStringForOption: (MeetingPoint mp) => mp.name,
            onSelected: (MeetingPoint mp) {
              setState(() => _selectedMeetingPointId = mp.id);
            },
            fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
              // Set initial value if already selected
              if (_selectedMeetingPointId != null && controller.text.isEmpty) {
                final selectedMp = _meetingPoints.where((mp) => mp.id == _selectedMeetingPointId).firstOrNull;
                if (selectedMp != null) {
                  controller.text = selectedMp.name;
                }
              }
              
              return TextFormField(
                controller: controller,
                focusNode: focusNode,
                decoration: const InputDecoration(
                  labelText: 'Meeting Point *',
                  prefixIcon: Icon(Icons.location_on),
                  helperText: 'Start typing to search...',
                  suffixIcon: Icon(Icons.search),
                ),
                validator: (value) {
                  if (_selectedMeetingPointId == null) {
                    return 'Please select a meeting point';
                  }
                  return null;
                },
                onFieldSubmitted: (value) => onFieldSubmitted(),
              );
            },
            optionsViewBuilder: (context, onSelected, options) {
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  child: Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    width: MediaQuery.of(context).size.width - 32,
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final mp = options.elementAt(index);
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: const Icon(Icons.location_on, size: 20),
                          title: Text(mp.name),
                          subtitle: mp.area != null ? Text(mp.area!, style: const TextStyle(fontSize: 12)) : null,
                          dense: true,
                          onTap: () => onSelected(mp),
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
  
  /// Select start time
  Future<void> _selectStartTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_startTime ?? DateTime.now()),
      );
      
      if (time != null && mounted) {
        setState(() {
          _startTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
          
          // Auto-set cutoff to 24h before if not set
          if (_cutOff == null && _startTime != null) {
            _cutOff = _startTime!.subtract(const Duration(hours: 24));
          }
        });
      }
    }
  }
  
  /// Select end time
  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime ?? _startTime ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: _startTime ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_endTime ?? DateTime.now()),
      );
      
      if (time != null && mounted) {
        setState(() {
          _endTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  /// Select cutoff time
  Future<void> _selectCutOffTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _cutOff ?? (_startTime ?? DateTime.now()).subtract(const Duration(hours: 24)),
      firstDate: DateTime.now(),
      lastDate: _startTime ?? DateTime.now().add(const Duration(days: 365)),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_cutOff ?? DateTime.now()),
      );
      
      if (time != null && mounted) {
        setState(() {
          _cutOff = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }
  
  /// Step 3: Capacity & Requirements
  Widget _buildStep3Capacity() {
    return Form(
      key: _formKeys[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Capacity
          TextFormField(
            controller: _capacityController,
            decoration: const InputDecoration(
              labelText: 'Maximum Participants *',
              prefixIcon: Icon(Icons.people),
              suffixText: 'vehicles',
              helperText: 'Number of vehicles that can join',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Capacity is required';
              }
              final capacity = int.tryParse(value);
              if (capacity == null || capacity < 1 || capacity > 100) {
                return 'Capacity must be between 1 and 100';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          
          // Allow Waitlist
          Card(
            child: SwitchListTile(
              title: const Text('Allow Waitlist'),
              subtitle: const Text(
                'Let members join waitlist when trip is full',
              ),
              secondary: const Icon(Icons.list),
              value: _allowWaitlist,
              onChanged: (value) => setState(() => _allowWaitlist = value),
            ),
          ),
          const SizedBox(height: 16),
          
          // Requirements
          TextFormField(
            controller: _requirementsController,
            decoration: const InputDecoration(
              labelText: 'Special Requirements',  
              prefixIcon: Icon(Icons.checklist),
              alignLabelWithHint: true,
              helperText: 'One requirement per line',
            ),
            maxLines: 10,
            maxLength: 1000,
          ),
        ],
      ),
    );
  }
  
  /// Step 4: Leadership (Deputy Selection)
  /// Step 4: Review & Submit
  Widget _buildStep4Review() {
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review Trip Details',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Please review all information before submitting',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 16),
        
        // Basic Info
        _buildReviewCard(
          'Basic Information',
          [
            _buildReviewRow('Title', _titleController.text),
            _buildReviewRow('Description', _descriptionController.text, maxLines: 3),
            _buildReviewRow(
              'Level',
              _selectedLevelId != null
                  ? (_levels.where((l) => l.id == _selectedLevelId).firstOrNull?.name ?? 'Unknown Level')
                  : 'Not selected',
            ),
          ],
        ),
        
        // Schedule
        _buildReviewCard(
          'Schedule & Location',
          [
            _buildReviewRow(
              'Start',
              _startTime != null
                  ? DateFormat('EEE, MMM d, y - h:mm a').format(_startTime!)
                  : 'Not set',
            ),
            _buildReviewRow(
              'End',
              _endTime != null
                  ? DateFormat('EEE, MMM d, y - h:mm a').format(_endTime!)
                  : 'Not set',
            ),
            if (_cutOff != null)
              _buildReviewRow(
                'Cutoff',
                DateFormat('EEE, MMM d, y - h:mm a').format(_cutOff!),
              ),
            _buildReviewRow(
              'Meeting Point',
              _selectedMeetingPointId != null
                  ? (_meetingPoints.where((mp) => mp.id == _selectedMeetingPointId).firstOrNull?.name ?? 'Unknown Location')
                  : 'Not selected',
            ),
          ],
        ),
        
        // Capacity
        _buildReviewCard(
          'Capacity & Requirements',
          [
            _buildReviewRow('Max Participants', '${_capacityController.text} vehicles'),
            _buildReviewRow('Allow Waitlist', _allowWaitlist ? 'Yes' : 'No'),
            if (_requirementsController.text.trim().isNotEmpty)
              _buildReviewRow('Requirements', _requirementsController.text, maxLines: 5),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Approval info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  currentUser?.hasPermission('create_trip') == true
                      ? 'Your trip will be automatically approved and visible to all members.'
                      : 'Your trip will be submitted for board approval before becoming visible to members.',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build review card widget
  Widget _buildReviewCard(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
  
  /// Build review row widget
  Widget _buildReviewRow(String label, String value, {int maxLines = 2}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: maxLines,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Validate current step and move to next
  void _nextStep() {
    // Validate current step (except step 3 which is review-only)
    if (_currentStep == 3) {
      // Step 4 (index 3) is review-only, no validation needed
      setState(() => _currentStep++);
      return;
    }
    
    if (_formKeys[_currentStep].currentState?.validate() ?? false) {
      // Additional validation for step 2 (dates)
      if (_currentStep == 1) {
        if (_startTime == null || _endTime == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select both start and end times'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (_endTime!.isBefore(_startTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('End time must be after start time'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (_cutOff != null && _cutOff!.isAfter(_startTime!)) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cutoff time must be before start time'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
      setState(() => _currentStep++);
    }
  }
  
  /// Submit trip to API
  Future<void> _submitTrip() async {
    // Validate all steps except step 4 (index 3) which is review-only
    for (var i = 0; i < _formKeys.length; i++) {
      // Skip step 4 (index 3) - it's review-only, no form validation needed
      if (i == 3) continue;
      
      if (!(_formKeys[i].currentState?.validate() ?? false)) {
        setState(() => _currentStep = i);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please complete step ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    // Final validation
    if (_startTime == null || _endTime == null) {
      setState(() => _currentStep = 1);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end times'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    setState(() => _isSubmitting = true);
    
    // Parse requirements
    final requirements = _requirementsController.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    
    // Get current user as lead
    final currentUserId = ref.read(authProviderV2).user?.id;
    if (currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User not authenticated'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }
    
    // Prepare trip data according to API documentation
    // See: docs/API_QUERY_PARAMETERS.md and backend API docs
    final tripData = {
      'lead': currentUserId,  // REQUIRED: Current user as trip lead
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'startTime': _startTime!.toIso8601String(),  // camelCase as per API
      'endTime': _endTime!.toIso8601String(),  // camelCase as per API
      'cutOff': (_cutOff ?? _startTime!.subtract(const Duration(hours: 24))).toIso8601String(),  // REQUIRED: default to 24h before start
      'capacity': int.parse(_capacityController.text),
      'level': _selectedLevelId,
      'allowWaitlist': _allowWaitlist,  // camelCase as per API
      // ⚠️ NOTE: Image field temporarily disabled - backend expects file upload, not blob URL
      // TODO: Implement proper image upload endpoint integration
      // 'image': _tripImagePath ?? '',  // DISABLED: Blob URL causes "not a file" error
      if (_selectedMeetingPointId != null) 'meetingPoint': _selectedMeetingPointId,  // camelCase
      // Note: requirements not in API spec, might be rejected
    };
    
    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final authState = ref.read(authProviderV2);
      
      print('📝 [CREATE TRIP] Sending trip data: $tripData');
      print('🔐 [CREATE TRIP] User permissions: ${authState.user?.permissions}');
      print('🔐 [CREATE TRIP] User level: ${authState.user?.level}');
      
      // Create trip
      final response = await repository.createTrip(tripData);
      
      print('✅ [CREATE TRIP] Trip created successfully: $response');
      
      if (mounted) {
        // Backend returns: {success: true, message: {id: 6288, approvalStatus: "A", ...}}
        // Extract the trip data from the "message" field
        final tripData = response['message'] as Map<String, dynamic>?;
        final tripId = tripData?['id'] as int?;
        final approvalStatus = tripData?['approvalStatus'] as String?;
        
        setState(() => _isSubmitting = false);
        
        // Show success dialog
        if (tripId != null) {
          _showSuccessDialog(tripId, approvalStatus);
        } else {
          // Fallback: Show generic success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Trip created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('❌ [CREATE TRIP] Error creating trip: $e');
      print('❌ [CREATE TRIP] Stack trace: $stackTrace');
      
      if (mounted) {
        setState(() => _isSubmitting = false);
        
        // Parse error message for user-friendly feedback
        String errorMessage = 'Failed to create trip';
        if (e.toString().contains('405')) {
          errorMessage = 'Method not allowed. Please check your permissions.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Authentication error. Please log in again.';
        } else if (e.toString().contains('403')) {
          errorMessage = 'Permission denied. You may need create_trip permission.';
        } else if (e.toString().contains('400')) {
          errorMessage = 'Invalid data. Please check all fields.';
        } else {
          errorMessage = 'Something went wrong: ${e.toString()}';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Details',
              textColor: Colors.white,
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Error Details'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(e.toString()),
                          const SizedBox(height: 16),
                          const Text('Data sent:', style: TextStyle(fontWeight: FontWeight.bold)),
                          Text(tripData.toString()),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      }
    }
  }
  
  /// Show success dialog after trip creation
  void _showSuccessDialog(int tripId, String? approvalStatus) {
    // ✅ FIXED: Use status helper to correctly check approval status
    // Backend returns "A" for approved, not "approved"
    final tripIsApproved = approvalStatus == 'A';
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              tripIsApproved ? Icons.check_circle : Icons.pending,
              color: tripIsApproved ? Colors.green : Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(tripIsApproved ? 'Trip Created!' : 'Trip Submitted'),
          ],
        ),
        content: Text(
          tripIsApproved
              ? 'Your trip has been created and is now visible to all members. Members can now register to join!'
              : 'Your trip has been submitted for board approval. You will be notified once it is reviewed.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.go('/trips'); // Go to trips list
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              context.push('/trips/$tripId'); // View created trip
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('View Trip'),
          ),
        ],
      ),
    );
  }
}
