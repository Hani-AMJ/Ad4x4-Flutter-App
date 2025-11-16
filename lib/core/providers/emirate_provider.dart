import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../data/models/emirate_choice_model.dart';

/// Emirate Choices Provider
/// 
/// Fetches and caches UAE emirate options from backend API.
/// Endpoint: GET /api/choices/emirates
/// 
/// Provides foundation for UAE-specific location features.
/// Place in core/providers as it's reusable across features.
final emirateChoicesProvider = FutureProvider<List<EmirateChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getEmiratesChoices();
    
    if (response.isEmpty) {
      return _getFallbackEmirates();
    }
    
    final choices = <EmirateChoice>[];
    for (var json in response) {
      try {
        final choice = EmirateChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing emirate choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackEmirates();
  } catch (e) {
    print('❌ Error loading emirate choices: $e');
    return _getFallbackEmirates();
  }
});

/// Fallback emirates when backend is unavailable
/// 
/// Provides all 7 UAE emirates
List<EmirateChoice> _getFallbackEmirates() {
  return const [
    EmirateChoice(
      value: 'abudhabi',
      label: 'Abu Dhabi',
      abbreviation: 'AD',
      order: 1,
      description: 'Capital of UAE',
    ),
    EmirateChoice(
      value: 'dubai',
      label: 'Dubai',
      abbreviation: 'DXB',
      order: 2,
      description: 'Commercial hub',
    ),
    EmirateChoice(
      value: 'sharjah',
      label: 'Sharjah',
      abbreviation: 'SHJ',
      order: 3,
      description: 'Cultural capital',
    ),
    EmirateChoice(
      value: 'ajman',
      label: 'Ajman',
      abbreviation: 'AJ',
      order: 4,
    ),
    EmirateChoice(
      value: 'ummalquwain',
      label: 'Umm Al Quwain',
      abbreviation: 'UAQ',
      order: 5,
    ),
    EmirateChoice(
      value: 'rasalkhaimah',
      label: 'Ras Al Khaimah',
      abbreviation: 'RAK',
      order: 6,
    ),
    EmirateChoice(
      value: 'fujairah',
      label: 'Fujairah',
      abbreviation: 'FUJ',
      order: 7,
      description: 'Eastern coast',
    ),
  ];
}

/// Helper function to get emirate by value
EmirateChoice? getEmirateByValue(
  List<EmirateChoice> choices,
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

/// Helper function to get label for an emirate value
String getEmirateLabel(
  List<EmirateChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown Emirate';
  
  final choice = getEmirateByValue(choices, value);
  return choice?.label ?? value;
}
