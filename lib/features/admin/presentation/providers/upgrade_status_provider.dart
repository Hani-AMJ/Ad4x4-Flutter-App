import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/upgrade_status_choice_model.dart';

/// Upgrade Request Status Choices Provider
/// 
/// Fetches and caches upgrade request status choices from backend API.
/// Endpoint: GET /api/choices/upgraderequeststatus
/// 
/// This provider replaces error-prone string comparisons with dynamic
/// choices from the backend, enabling server-side control of workflow states.
final upgradeStatusChoicesProvider = FutureProvider<List<UpgradeStatusChoice>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getUpgradeRequestStatusChoices();
    
    if (response.isEmpty) {
      return _getFallbackStatuses();
    }
    
    final choices = <UpgradeStatusChoice>[];
    for (var json in response) {
      try {
        final choice = UpgradeStatusChoice.fromJson(json as Map<String, dynamic>);
        if (choice.active) {
          choices.add(choice);
        }
      } catch (e) {
        print('⚠️ Error parsing upgrade status choice: $e');
        continue;
      }
    }
    
    // Sort by order if available, otherwise by label
    if (choices.isNotEmpty && choices.first.order != null) {
      choices.sort((a, b) => (a.order ?? 0).compareTo(b.order ?? 0));
    } else {
      choices.sort((a, b) => a.label.compareTo(b.label));
    }
    
    return choices.isNotEmpty ? choices : _getFallbackStatuses();
  } catch (e) {
    print('❌ Error loading upgrade status choices: $e');
    return _getFallbackStatuses();
  }
});

/// Fallback upgrade statuses when backend is unavailable
List<UpgradeStatusChoice> _getFallbackStatuses() {
  return const [
    UpgradeStatusChoice(
      value: 'pending',
      label: 'Pending Review',
      description: 'Awaiting board review and votes',
      order: 1,
    ),
    UpgradeStatusChoice(
      value: 'approved',
      label: 'Approved',
      description: 'Upgrade request approved',
      order: 2,
    ),
    UpgradeStatusChoice(
      value: 'declined',
      label: 'Declined',
      description: 'Upgrade request declined',
      order: 3,
    ),
  ];
}

/// Helper function to get upgrade status by value
UpgradeStatusChoice? getUpgradeStatusByValue(
  List<UpgradeStatusChoice> choices,
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

/// Helper function to get label for a status value
String getUpgradeStatusLabel(
  List<UpgradeStatusChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown';
  
  final choice = getUpgradeStatusByValue(choices, value);
  return choice?.label ?? value;
}
