import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../data/models/geocoding_result.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/here_maps_settings_provider.dart';
import '../../../../core/providers/here_maps_service_provider.dart';
import '../../../../core/constants/meeting_point_constants.dart';

/// Admin Meeting Point Form Screen
/// 
/// Create or edit meeting points.
/// Features:
/// - Create new meeting point
/// - Edit existing meeting point
/// - Field validation
/// - GPS coordinates input
/// - Google Maps link input
class AdminMeetingPointFormScreen extends ConsumerStatefulWidget {
  final int? meetingPointId; // null for create, ID for edit

  const AdminMeetingPointFormScreen({
    super.key,
    this.meetingPointId,
  });

  bool get isEditing => meetingPointId != null;

  @override
  ConsumerState<AdminMeetingPointFormScreen> createState() => _AdminMeetingPointFormScreenState();
}

class _AdminMeetingPointFormScreenState extends ConsumerState<AdminMeetingPointFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  // Form controllers
  late TextEditingController _nameController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _linkController;

  // Smart area detection state
  String? _selectedAreaCode; // Area code (DXB, AUH, etc.)
  GeocodingResult? _hereMapsLocation; // HERE Maps detailed location
  bool _isDetectingArea = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _latController = TextEditingController();
    _lonController = TextEditingController();
    _linkController = TextEditingController();
    
    if (widget.isEditing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadMeetingPoint();
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  /// Fetch location from Here Maps using coordinates with smart area detection
  Future<void> _fetchLocationFromHereMaps() async {
    // Validate coordinates are provided
    if (_latController.text.trim().isEmpty || _lonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please enter latitude and longitude first'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isDetectingArea = true;
    });

    try {
      final lat = double.parse(_latController.text.trim());
      final lon = double.parse(_lonController.text.trim());

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('🗺️ Detecting location and area...'),
              ],
            ),
            duration: Duration(seconds: 10),
          ),
        );
      }

      // Get Here Maps settings and service
      final settingsNotifier = ref.read(hereMapsSettingsProvider.notifier);
      final settings = settingsNotifier.getSettingsOrDefault();
      final service = ref.read(hereMapsServiceProvider);

      // Call Here Maps API with structured response
      final result = await service.reverseGeocodeWithFields(
        lat: lat,
        lon: lon,
        settings: settings,
      );

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Check if we got data
      if (!result.isValid) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ No location data available for these coordinates'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
        }
        
        setState(() {
          _hereMapsLocation = null;
          _selectedAreaCode = null;
          _isDetectingArea = false;
        });
        return;
      }

      // Smart area code detection
      final detectedCode = MeetingPointConstants.detectAreaCode(
        result.city,
        result.district,
      );

      // Validate detection
      final validation = MeetingPointConstants.validateAreaCodeDetection(
        result.city,
        result.district,
      );

      setState(() {
        _hereMapsLocation = result;
        _selectedAreaCode = detectedCode;
        _isDetectingArea = false;
      });

      // Show success message with detection info
      if (mounted) {
        final confidenceIcon = validation['confidence'] == 'high' 
            ? '✅' 
            : validation['confidence'] == 'medium' 
                ? '⚠️' 
                : '❓';
        
        final message = detectedCode != null
            ? '$confidenceIcon Location: ${result.area}\\nArea: ${MeetingPointConstants.getAreaName(detectedCode)}'
            : '⚠️ Location: ${result.area}\\nCould not auto-detect area';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: detectedCode != null ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } on FormatException {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Invalid coordinates format'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isDetectingArea = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to fetch location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isDetectingArea = false;
      });
    }
  }

  Future<void> _loadMeetingPoint() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final data = await repository.getMeetingPoints();
      final results = data['results'] as List<dynamic>? ?? [];
      final meetingPoints = results
          .map((json) => MeetingPoint.fromJson(json as Map<String, dynamic>))
          .toList();
      
      final meetingPoint = meetingPoints.firstWhere(
        (mp) => mp.id == widget.meetingPointId,
        orElse: () => throw Exception('Meeting point not found'),
      );

      setState(() {
        // Populate form
        _nameController.text = meetingPoint.name;
        _selectedAreaCode = meetingPoint.area; // Area code from database
        _latController.text = meetingPoint.lat ?? '';
        _lonController.text = meetingPoint.lon ?? '';
        _linkController.text = meetingPoint.link ?? '';
        
        _isLoading = false;
      });

      // Auto-fetch HERE Maps location if coordinates are available
      // This populates the location context and validates/suggests area code
      if (meetingPoint.lat != null &&
          meetingPoint.lon != null &&
          meetingPoint.lat!.isNotEmpty &&
          meetingPoint.lon!.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fetchLocationFromHereMaps();
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load meeting point: ${e.toString()}';
        _isLoading = false;
      });
    }
  }



  Future<void> _saveMeetingPoint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate area code is selected
    if (_selectedAreaCode == null || _selectedAreaCode!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Please select an area or fetch location from coordinates'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      final lat = _latController.text.trim();
      final lon = _lonController.text.trim();
      final link = _linkController.text.trim();
      
      // Prepare data - only send area code (not HERE Maps descriptive text)
      // Convert empty strings to null for optional fields
      final areaCode = _selectedAreaCode; // Area code (DXB, AUH, etc.)
      final latValue = lat.isNotEmpty ? lat : null;
      final lonValue = lon.isNotEmpty ? lon : null;
      final linkValue = link.isNotEmpty ? link : null;

      if (widget.isEditing) {
        // Update existing meeting point
        await repository.updateMeetingPoint(
          id: widget.meetingPointId!,
          name: _nameController.text.trim(),
          area: areaCode,  // Save only area code
          lat: latValue,
          lon: lonValue,
          link: linkValue,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Meeting point updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true); // Return success
        }
      } else {
        // Create new meeting point
        await repository.createMeetingPoint(
          name: _nameController.text.trim(),
          area: areaCode,  // Save only area code
          lat: latValue,
          lon: lonValue,
          link: linkValue,
        );
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Meeting point created successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(true);
        }
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
                  ? '🚫 You are not authorized to ${widget.isEditing ? 'edit' : 'create'} meeting points'
                  : '❌ Failed to ${widget.isEditing ? 'update' : 'create'} meeting point: ${e.toString()}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;
    
    // Check permission based on mode (create vs edit)
    final requiredPermission = widget.isEditing ? 'edit_meeting_points' : 'create_meeting_points';
    final hasPermission = user?.hasPermission(requiredPermission) ?? false;
    
    if (!hasPermission) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin/meeting-points'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                widget.isEditing ? 'Edit Permission Required' : 'Create Permission Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                widget.isEditing 
                    ? 'You do not have permission to edit meeting points.'
                    : 'You do not have permission to create meeting points.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin/meeting-points'),
                child: const Text('Back to Meeting Points'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Meeting Point' : 'Add Meeting Point'),
        actions: [
          if (!_isLoading && !_isSaving)
            TextButton(
              onPressed: _saveMeetingPoint,
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
              onPressed: _loadMeetingPoint,
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
          _buildLocationSection(),
          const SizedBox(height: 24),
          _buildMapLinkSection(),
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
            
            // Meeting Point Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'e.g., ADNOC Gas Station - E11',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // HERE Maps Location Display (Read-only context)
            if (_hereMapsLocation != null && _hereMapsLocation!.isValid) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Detected Location:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hereMapsLocation!.area,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            
            // Area Code Dropdown (Required field)
            DropdownButtonFormField<String>(
              value: _selectedAreaCode,
              decoration: InputDecoration(
                labelText: 'Area *',
                hintText: 'Select area or fetch from coordinates',
                border: const OutlineInputBorder(),
                helperText: _hereMapsLocation != null 
                    ? '✅ Auto-detected from coordinates'
                    : 'Select manually or click "Fetch Location" below',
                helperMaxLines: 2,
              ),
              items: MeetingPointConstants.areaNames.entries.map((entry) {
                return DropdownMenuItem<String>(
                  value: entry.key,
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: MeetingPointConstants.getAreaColor(entry.key),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(entry.value),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAreaCode = value;
                });
              },
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please select an area';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GPS Coordinates',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Enter GPS coordinates for accurate location',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _latController,
              decoration: const InputDecoration(
                labelText: 'Latitude',
                hintText: 'e.g., 24.4539',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gps_fixed),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final lat = double.tryParse(value);
                  if (lat == null || lat < -90 || lat > 90) {
                    return 'Please enter valid latitude (-90 to 90)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lonController,
              decoration: const InputDecoration(
                labelText: 'Longitude',
                hintText: 'e.g., 54.3773',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.gps_fixed),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  final lon = double.tryParse(value);
                  if (lon == null || lon < -180 || lon > 180) {
                    return 'Please enter valid longitude (-180 to 180)';
                  }
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            
            // Fetch Location Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isDetectingArea ? null : _fetchLocationFromHereMaps,
                icon: _isDetectingArea 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.location_searching),
                label: Text(_isDetectingArea 
                    ? 'Detecting Location...' 
                    : '📍 Fetch Location & Auto-Detect Area'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLinkSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Google Maps Link',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Optional: Add Google Maps link for easy navigation',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _linkController,
              decoration: const InputDecoration(
                labelText: 'Google Maps Link',
                hintText: 'https://maps.google.com/...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.map),
              ),
              keyboardType: TextInputType.url,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!value.startsWith('http://') && !value.startsWith('https://')) {
                    return 'Please enter a valid URL';
                  }
                }
                return null;
              },
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
        onPressed: _isSaving ? null : _saveMeetingPoint,
        icon: _isSaving
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Icon(widget.isEditing ? Icons.save : Icons.add),
        label: Text(
          _isSaving
              ? 'Saving...'
              : widget.isEditing
                  ? 'Save Changes'
                  : 'Create Meeting Point',
        ),
      ),
    );
  }
}
