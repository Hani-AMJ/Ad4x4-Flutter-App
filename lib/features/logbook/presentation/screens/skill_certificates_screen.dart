import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../data/models/certificate_model.dart';
import '../../data/providers/certificate_provider.dart';

/// Skill Certificates Screen
/// 
/// View and manage skill verification certificates
class SkillCertificatesScreen extends ConsumerStatefulWidget {
  final int? memberId;

  const SkillCertificatesScreen({
    super.key,
    this.memberId,
  });

  @override
  ConsumerState<SkillCertificatesScreen> createState() =>
      _SkillCertificatesScreenState();
}

class _SkillCertificatesScreenState
    extends ConsumerState<SkillCertificatesScreen> {
  
  int get _targetMemberId {
    final user = ref.read(currentUserProviderV2);
    return widget.memberId ?? user?.id ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final certificatesAsync = ref.watch(certificatesProvider(_targetMemberId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Skill Certificates'),
        actions: [
          // Filter button
          certificatesAsync.whenOrNull(
            data: (certificates) {
              final notifier = ref.read(certificatesProvider(_targetMemberId).notifier);
              final filter = notifier.filter;
              
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: () => _showFilterDialog(context, filter),
                  ),
                  if (filter.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colors.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${filter.activeFilterCount}',
                          style: TextStyle(
                            color: colors.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ) ?? const SizedBox.shrink(),
        ],
      ),
      body: certificatesAsync.when(
        loading: () => const LoadingIndicator(message: 'Loading certificates...'),
        error: (error, stack) => ErrorState(
          title: 'Error Loading Certificates',
          message: error.toString(),
          onRetry: () {
            ref.read(certificatesProvider(_targetMemberId).notifier).refresh();
          },
        ),
        data: (certificates) {
          if (certificates.isEmpty) {
            return EmptyState(
              icon: Icons.card_membership,
              title: 'No Certificates Yet',
              message: 'Skill certificates will appear here after skills are verified.',
              actionText: null,
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(certificatesProvider(_targetMemberId).notifier).refresh();
            },
            child: Column(
              children: [
                // Summary header
                _buildSummaryHeader(certificates, colors),

                // Certificate list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: certificates.length,
                    itemBuilder: (context, index) {
                      final certificate = certificates[index];
                      return _CertificateCard(
                        certificate: certificate,
                        onTap: () => _showCertificateActions(context, certificate),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryHeader(List<SkillCertificate> certificates, ColorScheme colors) {
    final totalSkills = certificates.fold<int>(
      0,
      (sum, cert) => sum + cert.stats.totalSkills,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.primaryContainer, colors.secondaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _SummaryItem(
            icon: Icons.card_membership,
            label: 'Certificates',
            value: '${certificates.length}',
            color: colors.onPrimaryContainer,
          ),
          _SummaryItem(
            icon: Icons.star,
            label: 'Total Skills',
            value: '$totalSkills',
            color: colors.onPrimaryContainer,
          ),
          _SummaryItem(
            icon: Icons.schedule,
            label: 'Recent',
            value: '${certificates.where((c) => c.isRecent).length}',
            color: colors.onPrimaryContainer,
          ),
        ],
      ),
    );
  }

  void _showCertificateActions(BuildContext context, SkillCertificate certificate) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _CertificateActionsSheet(
        certificate: certificate,
        memberId: _targetMemberId,
      ),
    );
  }

  void _showFilterDialog(BuildContext context, CertificateFilter currentFilter) {
    showDialog(
      context: context,
      builder: (context) => _CertificateFilterDialog(
        currentFilter: currentFilter,
        onApply: (newFilter) {
          ref.read(certificatesProvider(_targetMemberId).notifier)
              .updateFilter(newFilter);
        },
      ),
    );
  }
}

/// Summary Item Widget
class _SummaryItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 32),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

/// Certificate Card Widget
class _CertificateCard extends StatelessWidget {
  final SkillCertificate certificate;
  final VoidCallback onTap;

  const _CertificateCard({
    required this.certificate,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: certificate.isRecent
              ? colors.primary.withValues(alpha: 0.3)
              : colors.outline.withValues(alpha: 0.2),
          width: certificate.isRecent ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Certificate icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.card_membership,
                      color: colors.onPrimaryContainer,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Title and date
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          certificate.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('MMMM yyyy').format(certificate.issueDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Certificate ID badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.secondaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      certificate.certificateId,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Description and stats
              Text(
                certificate.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),

              const SizedBox(height: 12),

              // Stats chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _StatChip(
                    icon: Icons.star,
                    label: '${certificate.stats.totalSkills} Skills',
                    color: colors.primary,
                  ),
                  _StatChip(
                    icon: Icons.signal_cellular_alt,
                    label: certificate.stats.primaryLevel,
                    color: colors.tertiary,
                  ),
                  _StatChip(
                    icon: Icons.person,
                    label: '${certificate.stats.uniqueSignOffs} Marshal${certificate.stats.uniqueSignOffs > 1 ? 's' : ''}',
                    color: colors.secondary,
                  ),
                  if (certificate.isRecent)
                    Chip(
                      avatar: Icon(
                        Icons.new_releases,
                        size: 16,
                        color: colors.onErrorContainer,
                      ),
                      label: const Text('Recent'),
                      backgroundColor: colors.errorContainer,
                      labelStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: colors.onErrorContainer,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Stat Chip Widget
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(label),
      backgroundColor: color.withValues(alpha: 0.1),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: color,
      ),
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Certificate Actions Bottom Sheet
class _CertificateActionsSheet extends ConsumerWidget {
  final SkillCertificate certificate;
  final int memberId;

  const _CertificateActionsSheet({
    required this.certificate,
    required this.memberId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colors.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            certificate.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          ListTile(
            leading: Icon(Icons.visibility, color: colors.primary),
            title: const Text('Preview Certificate'),
            onTap: () async {
              Navigator.pop(context);
              
              // Show loading dialog
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Generating certificate PDF...'),
                          SizedBox(height: 8),
                          Text(
                            'This may take a few seconds',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              try {
                final notifier = ref.read(certificatesProvider(memberId).notifier);
                
                // Generate PDF first (this is the slow part)
                final pdfData = await notifier.generateCertificatePDF(certificate);
                    
                // Close loading dialog NOW that generation is done
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // Now show the preview (fast, already generated)
                await notifier.showPreview(certificate, pdfData);
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.share, color: colors.secondary),
            title: const Text('Share Certificate'),
            onTap: () async {
              Navigator.pop(context);
              
              // Show loading dialog
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Preparing certificate to share...'),
                          SizedBox(height: 8),
                          Text(
                            'This may take a few seconds',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              try {
                final notifier = ref.read(certificatesProvider(memberId).notifier);
                
                // Generate PDF first (this is the slow part)
                final pdfData = await notifier.generateCertificatePDF(certificate);
                    
                // Close loading dialog NOW that generation is done
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // Now show the share sheet (fast, already generated)
                await notifier.showShare(certificate, pdfData);
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.print, color: colors.tertiary),
            title: const Text('Print Certificate'),
            onTap: () async {
              Navigator.pop(context);
              
              // Show loading dialog
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (dialogContext) => WillPopScope(
                    onWillPop: () async => false,
                    child: AlertDialog(
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Preparing certificate for printing...'),
                          SizedBox(height: 8),
                          Text(
                            'This may take a few seconds',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              try {
                final notifier = ref.read(certificatesProvider(memberId).notifier);
                
                // Generate PDF first (this is the slow part)
                final pdfData = await notifier.generateCertificatePDF(certificate);
                    
                // Close loading dialog NOW that generation is done
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                // Now show the print dialog (fast, already generated)
                await notifier.showPrint(certificate, pdfData);
              } catch (e) {
                // Close loading dialog
                if (context.mounted) {
                  Navigator.pop(context);
                }
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

/// Certificate Filter Dialog
class _CertificateFilterDialog extends StatefulWidget {
  final CertificateFilter currentFilter;
  final Function(CertificateFilter) onApply;

  const _CertificateFilterDialog({
    required this.currentFilter,
    required this.onApply,
  });

  @override
  State<_CertificateFilterDialog> createState() =>
      _CertificateFilterDialogState();
}

class _CertificateFilterDialogState extends State<_CertificateFilterDialog> {
  late CertificateFilter _filter;

  @override
  void initState() {
    super.initState();
    _filter = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Filter Certificates'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Time Range
            Text('Time Range', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CertificateTimeRange.values.map((range) {
                return FilterChip(
                  label: Text(range.displayName),
                  selected: _filter.timeRange == range,
                  onSelected: (selected) {
                    setState(() {
                      _filter = _filter.copyWith(timeRange: range);
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Recent only
            SwitchListTile(
              title: const Text('Only Recent (Last 30 days)'),
              value: _filter.onlyRecent,
              onChanged: (value) {
                setState(() {
                  _filter = _filter.copyWith(onlyRecent: value);
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            setState(() {
              _filter = const CertificateFilter();
            });
          },
          child: const Text('Reset'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onApply(_filter);
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}
