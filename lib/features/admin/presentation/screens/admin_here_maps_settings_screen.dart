import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/here_maps_settings_provider.dart';
import '../../../../data/models/here_maps_settings.dart';

/// Here Maps Settings Screen
/// 
/// Configure Here Maps reverse geocoding for meeting points
class AdminHereMapsSettingsScreen extends ConsumerStatefulWidget {
  const AdminHereMapsSettingsScreen({super.key});

  @override
  ConsumerState<AdminHereMapsSettingsScreen> createState() =>
      _AdminHereMapsSettingsScreenState();
}

class _AdminHereMapsSettingsScreenState
    extends ConsumerState<AdminHereMapsSettingsScreen> {
  late TextEditingController _apiKeyController;
  bool _showMaxFieldsWarning = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(hereMapsSettingsProvider);
    _apiKeyController = TextEditingController(text: settings.apiKey);
  }

  @override
  void dispose() {
    _apiKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settings = ref.watch(hereMapsSettingsProvider);
    final settingsNotifier = ref.read(hereMapsSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Here Maps Settings'),
        actions: [
          TextButton.icon(
            onPressed: () {
              settingsNotifier.resetToDefaults();
              _apiKeyController.text = HereMapsSettings.defaultApiKey;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings reset to defaults'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset to Defaults'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: colors.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: colors.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These settings control how meeting point locations are displayed throughout the app. Changes apply app-wide for all users.',
                        style: TextStyle(
                          color: colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // API Key section
            Text(
              'API Configuration',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Here Maps API credentials for reverse geocoding',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _apiKeyController,
              decoration: InputDecoration(
                labelText: 'API Key',
                hintText: 'Enter Here Maps API Key',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.key),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: () {
                    settingsNotifier.updateApiKey(_apiKeyController.text.trim());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('API Key updated'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Save API Key',
                ),
                helperText: 'Default key is pre-configured',
              ),
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  settingsNotifier.updateApiKey(value.trim());
                }
              },
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // Display fields section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Display Fields',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select up to 2 fields to display',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
                Chip(
                  label: Text(
                    '${settings.selectedFields.length} / ${HereMapsSettings.maxFields}',
                  ),
                  backgroundColor: settings.selectedFields.length >= HereMapsSettings.maxFields
                      ? colors.errorContainer
                      : colors.primaryContainer,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Warning message
            if (_showMaxFieldsWarning)
              Card(
                color: colors.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: colors.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Maximum ${HereMapsSettings.maxFields} fields allowed. Unselect a field before selecting another.',
                          style: TextStyle(
                            color: colors.onErrorContainer,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close,
                          color: colors.onErrorContainer,
                        ),
                        onPressed: () {
                          setState(() {
                            _showMaxFieldsWarning = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Field checkboxes
            ...HereMapsDisplayField.values.map((field) {
              final isSelected = settings.selectedFields.contains(field);
              final isAtMax = settings.selectedFields.length >= HereMapsSettings.maxFields;

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: CheckboxListTile(
                  value: isSelected,
                  onChanged: (value) {
                    if (value == true) {
                      if (isAtMax) {
                        // Show warning
                        setState(() {
                          _showMaxFieldsWarning = true;
                        });
                      } else {
                        settingsNotifier.toggleField(field);
                        setState(() {
                          _showMaxFieldsWarning = false;
                        });
                      }
                    } else {
                      settingsNotifier.toggleField(field);
                      setState(() {
                        _showMaxFieldsWarning = false;
                      });
                    }
                  },
                  title: Text(field.displayName),
                  subtitle: Text(
                    'API field: ${field.jsonKey}',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                  secondary: Icon(
                    isSelected ? Icons.check_circle : Icons.circle_outlined,
                    color: isSelected ? colors.primary : colors.onSurface.withValues(alpha: 0.3),
                  ),
                ),
              );
            }),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 32),

            // Preview section
            Text(
              'Preview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Example display format',
              style: TextStyle(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 16),

            Card(
              color: colors.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Meeting Point Display:',
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      settings.selectedFields.isEmpty
                          ? '24.207000, 54.833200 (fallback to coordinates)'
                          : _getExampleDisplay(settings.selectedFields),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This is how meeting points will appear in trip cards, details, and throughout the app.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Persistence note
            Card(
              color: colors.secondaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off,
                      color: colors.onSecondaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Temporary Settings',
                            style: TextStyle(
                              color: colors.onSecondaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Settings are stored in memory and will reset on app restart. Backend persistence is in development.',
                            style: TextStyle(
                              color: colors.onSecondaryContainer,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  String _getExampleDisplay(List<HereMapsDisplayField> fields) {
    final examples = {
      HereMapsDisplayField.title: 'ADNOC',
      HereMapsDisplayField.district: 'Qasr Al Wathba South',
      HereMapsDisplayField.city: 'Abu Dhabi',
      HereMapsDisplayField.county: 'Abu Dhabi',
      HereMapsDisplayField.countryName: 'United Arab Emirates',
      HereMapsDisplayField.postalCode: '20855',
      HereMapsDisplayField.label: 'ADNOC, Qasr Al Wathba South Abu Dhabi, UAE',
      HereMapsDisplayField.categoryName: 'Gas Station',
    };

    final parts = fields.map((f) => examples[f] ?? '').where((s) => s.isNotEmpty);
    return parts.join(', ');
  }
}
