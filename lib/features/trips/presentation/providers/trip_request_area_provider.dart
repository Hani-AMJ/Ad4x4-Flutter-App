import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/trip_request_area_choice_model.dart';

/// Trip Request Area Choices Provider
/// 
/// Fetches and caches trip request area/category options from backend API.
/// Endpoint: GET /api/choices/triprequestarea
/// 
/// Enables categorization of trip requests by geographic area or terrain type.
/// Use in trip request creation forms and admin filters.
final tripRequestAreaChoicesProvider = FutureProvider<List<TripRequestAreaChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getTripRequestAreaChoices();
    
    if (response.isEmpty) {
      return _getFallbackAreas();
    }
    
    final choices = <TripRequestAreaChoice>[];
    for (var json in response) {
      try {
        final choice = TripRequestAreaChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing trip request area choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackAreas();
  } catch (e) {
    print('❌ Error loading trip request area choices: $e');
    return _getFallbackAreas();
  }
});

/// Fallback trip request areas when backend is unavailable
/// 
/// Provides common UAE off-road area types
List<TripRequestAreaChoice> _getFallbackAreas() {
  return const [
    TripRequestAreaChoice(
      value: 'desert',
      label: 'Desert',
      description: 'Sand dunes and desert terrain',
      order: 1,
      icon: 'wb_sunny',
    ),
    TripRequestAreaChoice(
      value: 'mountain',
      label: 'Mountain',
      description: 'Rocky mountains and highlands',
      order: 2,
      icon: 'terrain',
    ),
    TripRequestAreaChoice(
      value: 'wadi',
      label: 'Wadi',
      description: 'Dry riverbeds and valleys',
      order: 3,
      icon: 'water',
    ),
    TripRequestAreaChoice(
      value: 'beach',
      label: 'Beach',
      description: 'Coastal and beach areas',
      order: 4,
      icon: 'beach_access',
    ),
    TripRequestAreaChoice(
      value: 'mixed',
      label: 'Mixed Terrain',
      description: 'Combination of different terrains',
      order: 5,
      icon: 'landscape',
    ),
  ];
}

/// Helper function to get area choice by value
TripRequestAreaChoice? getAreaByValue(
  List<TripRequestAreaChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return null;
  
  try {
    return choices.firstWhere(
      (choice) => choice.value.toLowerCase() == value.toLowerCase(),
    );
  } catch (e) {
    return null;
  }
}

/// Helper function to get label for an area value
String getAreaLabel(
  List<TripRequestAreaChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown Area';
  
  final choice = getAreaByValue(choices, value);
  return choice?.label ?? value;
}
