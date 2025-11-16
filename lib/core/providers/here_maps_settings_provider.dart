import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/here_maps_settings.dart';

/// Here Maps Settings Provider
/// 
/// In-memory state management for Here Maps configuration
/// Note: Settings will reset on app restart until backend persistence is implemented
class HereMapsSettingsNotifier extends StateNotifier<HereMapsSettings> {
  HereMapsSettingsNotifier() : super(HereMapsSettings.defaultSettings());

  /// Update API key
  void updateApiKey(String apiKey) {
    state = state.copyWith(apiKey: apiKey);
  }

  /// Update selected display fields (max 2)
  void updateSelectedFields(List<HereMapsDisplayField> fields) {
    if (fields.length > HereMapsSettings.maxFields) {
      // Validation: Should not reach here due to UI restrictions
      return;
    }
    state = state.copyWith(selectedFields: fields);
  }

  /// Toggle a display field on/off
  void toggleField(HereMapsDisplayField field) {
    final currentFields = List<HereMapsDisplayField>.from(state.selectedFields);
    
    if (currentFields.contains(field)) {
      // Remove field
      currentFields.remove(field);
    } else {
      // Add field (if under max limit)
      if (currentFields.length < HereMapsSettings.maxFields) {
        currentFields.add(field);
      }
      // If at max, do nothing (UI should show warning)
    }
    
    state = state.copyWith(selectedFields: currentFields);
  }

  /// Enable/disable reverse geocoding
  void toggleReverseGeocode(bool enabled) {
    state = state.copyWith(enableReverseGeocode: enabled);
  }

  /// Reset to default settings
  void resetToDefaults() {
    state = HereMapsSettings.defaultSettings();
  }

  /// Check if field selection is at maximum
  bool isAtMaxFields() {
    return state.selectedFields.length >= HereMapsSettings.maxFields;
  }

  /// Check if a specific field is selected
  bool isFieldSelected(HereMapsDisplayField field) {
    return state.selectedFields.contains(field);
  }
}

/// Provider for Here Maps settings
final hereMapsSettingsProvider =
    StateNotifierProvider<HereMapsSettingsNotifier, HereMapsSettings>((ref) {
  return HereMapsSettingsNotifier();
});
