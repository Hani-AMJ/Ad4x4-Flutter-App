import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../data/models/car_brand_choice_model.dart';

/// Car Brand Choices Provider
/// 
/// Fetches and caches vehicle brand options from backend API.
/// Endpoint: GET /api/choices/carbrand
/// 
/// Provides foundation for vehicle profile features.
/// Place in core/providers as it's reusable across features.
final carBrandChoicesProvider = FutureProvider<List<CarBrandChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getCarBrandChoices();
    
    if (response.isEmpty) {
      return _getFallbackBrands();
    }
    
    final choices = <CarBrandChoice>[];
    for (var json in response) {
      try {
        final choice = CarBrandChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing car brand choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackBrands();
  } catch (e) {
    print('❌ Error loading car brand choices: $e');
    return _getFallbackBrands();
  }
});

/// Fallback car brands when backend is unavailable
/// 
/// Provides common UAE off-road vehicle brands
List<CarBrandChoice> _getFallbackBrands() {
  return const [
    CarBrandChoice(value: 'toyota', label: 'Toyota', order: 1, category: '4x4'),
    CarBrandChoice(value: 'nissan', label: 'Nissan', order: 2, category: '4x4'),
    CarBrandChoice(value: 'land_rover', label: 'Land Rover', order: 3, category: '4x4'),
    CarBrandChoice(value: 'jeep', label: 'Jeep', order: 4, category: '4x4'),
    CarBrandChoice(value: 'ford', label: 'Ford', order: 5, category: '4x4'),
    CarBrandChoice(value: 'chevrolet', label: 'Chevrolet', order: 6, category: '4x4'),
    CarBrandChoice(value: 'gmc', label: 'GMC', order: 7, category: '4x4'),
    CarBrandChoice(value: 'mitsubishi', label: 'Mitsubishi', order: 8, category: '4x4'),
    CarBrandChoice(value: 'mercedes', label: 'Mercedes-Benz', order: 9, category: 'Luxury'),
    CarBrandChoice(value: 'other', label: 'Other', order: 99),
  ];
}

/// Helper function to get brand by value
CarBrandChoice? getCarBrandByValue(
  List<CarBrandChoice> choices,
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

/// Helper function to get label for a brand value
String getCarBrandLabel(
  List<CarBrandChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown Brand';
  
  final choice = getCarBrandByValue(choices, value);
  return choice?.label ?? value;
}
