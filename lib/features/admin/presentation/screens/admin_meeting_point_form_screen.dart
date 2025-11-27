import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/meeting_point_model.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/here_maps_settings_provider.dart';
import '../../../../core/providers/here_maps_service_provider.dart';

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
  late TextEditingController _areaController;
  late TextEditingController _latController;
  late TextEditingController _lonController;
  late TextEditingController _linkController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _areaController = TextEditingController();
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
    _areaController.dispose();
    _latController.dispose();
    _lonController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  /// Fetch location from Here Maps using coordinates
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

    try {
      final lat = double.parse(_latController.text.trim());
      final lon = double.parse(_lonController.text.trim());

      // Show loading indicator
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
              Text('🗺️ Fetching location from Here Maps...'),
            ],
          ),
          duration: Duration(seconds: 10),
        ),
      );

      // Get Here Maps settings and service
      final settingsNotifier = ref.read(hereMapsSettingsProvider.notifier);
      final settings = settingsNotifier.getSettingsOrDefault();
      final service = ref.read(hereMapsServiceProvider);

      // Call Here Maps API
      final areaValue = await service.reverseGeocode(
        lat: lat,
        lon: lon,
        settings: settings,
      );

      // Hide loading snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
      }

      // Check if we got data
      if (areaValue.isEmpty) {
        // No data - show warning with selected field names
        final fieldNames = settings.selectedFields
            .map((f) => f.displayName)
            .join(', ');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('⚠️ No data available for: $fieldNames'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        
        // Leave area field blank
        setState(() {
          _areaController.text = '';
        });
      } else {
        // Got data - update field and show success
        setState(() {
          _areaController.text = areaValue;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Location fetched: $areaValue'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } on FormatException {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Invalid coordinates format'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to fetch location: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
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
        _areaController.text = meetingPoint.area ?? '';
        _latController.text = meetingPoint.lat ?? '';
        _lonController.text = meetingPoint.lon ?? '';
        _linkController.text = meetingPoint.link ?? '';
        
        _isLoading = false;
      });

      // Auto-fetch area if empty and coordinates are available
      if ((meetingPoint.area == null || meetingPoint.area!.isEmpty) &&
          meetingPoint.lat != null &&
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

  /// Reverse geocode lat/lon to get area name using HERE Maps backend
  Future<String> _getAreaFromCoordinates(String lat, String lon) async {
    try {
      // Get HERE Maps settings and service
      final settingsNotifier = ref.read(hereMapsSettingsProvider.notifier);
      final settings = settingsNotifier.getSettingsOrDefault();
      final service = ref.read(hereMapsServiceProvider);

      // Call HERE Maps backend API
      final areaValue = await service.reverseGeocode(
        lat: double.parse(lat),
        lon: double.parse(lon),
        settings: settings,
      );

      // Return the formatted area string from backend
      return areaValue;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ HERE Maps geocoding error: $e');
      }
      return ''; // Return empty string on error
    }
  }

  Future<void> _saveMeetingPoint() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Auto-populate area from coordinates if provided
      String areaValue = _areaController.text.trim();
      final lat = _latController.text.trim();
      final lon = _lonController.text.trim();
      
      // If coordinates are provided, fetch area name
      if (lat.isNotEmpty && lon.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🔍 Getting area name from coordinates...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        final fetchedArea = await _getAreaFromCoordinates(lat, lon);
        if (fetchedArea.isNotEmpty) {
          areaValue = fetchedArea;
        }
      }
      
      final data = {
        'name': _nameController.text.trim(),
        'area': areaValue,
        'lat': lat,
        'lon': lon,
        'link': _linkController.text.trim(),
      };

      if (widget.isEditing) {
        // Update existing meeting point using PUT endpoint
        // Use the fetched areaValue (from HERE Maps) instead of controller text
        await repository.updateMeetingPoint(
          id: widget.meetingPointId!,
          name: data['name'] as String,
          area: data['area'] as String?,  // This is the fetched area from HERE Maps
          lat: data['lat'] as String?,
          lon: data['lon'] as String?,
          link: data['link'] as String?,
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
        await repository.createMeetingPoint(
          name: data['name'] as String,
          area: data['area'] as String?,
          lat: data['lat'] as String?,
          lon: data['lon'] as String?,
          link: data['link'] as String?,
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
            TextFormField(
              controller: _areaController,
              decoration: InputDecoration(
                labelText: 'Area',
                hintText: 'Will be populated automatically',
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                suffixIcon: IconButton(
                  icon: const Icon(Icons.location_searching),
                  onPressed: _fetchLocationFromHereMaps,
                  tooltip: 'Fetch location from Here Maps',
                ),
                helperText: '🗺️ Automatically Populated from Here Maps',
                helperMaxLines: 2,
              ),
              readOnly: true,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontStyle: FontStyle.italic,
              ),
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
