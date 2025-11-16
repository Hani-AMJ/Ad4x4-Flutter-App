import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/time_of_day_choice_model.dart';

/// Time of Day Choices Provider
/// 
/// Fetches and caches time slot options from backend API.
/// Endpoint: GET /api/choices/timeofday
/// 
/// Enables pre-defined time slots for better trip scheduling UX.
/// Use in trip creation/editing forms and schedule filters.
final timeOfDayChoicesProvider = FutureProvider<List<TimeOfDayChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getTimeOfDayChoices();
    
    if (response.isEmpty) {
      return _getFallbackTimeSlots();
    }
    
    final choices = <TimeOfDayChoice>[];
    for (var json in response) {
      try {
        final choice = TimeOfDayChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing time of day choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by startHour, then label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else if (choices.isNotEmpty && choices.first.startHour != null) {
      choices.sort((a, b) => (a.startHour ?? 0).compareTo(b.startHour ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackTimeSlots();
  } catch (e) {
    print('❌ Error loading time of day choices: $e');
    return _getFallbackTimeSlots();
  }
});

/// Fallback time slots when backend is unavailable
/// 
/// Provides standard time-of-day slots for UAE timezone
List<TimeOfDayChoice> _getFallbackTimeSlots() {
  return const [
    TimeOfDayChoice(
      value: 'early_morning',
      label: 'Early Morning',
      description: '5:00 AM - 8:00 AM',
      order: 1,
      startHour: 5,
      endHour: 8,
    ),
    TimeOfDayChoice(
      value: 'morning',
      label: 'Morning',
      description: '8:00 AM - 12:00 PM',
      order: 2,
      startHour: 8,
      endHour: 12,
    ),
    TimeOfDayChoice(
      value: 'afternoon',
      label: 'Afternoon',
      description: '12:00 PM - 5:00 PM',
      order: 3,
      startHour: 12,
      endHour: 17,
    ),
    TimeOfDayChoice(
      value: 'evening',
      label: 'Evening',
      description: '5:00 PM - 9:00 PM',
      order: 4,
      startHour: 17,
      endHour: 21,
    ),
    TimeOfDayChoice(
      value: 'night',
      label: 'Night',
      description: '9:00 PM - 5:00 AM',
      order: 5,
      startHour: 21,
      endHour: 5,
    ),
  ];
}

/// Helper function to get time slot by value
TimeOfDayChoice? getTimeSlotByValue(
  List<TimeOfDayChoice> choices,
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

/// Helper function to get label for a time slot value
String getTimeSlotLabel(
  List<TimeOfDayChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown Time';
  
  final choice = getTimeSlotByValue(choices, value);
  return choice?.label ?? value;
}

/// Helper function to determine time slot based on DateTime
/// 
/// Useful for auto-selecting appropriate time slot from trip start time
TimeOfDayChoice? getTimeSlotFromDateTime(
  List<TimeOfDayChoice> choices,
  DateTime dateTime,
) {
  final hour = dateTime.hour;
  
  // Find slot that contains this hour
  for (var choice in choices) {
    if (choice.startHour != null && choice.endHour != null) {
      final start = choice.startHour!;
      final end = choice.endHour!;
      
      // Handle overnight slots (e.g., night: 21:00 - 5:00)
      if (end < start) {
        if (hour >= start || hour < end) return choice;
      } else {
        if (hour >= start && hour < end) return choice;
      }
    }
  }
  
  return null; // No matching slot found
}
