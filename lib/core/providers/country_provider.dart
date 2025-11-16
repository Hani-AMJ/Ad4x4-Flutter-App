import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';
import '../../data/models/country_choice_model.dart';

/// Country Choices Provider
/// 
/// Fetches and caches country options from backend API.
/// Endpoint: GET /api/choices/countries
/// 
/// Provides foundation for international features.
/// Place in core/providers as it's reusable across features.
final countryChoicesProvider = FutureProvider<List<CountryChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getCountryChoices();
    
    if (response.isEmpty) {
      return _getFallbackCountries();
    }
    
    final choices = <CountryChoice>[];
    for (var json in response) {
      try {
        final choice = CountryChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing country choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackCountries();
  } catch (e) {
    print('❌ Error loading country choices: $e');
    return _getFallbackCountries();
  }
});

/// Fallback countries when backend is unavailable
/// 
/// Provides GCC countries + common international destinations
List<CountryChoice> _getFallbackCountries() {
  return const [
    CountryChoice(value: 'AE', label: 'United Arab Emirates', order: 1, flagEmoji: '🇦🇪', callingCode: '+971'),
    CountryChoice(value: 'SA', label: 'Saudi Arabia', order: 2, flagEmoji: '🇸🇦', callingCode: '+966'),
    CountryChoice(value: 'OM', label: 'Oman', order: 3, flagEmoji: '🇴🇲', callingCode: '+968'),
    CountryChoice(value: 'QA', label: 'Qatar', order: 4, flagEmoji: '🇶🇦', callingCode: '+974'),
    CountryChoice(value: 'BH', label: 'Bahrain', order: 5, flagEmoji: '🇧🇭', callingCode: '+973'),
    CountryChoice(value: 'KW', label: 'Kuwait', order: 6, flagEmoji: '🇰🇼', callingCode: '+965'),
    CountryChoice(value: 'JO', label: 'Jordan', order: 7, flagEmoji: '🇯🇴', callingCode: '+962'),
    CountryChoice(value: 'EG', label: 'Egypt', order: 8, flagEmoji: '🇪🇬', callingCode: '+20'),
    CountryChoice(value: 'US', label: 'United States', order: 9, flagEmoji: '🇺🇸', callingCode: '+1'),
    CountryChoice(value: 'GB', label: 'United Kingdom', order: 10, flagEmoji: '🇬🇧', callingCode: '+44'),
  ];
}

/// Helper function to get country by value
CountryChoice? getCountryByValue(
  List<CountryChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return null;
  
  try {
    return choices.firstWhere(
      (choice) => choice.value.toUpperCase() == value.toUpperCase(),
    );
  } catch (e) {
    return null;
  }
}

/// Helper function to get label for a country value
String getCountryLabel(
  List<CountryChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown Country';
  
  final choice = getCountryByValue(choices, value);
  return choice?.label ?? value;
}
