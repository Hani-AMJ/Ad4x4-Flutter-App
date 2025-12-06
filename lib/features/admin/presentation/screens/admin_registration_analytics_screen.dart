import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/registration_analytics_model.dart';
import '../../../../data/models/trip_model.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/registration_management_provider.dart';
import '../widgets/trip_search_autocomplete.dart';

/// Admin Registration Analytics Screen
/// 
/// Statistics dashboard for trip registrations
/// Accessible by users with edit_trip_registrations permission
class AdminRegistrationAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminRegistrationAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminRegistrationAnalyticsScreen> createState() =>
      _AdminRegistrationAnalyticsScreenState();
}

class _AdminRegistrationAnalyticsScreenState
    extends ConsumerState<AdminRegistrationAnalyticsScreen> {
  int? _selectedTripId;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canManage = user?.hasPermission('edit_trip_registrations') ?? false;
    if (!canManage) {
      return Scaffold(
        appBar: AppBar(title: const Text('Registration Analytics')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Access Denied', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'You don\'t have permission to manage registrations',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registration Analytics'),
        actions: [
          // Export button
          if (_selectedTripId != null)
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Export',
              onPressed: () => _handleExport(context),
            ),
          // Refresh button
          if (_selectedTripId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
              onPressed: () {
                ref.invalidate(registrationAnalyticsProvider(_selectedTripId!));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Trip search autocomplete
          Container(
            padding: const EdgeInsets.all(16),
            color: colors.surfaceContainerHighest,
            child: TripSearchAutocomplete(
              initialTripId: _selectedTripId,
              onTripSelected: (Trip? trip) {
                setState(() => _selectedTripId = trip?.id);
              },
              showFilters: true,
              hintText: 'Search trips for analytics...',
            ),
          ),
          // Analytics content
          Expanded(
            child: _selectedTripId == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics, size: 64, color: colors.outline),
                        const SizedBox(height: 16),
                        Text(
                          'Select a trip to view analytics',
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  )
                : _AnalyticsContent(tripId: _selectedTripId!),
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(BuildContext context) async {
    if (_selectedTripId == null) return;

    final format = await showDialog<String>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Export Format'),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'csv'),
            child: const Text('CSV (Excel)'),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.pop(context, 'pdf'),
            child: const Text('PDF'),
          ),
        ],
      ),
    );

    if (format == null || !context.mounted) return;

    try {
      await ref.read(exportProvider.notifier).exportRegistrations(
        tripId: _selectedTripId!,
        format: format,
      );

      final exportState = ref.read(exportProvider);
      if (exportState.downloadUrl != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Export ready!'),
            action: SnackBarAction(
              label: 'Download',
              onPressed: () async {
                // Open download URL in browser
                final downloadUrl = exportState.downloadUrl;
                if (downloadUrl != null) {
                  final uri = Uri.parse(downloadUrl);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Failed to open download link'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

/// Analytics Content Widget
class _AnalyticsContent extends ConsumerWidget {
  final int tripId;

  const _AnalyticsContent({required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(registrationAnalyticsProvider(tripId));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return analyticsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text('Error Loading Analytics', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(error.toString()),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(registrationAnalyticsProvider(tripId)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (analytics) => RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(registrationAnalyticsProvider(tripId));
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _SummaryCards(analytics: analytics),
              const SizedBox(height: 24),
              // Registration Breakdown
              _RegistrationBreakdown(analytics: analytics),
              const SizedBox(height: 24),
              // Quick Actions
              _QuickActions(tripId: tripId, analytics: analytics),
            ],
          ),
        ),
      ),
    );
  }
}

/// Summary Cards
class _SummaryCards extends StatelessWidget {
  final RegistrationAnalytics analytics;

  const _SummaryCards({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Overview', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.5,
          children: [
            _StatCard(
              icon: Icons.people,
              label: 'Total Registrations',
              value: '${analytics.totalRegistrations}',
              subtitle: '${analytics.availableSpots} spots available',
            ),
            _StatCard(
              icon: Icons.check_circle,
              label: 'Confirmed',
              value: '${analytics.confirmedRegistrations}',
              subtitle: '${analytics.fillPercentage.toStringAsFixed(0)}% full',
            ),
            _StatCard(
              icon: Icons.login,
              label: 'Checked In',
              value: '${analytics.checkedIn}',
              subtitle: '${analytics.checkInRate.toStringAsFixed(0)}% rate',
            ),
            _StatCard(
              icon: Icons.logout,
              label: 'Checked Out',
              value: '${analytics.checkedOut}',
              subtitle: 'Trip completion',
            ),
            _StatCard(
              icon: Icons.cancel,
              label: 'Cancellations',
              value: '${analytics.cancelled}',
              subtitle: '${analytics.cancellationRate.toStringAsFixed(0)}% rate',
            ),
            _StatCard(
              icon: Icons.hourglass_empty,
              label: 'Waitlist',
              value: '${analytics.totalWaitlist}',
              subtitle: 'Waiting members',
            ),
          ],
        ),
      ],
    );
  }
}

/// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 24, color: colors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.6),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Registration Breakdown
class _RegistrationBreakdown extends StatelessWidget {
  final RegistrationAnalytics analytics;

  const _RegistrationBreakdown({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (analytics.registrationsByLevel.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Breakdown by Level', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: analytics.registrationsByLevel.entries.map((entry) {
                final percentage = analytics.totalRegistrations > 0
                    ? (entry.value / analytics.totalRegistrations) * 100
                    : 0.0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(entry.key, style: theme.textTheme.titleSmall),
                          Text(
                            '${entry.value} (${percentage.toStringAsFixed(0)}%)',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      LinearProgressIndicator(
                        value: percentage / 100,
                        minHeight: 8,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

/// Quick Actions
class _QuickActions extends ConsumerWidget {
  final int tripId;
  final RegistrationAnalytics analytics;

  const _QuickActions({
    required this.tripId,
    required this.analytics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick Actions', style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            // ❌ REMOVED: Manage Registrations button (bulk-registrations feature deleted)
            ElevatedButton.icon(
              icon: const Icon(Icons.people),
              label: const Text('Manage Waitlist'),
              onPressed: () => context.push('/admin/waitlist-management?tripId=$tripId'),
            ),
            // ❌ REMOVED: Notify All button (bulk actions removed)
          ],
        ),
      ],
    );
  }

  // ❌ REMOVED: _handleNotifyAll method (bulk actions removed)
}

/// Notification Dialog
