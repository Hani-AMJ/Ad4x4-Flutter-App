import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';

/// Trip Lead Autocomplete Widget
/// 
/// Smart autocomplete that searches trip leads from existing trips data
/// without needing to fetch a separate member list
class TripLeadAutocomplete extends ConsumerStatefulWidget {
  final String? initialValue;
  final ValueChanged<String?> onSelected;

  const TripLeadAutocomplete({
    super.key,
    this.initialValue,
    required this.onSelected,
  });

  @override
  ConsumerState<TripLeadAutocomplete> createState() => _TripLeadAutocompleteState();
}

class _TripLeadAutocompleteState extends ConsumerState<TripLeadAutocomplete> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialValue != null) {
      _controller.text = widget.initialValue!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Autocomplete<String>(
      initialValue: widget.initialValue != null
          ? TextEditingValue(text: widget.initialValue!)
          : null,
      optionsBuilder: (TextEditingValue textEditingValue) async {
        if (textEditingValue.text.length < 2) {
          return const Iterable<String>.empty();
        }

        try {
          // Search trip leads from recent trips
          final repository = ref.read(mainApiRepositoryProvider);
          final response = await repository.getTrips(
            approvalStatus: 'A', // ✅ FIXED: Only show approved trips
            page: 1,
            pageSize: 100, // Fetch recent trips to get lead names
            ordering: '-start_time',
          );

          final trips = response['results'] as List<dynamic>? ?? [];
          
          // Extract unique lead usernames
          final leadNames = trips
              .map((trip) {
                final lead = trip['lead'] as Map<String, dynamic>?;
                if (lead == null) return null;
                final username = lead['username'] as String?;
                final firstName = lead['firstName'] as String? ?? '';
                final lastName = lead['lastName'] as String? ?? '';
                final displayName = firstName.isNotEmpty && lastName.isNotEmpty
                    ? '$firstName $lastName'
                    : username;
                return displayName;
              })
              .whereType<String>()
              .toSet()
              .toList();

          // Filter by search query
          final query = textEditingValue.text.toLowerCase();
          final filtered = leadNames.where((name) {
            return name.toLowerCase().contains(query);
          }).toList();

          // Sort alphabetically
          filtered.sort();

          return filtered;
        } catch (e) {
          print('❌ [TripLeadAutocomplete] Error fetching leads: $e');
          return const Iterable<String>.empty();
        }
      },
      onSelected: (String selection) {
        _controller.text = selection;
        widget.onSelected(selection);
      },
      fieldViewBuilder: (
        BuildContext context,
        TextEditingController textEditingController,
        FocusNode focusNode,
        VoidCallback onFieldSubmitted,
      ) {
        // Sync with internal controller
        if (_controller.text.isNotEmpty && textEditingController.text.isEmpty) {
          textEditingController.text = _controller.text;
        }

        return TextField(
          controller: textEditingController,
          focusNode: focusNode,
          decoration: InputDecoration(
            labelText: 'Trip Lead',
            hintText: 'Start typing to search...',
            helperText: 'Search by name or username',
            prefixIcon: const Icon(Icons.person_search),
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      textEditingController.clear();
                      _controller.clear();
                      widget.onSelected(null);
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onSubmitted: (value) {
            if (value.isNotEmpty) {
              widget.onSelected(value);
            }
          },
        );
      },
      optionsViewBuilder: (
        BuildContext context,
        AutocompleteOnSelected<String> onSelected,
        Iterable<String> options,
      ) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300, maxWidth: 400),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final option = options.elementAt(index);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: colors.primaryContainer,
                      child: Text(
                        option[0].toUpperCase(),
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    title: Text(option),
                    onTap: () {
                      onSelected(option);
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
