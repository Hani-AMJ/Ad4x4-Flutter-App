import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../../data/models/user_model.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../providers/logbook_provider.dart';
import '../widgets/member_search_dialog.dart';
import '../widgets/trip_search_dialog.dart';

/// Admin Logbook Entries Screen
/// 
/// Displays list of all logbook entries with filtering options
/// Accessible by users with create_logbook_entries permission
class AdminLogbookEntriesScreen extends ConsumerStatefulWidget {
  const AdminLogbookEntriesScreen({super.key});

  @override
  ConsumerState<AdminLogbookEntriesScreen> createState() =>
      _AdminLogbookEntriesScreenState();
}

class _AdminLogbookEntriesScreenState
    extends ConsumerState<AdminLogbookEntriesScreen> {
  final ScrollController _scrollController = ScrollController();
  int? _selectedMemberId;
  int? _selectedTripId;

  @override
  void initState() {
    super.initState();
    
    // Load entries on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(logbookEntriesProvider.notifier).loadEntries();
    });

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      ref.read(logbookEntriesProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final state = ref.watch(logbookEntriesProvider);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // Permission check
    final canView = user?.hasPermission('create_logbook_entries') ?? false;
    if (!canView) {
      return Scaffold(
        appBar: AppBar(title: const Text('Logbook Entries')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text(
                'Access Denied',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You don\'t have permission to view logbook entries',
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
        title: const Text('Logbook Entries'),
        actions: [
          // Clear filters button
          if (state.memberFilter != null || state.tripFilter != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off),
              tooltip: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _selectedMemberId = null;
                  _selectedTripId = null;
                });
                ref.read(logbookEntriesProvider.notifier).clearFilters();
              },
            ),
          
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(logbookEntriesProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filters section
          _buildFiltersSection(context, state),
          
          // Entries list
          Expanded(
            child: _buildEntriesList(context, state, theme, colors),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/admin/logbook/create'),
        icon: const Icon(Icons.add),
        label: const Text('Create Entry'),
      ),
    );
  }

  Widget _buildFiltersSection(BuildContext context, LogbookEntriesState state) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          
          Row(
            children: [
              // Member filter with search dialog
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Show member search dialog
                    final selectedMember = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const MemberSearchDialog(
                        title: 'Filter by Member',
                        searchHint: 'Search member by name...',
                      ),
                    );

                    if (selectedMember != null) {
                      final memberId = selectedMember['id'] as int;
                      final memberName = selectedMember['displayName'] as String;
                      ref.read(logbookEntriesProvider.notifier).setMemberFilter(memberId);
                    }
                  },
                  icon: const Icon(Icons.person),
                  label: Text(
                    state.memberFilter != null
                        ? 'Member: ${state.memberFilter}'
                        : 'Filter by Member',
                  ),
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Trip filter with search dialog
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    // Show trip search dialog
                    final selectedTrip = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (context) => const TripSearchDialog(
                        title: 'Filter by Trip',
                        searchHint: 'Search trip by title...',
                      ),
                    );

                    if (selectedTrip != null) {
                      final tripId = selectedTrip['id'] as int;
                      final tripTitle = selectedTrip['title'] as String;
                      ref.read(logbookEntriesProvider.notifier).setTripFilter(tripId);
                    }
                  },
                  icon: const Icon(Icons.directions_car),
                  label: Text(
                    state.tripFilter != null
                        ? 'Trip: ${state.tripFilter}'
                        : 'Filter by Trip',
                  ),
                ),
              ),
            ],
          ),
          
          // Active filters summary
          if (state.memberFilter != null || state.tripFilter != null) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (state.memberFilter != null)
                  Chip(
                    label: Text('Member: ${state.memberFilter}'),
                    onDeleted: () {
                      setState(() => _selectedMemberId = null);
                      ref.read(logbookEntriesProvider.notifier).setMemberFilter(null);
                    },
                  ),
                if (state.tripFilter != null)
                  Chip(
                    label: Text('Trip: ${state.tripFilter}'),
                    onDeleted: () {
                      setState(() => _selectedTripId = null);
                      ref.read(logbookEntriesProvider.notifier).setTripFilter(null);
                    },
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEntriesList(
    BuildContext context,
    LogbookEntriesState state,
    ThemeData theme,
    ColorScheme colors,
  ) {
    if (state.isLoading && state.entries.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colors.error),
            const SizedBox(height: 16),
            Text(
              'Error Loading Entries',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              state.error!,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                ref.read(logbookEntriesProvider.notifier).refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 64, color: colors.outline),
            const SizedBox(height: 16),
            Text(
              'No Logbook Entries',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'No entries found. Create your first entry!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(logbookEntriesProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: state.entries.length + (state.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= state.entries.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final entry = state.entries[index];
          return _buildEntryCard(context, entry, theme, colors);
        },
      ),
    );
  }

  Widget _buildEntryCard(
    BuildContext context,
    LogbookEntry entry,
    ThemeData theme,
    ColorScheme colors,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          // Show entry details dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('Logbook Entry #${entry.id}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Member: ${entry.member.displayName}'),
                    const SizedBox(height: 8),
                    if (entry.trip != null) ...[
                      Text('Trip: ${entry.trip!.title}'),
                      const SizedBox(height: 8),
                    ],
                    Text('Signed by: ${entry.signedBy.displayName}'),
                    const SizedBox(height: 8),
                    Text('Date: ${DateFormat('MMM d, yyyy • h:mm a').format(entry.createdAt)}'),
                    const SizedBox(height: 16),
                    const Text('Skills Verified:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    ...entry.skillsVerified.map((skill) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• ${skill.name}'),
                    )),
                    if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Comment:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(entry.comment!),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Member info + Date
              Row(
                children: [
                  // Member avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: entry.member.profilePicture != null
                        ? NetworkImage(entry.member.profilePicture!)
                        : null,
                    child: entry.member.profilePicture == null
                        ? Text(
                            entry.member.firstName.isNotEmpty
                                ? entry.member.firstName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(fontSize: 20),
                          )
                        : null,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Member name and level
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.member.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (entry.member.level != null)
                          Text(
                            entry.member.level!.name,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.primary,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Date
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Icon(Icons.calendar_today, size: 16, color: colors.outline),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(entry.createdAt),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              
              // Trip info (if available)
              if (entry.trip != null) ...[
                Row(
                  children: [
                    Icon(Icons.directions_car, size: 20, color: colors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Trip',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colors.onSurface.withOpacity(0.6),
                            ),
                          ),
                          Text(
                            entry.trip!.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Skills verified
              if (entry.skillsVerified.isNotEmpty) ...[
                Text(
                  'Skills Verified',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: entry.skillsVerified.map((skill) {
                    return Chip(
                      avatar: const Icon(Icons.verified, size: 16),
                      label: Text(skill.name),
                      backgroundColor: colors.primaryContainer,
                      labelStyle: TextStyle(
                        color: colors.onPrimaryContainer,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
              ],
              
              // Marshal signature
              Row(
                children: [
                  Icon(Icons.badge, size: 20, color: colors.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Signed by',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.6),
                          ),
                        ),
                        Text(
                          entry.signedBy.displayName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Comment (if available)
              if (entry.comment != null && entry.comment!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colors.surfaceVariant.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.comment,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          entry.comment!,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
