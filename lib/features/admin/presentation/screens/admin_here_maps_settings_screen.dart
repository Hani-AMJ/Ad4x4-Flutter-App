import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/here_maps_settings_provider.dart';
import '../../../../data/models/here_maps_settings.dart';

/// Here Maps Settings Screen (Read-Only Display)
/// 
/// ✅ MIGRATED TO BACKEND-DRIVEN ARCHITECTURE
/// - Settings managed via Django Admin panel ONLY
/// - This screen displays current backend configuration
/// - No editing capabilities from Flutter app
/// - Manual refresh available to check for backend changes
/// 
/// ADMIN MANAGEMENT:
/// To change HERE Maps settings:
/// 1. Access Django Admin panel
/// 2. Navigate to Global Settings → HERE Maps Configuration
/// 3. Update: API key, enabled status, selected fields, max fields
/// 4. Save changes
/// 5. Flutter app will auto-refresh within 15 minutes (or manually refresh)
class AdminHereMapsSettingsScreen extends ConsumerWidget {
  const AdminHereMapsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final settingsAsync = ref.watch(hereMapsSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('HERE Maps Configuration'),
        actions: [
          // Refresh button to load latest backend config
          IconButton(
            onPressed: () async {
              await ref.read(hereMapsSettingsProvider.notifier).refreshSettings();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Configuration refreshed from backend'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh from Backend',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: settingsAsync.when(
        data: (settings) => _buildContent(context, settings),
        loading: () => const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading configuration from backend...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: colors.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Failed to load configuration',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () {
                    ref.read(hereMapsSettingsProvider.notifier).refreshSettings();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, HereMapsSettings settings) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Backend-driven notice
          Card(
            color: colors.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud,
                    color: colors.onPrimaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Backend-Managed Configuration',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Settings are managed via Django Admin panel. Changes made there will appear here within 15 minutes (or refresh manually).',
                          style: TextStyle(
                            color: colors.onPrimaryContainer,
                            fontSize: 14,
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

          // Global Status
          _buildSectionHeader(theme, 'Global Status'),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    settings.enabled ? Icons.check_circle : Icons.cancel,
                    color: settings.enabled ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HERE Maps Geocoding',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          settings.enabled ? 'Enabled' : 'Disabled',
                          style: TextStyle(
                            color: settings.enabled ? Colors.green : Colors.red,
                            fontWeight: FontWeight.w500,
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

          // Display Configuration
          _buildSectionHeader(theme, 'Display Configuration'),
          const SizedBox(height: 16),
          
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReadOnlyField(
                    theme,
                    'Maximum Fields',
                    settings.maxFields.toString(),
                    Icons.numbers,
                  ),
                  const SizedBox(height: 16),
                  _buildReadOnlyField(
                    theme,
                    'Selected Fields',
                    settings.selectedFields
                        .map((f) => f.displayName)
                        .join(', '),
                    Icons.list,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Available Fields
          _buildSectionHeader(theme, 'Available Field Options'),
          const SizedBox(height: 8),
          Text(
            'These fields can be selected via Django Admin panel',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),

          ...settings.availableFields.map((fieldName) {
            final isSelected = settings.selectedFields.any(
              (f) => f.displayName.toLowerCase() == fieldName.toLowerCase(),
            );
            
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              color: isSelected 
                  ? colors.primaryContainer 
                  : colors.surfaceContainerHighest,
              child: ListTile(
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected 
                      ? colors.primary 
                      : colors.onSurface.withValues(alpha: 0.3),
                ),
                title: Text(
                  fieldName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                trailing: isSelected
                    ? Chip(
                        label: const Text('Selected'),
                        backgroundColor: colors.primary,
                        labelStyle: TextStyle(
                          color: colors.onPrimary,
                          fontSize: 12,
                        ),
                      )
                    : null,
              ),
            );
          }),

          const SizedBox(height: 32),

          // Example Preview
          _buildSectionHeader(theme, 'Display Preview'),
          const SizedBox(height: 8),
          Text(
            'Example of how locations will appear',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
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
                    _getExampleDisplay(settings.selectedFields),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Based on current backend configuration',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Security Info
          Card(
            color: colors.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    Icons.security,
                    color: colors.onSecondaryContainer,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Secure Backend Architecture',
                          style: TextStyle(
                            color: colors.onSecondaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '• API key secured on backend\n'
                          '• JWT authentication required\n'
                          '• 70%+ cache hit rate\n'
                          '• Centralized rate limiting\n'
                          '• Usage monitoring enabled',
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

          // Admin Instructions
          Card(
            color: colors.tertiaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.admin_panel_settings,
                        color: colors.onTertiaryContainer,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'How to Modify Settings',
                        style: TextStyle(
                          color: colors.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '1. Access Django Admin Panel\n'
                    '2. Navigate to: Global Settings → HERE Maps\n'
                    '3. Update configuration as needed\n'
                    '4. Save changes\n'
                    '5. Changes will sync to app within 15 minutes',
                    style: TextStyle(
                      color: colors.onTertiaryContainer,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      // Copy admin URL to clipboard
                      Clipboard.setData(
                        const ClipboardData(text: 'https://ap.ad4x4.com/admin/'),
                      );
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Admin URL copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy Admin URL'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.tertiary,
                      foregroundColor: colors.onTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Text(
      title,
      style: theme.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildReadOnlyField(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    final colors = theme.colorScheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.6),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: colors.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: colors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getExampleDisplay(List<HereMapsDisplayField> fields) {
    if (fields.isEmpty) {
      return '24.207000, 54.833200 (fallback to coordinates)';
    }

    final examples = {
      HereMapsDisplayField.title: 'ADNOC',
      HereMapsDisplayField.district: 'Al Karamah',
      HereMapsDisplayField.city: 'Abu Dhabi',
      HereMapsDisplayField.county: 'Abu Dhabi',
      HereMapsDisplayField.countryName: 'United Arab Emirates',
      HereMapsDisplayField.postalCode: '20855',
      HereMapsDisplayField.label: 'ADNOC, Al Karamah, Abu Dhabi, UAE',
      HereMapsDisplayField.categoryName: 'Gas Station',
    };

    final parts = fields
        .map((f) => examples[f] ?? '')
        .where((s) => s.isNotEmpty);
    
    return parts.join(', ');
  }
}
