import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/widgets.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _makeController = TextEditingController();
  final _modelController = TextEditingController();
  final _yearController = TextEditingController();
  final _plateController = TextEditingController();
  final _colorController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _makeController.dispose();
    _modelController.dispose();
    _yearController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // TODO: Implement actual API call to save vehicle
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() => _isLoading = false);
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Vehicle "${_makeController.text} ${_modelController.text}" added successfully!',
          ),
          backgroundColor: Colors.green,
        ),
      );
      
      // Navigate back
      context.pop();
    }
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Year is required';
    }
    
    final year = int.tryParse(value);
    if (year == null) {
      return 'Please enter a valid year';
    }
    
    final currentYear = DateTime.now().year;
    if (year < 1900 || year > currentYear + 1) {
      return 'Please enter a valid year (1900-${currentYear + 1})';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Add Vehicle',
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.directions_car,
                  size: 40,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Description
              Text(
                'Add your vehicle details',
                style: TextStyle(
                  color: colors.onSurface,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Make
              CustomTextField(
                controller: _makeController,
                label: 'Make',
                hint: 'e.g., Toyota, Nissan, Land Rover',
                prefixIcon: const Icon(Icons.business),
                validator: (value) => _validateRequired(value, 'Make'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Model
              CustomTextField(
                controller: _modelController,
                label: 'Model',
                hint: 'e.g., Land Cruiser, Patrol, Defender',
                prefixIcon: const Icon(Icons.local_offer),
                validator: (value) => _validateRequired(value, 'Model'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Year
              CustomTextField(
                controller: _yearController,
                label: 'Year',
                hint: 'e.g., 2024',
                prefixIcon: const Icon(Icons.calendar_today),
                keyboardType: TextInputType.number,
                validator: _validateYear,
              ),
              const SizedBox(height: 16),

              // Plate Number
              CustomTextField(
                controller: _plateController,
                label: 'Plate Number',
                hint: 'e.g., A 12345',
                prefixIcon: const Icon(Icons.pin),
                validator: (value) => _validateRequired(value, 'Plate Number'),
                textCapitalization: TextCapitalization.characters,
              ),
              const SizedBox(height: 16),

              // Color (Optional)
              CustomTextField(
                controller: _colorController,
                label: 'Color (Optional)',
                hint: 'e.g., White, Black, Silver',
                prefixIcon: const Icon(Icons.palette),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),

              // Notes (Optional)
              CustomTextField(
                controller: _notesController,
                label: 'Notes (Optional)',
                hint: 'Any additional information about your vehicle',
                prefixIcon: const Icon(Icons.notes),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Save Button
              PrimaryButton(
                text: 'Add Vehicle',
                onPressed: _handleSaveVehicle,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 16),

              // Cancel Button
              TextButton(
                onPressed: _isLoading ? null : () => context.pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
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
