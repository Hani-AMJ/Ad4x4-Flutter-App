import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../data/models/gender_choice_model.dart';

/// Gender Choices Provider
/// 
/// Fetches and caches gender options from backend API.
/// Endpoint: GET /api/choices/gender
/// 
/// Provides foundation for demographic features with backend-controlled
/// inclusive gender options.
/// Place in core/providers as it's reusable across features.
final genderChoicesProvider = FutureProvider<List<GenderChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getGenderChoices();
    
    if (response.isEmpty) {
      return _getFallbackGenders();
    }
    
    final choices = <GenderChoice>[];
    for (var json in response) {
      try {
        final choice = GenderChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing gender choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackGenders();
  } catch (e) {
    print('❌ Error loading gender choices: $e');
    return _getFallbackGenders();
  }
});

/// Fallback gender options when backend is unavailable
/// 
/// Provides inclusive gender options
List<GenderChoice> _getFallbackGenders() {
  return const [
    GenderChoice(
      value: 'male',
      label: 'Male',
      order: 1,
    ),
    GenderChoice(
      value: 'female',
      label: 'Female',
      order: 2,
    ),
    GenderChoice(
      value: 'other',
      label: 'Other',
      order: 3,
    ),
    GenderChoice(
      value: 'prefer_not_say',
      label: 'Prefer not to say',
      order: 4,
    ),
  ];
}

/// Helper function to get gender by value
GenderChoice? getGenderByValue(
  List<GenderChoice> choices,
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

/// Helper function to get label for a gender value
String getGenderLabel(
  List<GenderChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Not specified';
  
  final choice = getGenderByValue(choices, value);
  return choice?.label ?? value;
}
