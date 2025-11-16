import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/trip_area_choice_model.dart';
import 'repository_providers.dart';

/// Trip Area Choices Provider
/// 
/// Fetches and caches trip area choices from backend API.
/// Endpoint: GET /api/choices/triprequest area
/// 
/// This provider enables dynamic trip area selection (desert, mountain, wadi, beach, mixed)
/// controlled by the backend, replacing hardcoded area options.
final tripAreaChoicesProvider = FutureProvider<List<TripAreaChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getTripRequestAreaChoices();
    
    if (response.isEmpty) {
      return _getFallbackAreas();
    }
    
    final choices = <TripAreaChoice>[];
    for (var json in response) {
      try {
        final choice = TripAreaChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error parsing trip area choice: $e');
        }
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
    if (kDebugMode) {
      debugPrint('❌ Error loading trip area choices: $e');
    }
    return _getFallbackAreas();
  }
});

/// Fallback trip areas when backend is unavailable
List<TripAreaChoice> _getFallbackAreas() {
  return const [
    TripAreaChoice(
      value: 'desert',
      label: 'Desert',
      description: 'Sand dunes and desert terrain',
      order: 1,
      icon: 'desert',
      color: '#FFA726',
    ),
    TripAreaChoice(
      value: 'mountain',
      label: 'Mountain',
      description: 'Rocky mountain trails',
      order: 2,
      icon: 'terrain',
      color: '#8D6E63',
    ),
    TripAreaChoice(
      value: 'wadi',
      label: 'Wadi',
      description: 'Dry riverbeds and valleys',
      order: 3,
      icon: 'water',
      color: '#42A5F5',
    ),
    TripAreaChoice(
      value: 'beach',
      label: 'Beach',
      description: 'Coastal and beach areas',
      order: 4,
      icon: 'beach_access',
      color: '#26C6DA',
    ),
    TripAreaChoice(
      value: 'mixed',
      label: 'Mixed',
      description: 'Combination of different terrains',
      order: 5,
      icon: 'layers',
      color: '#66BB6A',
    ),
  ];
}

/// Helper function to get trip area by value
TripAreaChoice? getTripAreaByValue(
  List<TripAreaChoice> choices,
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
String getTripAreaLabel(
  List<TripAreaChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown';
  
  final choice = getTripAreaByValue(choices, value);
  return choice?.label ?? value;
}
