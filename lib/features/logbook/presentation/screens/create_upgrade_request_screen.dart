import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../data/models/level_model.dart';

/// Create Upgrade Request Screen
/// 
/// Form for members to submit upgrade requests
class CreateUpgradeRequestScreen extends ConsumerStatefulWidget {
  const CreateUpgradeRequestScreen({super.key});

  @override
  ConsumerState<CreateUpgradeRequestScreen> createState() => _CreateUpgradeRequestScreenState();
}

class _CreateUpgradeRequestScreenState extends ConsumerState<CreateUpgradeRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final MainApiRepository _repository = MainApiRepository();
  final TextEditingController _reasonController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  
  List<Level> _levels = [];
  int? _selectedLevelId;
  bool _isLoadingLevels = true;
  bool _isSubmitting = false;
  XFile? _selectedFile;

  @override
  void initState() {
    super.initState();
    _loadLevels();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      
      if (file != null) {
        // Check file size (max 10MB)
        final fileSize = await file.length();
        if (fileSize > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }
        
        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _loadLevels() async {
    try {
      final levelsData = await _repository.getLevels();
      setState(() {
        _levels = levelsData
            .map((json) => Level.fromJson(json as Map<String, dynamic>))
            .where((level) => level.active) // Only show active levels
            .toList();
        _levels.sort((a, b) => a.numericLevel.compareTo(b.numericLevel));
        _isLoadingLevels = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load levels: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _isLoadingLevels = false;
      });
    }
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLevelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a target level'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final authState = ref.read(authProviderV2);
      final userId = authState.user?.id;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Create upgrade request
      await _repository.createUpgradeRequest(
        memberId: userId,
        requestedLevel: _selectedLevelId!.toString(),
        reason: _reasonController.text.trim(),
        supportingDocument: _selectedFile,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade request submitted successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        
        // ✅ FIXED: Navigate back with result to trigger reload
        context.pop(true);  // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit request: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Level Upgrade'),
      ),
      body: _isLoadingLevels
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Info Card
                    Card(
                      color: colors.primaryContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: colors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Submit your request to advance your off-road certification level',
                                style: TextStyle(
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Target Level Selector
                    Text(
                      'Target Level',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the level you wish to upgrade to',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    DropdownButtonFormField<int>(
                      initialValue: _selectedLevelId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.trending_up),
                        hintText: 'Select target level',
                        filled: true,
                        fillColor: colors.surface,
                      ),
                      items: _levels.map((level) {
                        return DropdownMenuItem<int>(
                          value: level.id,
                          child: Text(level.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedLevelId = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select a target level';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Reason Field
                    Text(
                      'Reason for Upgrade',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Explain why you\'re ready for this upgrade. Include relevant experience, skills demonstrated, and trips completed.',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    TextFormField(
                      controller: _reasonController,
                      maxLines: 8,
                      maxLength: 1000,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        hintText: 'e.g., I have completed 15 Level 3 trips, demonstrated recovery skills on 10+ occasions, and consistently help newer members...',
                        filled: true,
                        fillColor: colors.surface,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please provide a reason for your upgrade request';
                        }
                        if (value.trim().length < 50) {
                          return 'Please provide at least 50 characters explaining your qualifications';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Supporting Document / Attachment Section
                    Text(
                      'Supporting Document (Optional)',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Attach a document to support your upgrade request (e.g., certificates, training records, trip photos)',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    if (_selectedFile != null) ...[
                      // File preview card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.attach_file, color: colors.primary, size: 32),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _selectedFile!.name,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: colors.onSurface,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  FutureBuilder<int>(
                                    future: _selectedFile!.length(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        final sizeInKB = (snapshot.data! / 1024).round();
                                        final sizeText = sizeInKB < 1024
                                            ? '$sizeInKB KB'
                                            : '${(sizeInKB / 1024).toStringAsFixed(1)} MB';
                                        return Text(
                                          sizeText,
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: colors.onSurface.withValues(alpha: 0.6),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              color: colors.error,
                              onPressed: _removeFile,
                              tooltip: 'Remove file',
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // File picker button
                      OutlinedButton.icon(
                        onPressed: _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Attach Document'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          side: BorderSide(color: colors.primary),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Max file size: 10MB • Supported formats: JPG, PNG',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 24),
                    
                    // Guidelines Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.lightbulb_outline, color: colors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Upgrade Guidelines',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            const Text('• Document your completed trips at the target level'),
                            const Text('• Highlight specific skills you\'ve mastered'),
                            const Text('• Mention any advanced training or courses'),
                            const Text('• Show consistent safety and helping behaviors'),
                            const Text('• Be specific with examples and dates'),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _submitRequest,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Request'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: colors.primary,
                          foregroundColor: colors.onPrimary,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // What happens next
                    Card(
                      color: colors.surfaceContainerHighest,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'What happens next?',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '1. Your request will be reviewed by the board\n'
                              '2. Nominated marshals will vote on your request\n'
                              '3. You\'ll receive a notification with the decision\n'
                              '4. If approved, your level will be updated immediately',
                              style: TextStyle(fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
