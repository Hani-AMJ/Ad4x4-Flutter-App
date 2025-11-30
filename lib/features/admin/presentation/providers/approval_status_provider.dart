import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/approval_status_choice_model.dart';

/// Approval Status Choices Provider
///
/// Fetches and caches approval status choices from backend API.
/// Endpoint: GET /api/choices/approvalstatus
///
/// This provider replaces the hardcoded ApprovalStatus enum with dynamic
/// choices from the backend, enabling server-side control of workflow states.
///
/// Usage:
/// ```dart
/// final statusesAsync = ref.watch(approvalStatusChoicesProvider);
///
/// statusesAsync.when(
///   data: (statuses) => DropdownButton(...),
///   loading: () => CircularProgressIndicator(),
///   error: (e, st) => Text('Error: $e'),
/// );
/// ```
final approvalStatusChoicesProvider =
    FutureProvider<List<ApprovalStatusChoice>>((ref) async {
      final repository = ref.watch(mainApiRepositoryProvider);

      try {
        final response = await repository.getApprovalStatusChoices();

        if (response.isEmpty) {
          // If backend returns empty, use fallback statuses
          return _getFallbackStatuses();
        }

        final choices = <ApprovalStatusChoice>[];
        for (var json in response) {
          try {
            final choice = ApprovalStatusChoice.fromJson(
              json as Map<String, dynamic>,
            );
            // Only include active statuses
            if (choice.active) {
              choices.add(choice);
            }
          } catch (e) {
            print('⚠️ Error parsing approval status choice: $e');
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
        print('❌ Error loading approval status choices: $e');
        // Return fallback statuses on error to prevent app breakage
        return _getFallbackStatuses();
      }
    });

/// Fallback approval statuses when backend is unavailable
///
/// These match the current hardcoded values to ensure backward compatibility
List<ApprovalStatusChoice> _getFallbackStatuses() {
  return const [
    ApprovalStatusChoice(
      value: 'P',
      label: 'Pending',
      description: 'Pending board approval',
      order: 1,
    ),
    ApprovalStatusChoice(
      value: 'A',
      label: 'Approved',
      description: 'Approved and visible to members',
      order: 2,
    ),
    ApprovalStatusChoice(
      value: 'D',
      label: 'Declined',
      description: 'Declined by board',
      order: 3,
    ),
  ];
}

/// Helper function to get approval status by value
///
/// Returns null if status not found in choices
ApprovalStatusChoice? getApprovalStatusByValue(
  List<ApprovalStatusChoice> choices,
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

/// Helper function to get label for a status value
///
/// Falls back to the value itself if not found
String getApprovalStatusLabel(
  List<ApprovalStatusChoice> choices,
  String? value,
) {
  if (value == null || value.isEmpty) return 'Unknown';

  final choice = getApprovalStatusByValue(choices, value);
  return choice?.label ?? value;
}
