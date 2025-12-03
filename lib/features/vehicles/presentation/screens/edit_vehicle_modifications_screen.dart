import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/vehicle_modifications_cache_service.dart';
import '../../../../data/models/vehicle_modifications_model.dart';
import '../../../../shared/widgets/badges/verification_status_badge.dart';
import '../../../../shared/widgets/dialogs/verification_method_dialog.dart';

/// Edit Vehicle Modifications Screen
/// 
/// Allows members to declare their vehicle modifications.
/// Modifications must be verified by a marshal before becoming active.

class EditVehicleModificationsScreen extends StatefulWidget {
  final int vehicleId;
  final int memberId;
  final String? vehicleName; // e.g., "Jeep Gladiator"

  const EditVehicleModificationsScreen({
    super.key,
    required this.vehicleId,
    required this.memberId,
    this.vehicleName,
  });

  @override
  State<EditVehicleModificationsScreen> createState() => _EditVehicleModificationsScreenState();
}

class _EditVehicleModificationsScreenState extends State<EditVehicleModificationsScreen> {
  late VehicleModificationsCacheService _cacheService;
  VehicleModifications? _existingMods;
  bool _isLoading = true;
  bool _isSaving = false;

  // Form values
  LiftKitType _liftKit = LiftKitType.stock;
  ShocksType _shocksType = ShocksType.normal;
  ArmsType _arms = ArmsType.normal;
  TyreSizeType _tyreSize = TyreSizeType.size32;
  AirIntakeType _airIntake = AirIntakeType.normal;
  CatbackType _catback = CatbackType.normal;
  HorsepowerType _horsepower = HorsepowerType.hp100_200;
  OffRoadLightType _offRoadLight = OffRoadLightType.no;
  WinchType _winch = WinchType.no;
  ArmorType _armor = ArmorType.no;

  @override
  void initState() {
    super.initState();
    _initializeService();
  }

  Future<void> _initializeService() async {
    final prefs = await SharedPreferences.getInstance();
    _cacheService = VehicleModificationsCacheService(prefs);
    await _loadExistingModifications();
  }

  Future<void> _loadExistingModifications() async {
    try {
      final mods = await _cacheService.getModificationsByVehicleId(widget.vehicleId);
      
      if (mods != null) {
        setState(() {
          _existingMods = mods;
          _liftKit = mods.liftKit;
          _shocksType = mods.shocksType;
          _arms = mods.arms;
          _tyreSize = mods.tyreSize;
          _airIntake = mods.airIntake;
          _catback = mods.catback;
          _horsepower = mods.horsepower;
          _offRoadLight = mods.offRoadLight;
          _winch = mods.winch;
          _armor = mods.armor;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading modifications: $e')),
        );
      }
    }
  }

  Future<void> _submitModifications() async {
    // Show verification method dialog
    final verificationType = await showVerificationMethodDialog(context);
    if (verificationType == null) return; // User cancelled

    setState(() => _isSaving = true);

    try {
      final modifications = VehicleModifications(
        id: _existingMods?.id ?? '',
        vehicleId: widget.vehicleId,
        memberId: widget.memberId,
        liftKit: _liftKit,
        shocksType: _shocksType,
        arms: _arms,
        tyreSize: _tyreSize,
        airIntake: _airIntake,
        catback: _catback,
        horsepower: _horsepower,
        offRoadLight: _offRoadLight,
        winch: _winch,
        armor: _armor,
        verificationStatus: VerificationStatus.pending,
        verificationType: verificationType,
        createdAt: _existingMods?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _cacheService.saveModifications(modifications);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              verificationType == VerificationType.expedited
                  ? '✅ Modifications submitted! A marshal will contact you within 48 hours.'
                  : '✅ Modifications submitted! They will be verified on your next trip.',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context, true); // Return true to indicate changes
      }
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving modifications: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Vehicle Modifications')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vehicleName != null 
          ? '${widget.vehicleName} Modifications'
          : 'Edit Vehicle Modifications'
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status banner if modifications exist
            if (_existingMods != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: colors.surfaceContainerHighest,
                child: Row(
                  children: [
                    VerificationStatusBadge(status: _existingMods!.verificationStatus),
                    const Spacer(),
                    if (_existingMods!.verificationStatus == VerificationStatus.approved)
                      TextButton.icon(
                        onPressed: () => _showReVerificationWarning(),
                        icon: const Icon(Icons.info_outline, size: 16),
                        label: const Text('Re-verification Required'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                        ),
                      ),
                  ],
                ),
              ),

            // Form
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Suspension & Tires Section
                    _buildSectionHeader('Suspension & Tires', Icons.settings),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Lift Kit',
                      value: _liftKit,
                      items: LiftKitType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _liftKit = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Shocks Type',
                      value: _shocksType,
                      items: ShocksType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _shocksType = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Arms',
                      value: _arms,
                      items: ArmsType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _arms = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Tyre Size',
                      value: _tyreSize,
                      items: TyreSizeType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _tyreSize = value!),
                    ),
                    const SizedBox(height: 24),

                    // Engine Section
                    _buildSectionHeader('Engine', Icons.speed),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Air Intake',
                      value: _airIntake,
                      items: AirIntakeType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _airIntake = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Catback',
                      value: _catback,
                      items: CatbackType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _catback = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Horsepower',
                      value: _horsepower,
                      items: HorsepowerType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _horsepower = value!),
                    ),
                    const SizedBox(height: 24),

                    // Equipment Section
                    _buildSectionHeader('Equipment', Icons.build),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Off-Road Light',
                      value: _offRoadLight,
                      items: OffRoadLightType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _offRoadLight = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Winch',
                      value: _winch,
                      items: WinchType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _winch = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown(
                      label: 'Armor',
                      value: _armor,
                      items: ArmorType.values,
                      displayName: (type) => type.displayName,
                      onChanged: (value) => setState(() => _armor = value!),
                    ),
                    const SizedBox(height: 32),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitModifications,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Submit Modifications'),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required String Function(T) displayName,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      items: items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(displayName(item)),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  void _showReVerificationWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('Re-verification Required'),
          ],
        ),
        content: const Text(
          'Your current modifications are verified. If you update them, '
          'they will need to be verified again by a marshal before becoming active.\n\n'
          'You will not be able to register for trips with vehicle requirements '
          'until re-verification is complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Understood'),
          ),
        ],
      ),
    );
  }
}
