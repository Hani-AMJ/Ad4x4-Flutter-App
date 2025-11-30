import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/upgrade_vote_choice_model.dart';

/// Upgrade Request Vote Choices Provider
///
/// Fetches and caches upgrade request vote choices from backend API.
/// Endpoint: GET /api/choices/upgradevote
///
/// This provider enables dynamic vote options (approve, decline, abstain, needs_info, etc.)
/// controlled by the backend, replacing the hardcoded boolean approve/decline system.
final upgradeVoteChoicesProvider = FutureProvider<List<UpgradeVoteChoice>>((
  ref,
) async {
  final repository = ref.watch(mainApiRepositoryProvider);

  try {
    final response = await repository.getUpgradeRequestVoteChoices();

    if (response.isEmpty) {
      return _getFallbackVotes();
    }

    final choices = <UpgradeVoteChoice>[];
    bool hasDefer = false;

    for (var json in response) {
      try {
        final choice = UpgradeVoteChoice.fromJson(json as Map<String, dynamic>);
        if (!choice.active) continue;

        // ✅ Filter logic: Keep only Approve, Decline, and ONE defer option
        final normalizedValue = choice.value.toLowerCase();

        // Skip 'abstain' if we already have a defer option
        if (normalizedValue == 'abstain' ||
            normalizedValue == 'needs_info' ||
            normalizedValue == 'defer') {
          if (hasDefer) {
            // Already have a defer option, skip this one
            continue;
          }
          // This is our defer option - rename it and mark as found
          hasDefer = true;
          choices.add(
            UpgradeVoteChoice(
              value: 'defer', // Normalize to 'defer'
              label: 'Defer', // Consistent label
              description:
                  choice.description ??
                  'Defer decision - need more information',
              order: 3, // Always last
              icon: 'help_outline',
              color: '#FF9800',
            ),
          );
        } else {
          // Keep approve and decline as-is
          choices.add(choice);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('⚠️ Error parsing upgrade vote choice: $e');
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

    return choices.isNotEmpty ? choices : _getFallbackVotes();
  } catch (e) {
    if (kDebugMode) {
      debugPrint('❌ Error loading upgrade vote choices: $e');
    }
    return _getFallbackVotes();
  }
});

/// Fallback upgrade vote options when backend is unavailable
/// ✅ UPDATED: Only 3 options (Approve, Decline, Defer)
List<UpgradeVoteChoice> _getFallbackVotes() {
  return const [
    UpgradeVoteChoice(
      value: 'approve',
      label: 'Approve',
      description: 'Vote to approve this upgrade request',
      order: 1,
      icon: 'thumb_up',
      color: '#66BB6A',
    ),
    UpgradeVoteChoice(
      value: 'decline',
      label: 'Decline',
      description: 'Vote to decline this upgrade request',
      order: 2,
      icon: 'thumb_down',
      color: '#EF5350',
    ),
    UpgradeVoteChoice(
      value: 'defer',
      label: 'Defer',
      description: 'Defer decision - need more information',
      order: 3,
      icon: 'help_outline',
      color: '#FF9800',
    ),
  ];
}

/// Helper function to get vote option by value
UpgradeVoteChoice? getUpgradeVoteByValue(
  List<UpgradeVoteChoice> choices,
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

/// Helper function to get label for a vote value
String getUpgradeVoteLabel(List<UpgradeVoteChoice> choices, String? value) {
  if (value == null || value.isEmpty) return 'Unknown';

  final choice = getUpgradeVoteByValue(choices, value);
  return choice?.label ?? value;
}

/// Helper function to check if a vote is an approval type
bool isApprovalVote(String? value) {
  if (value == null || value.isEmpty) return false;
  return value.toLowerCase() == 'approve' || value.toLowerCase() == 'a';
}

/// Helper function to check if a vote is a decline type
bool isDeclineVote(String? value) {
  if (value == null || value.isEmpty) return false;
  return value.toLowerCase() == 'decline' || value.toLowerCase() == 'd';
}

/// Helper function to check if a vote is a defer/abstain/needs_info type
bool isDeferVote(String? value) {
  if (value == null || value.isEmpty) return false;
  final normalizedValue = value.toLowerCase();
  return normalizedValue == 'defer' ||
      normalizedValue == 'abstain' ||
      normalizedValue == 'needs_info' ||
      normalizedValue == 'needsinfo';
}
