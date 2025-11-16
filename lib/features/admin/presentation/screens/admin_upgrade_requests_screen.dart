import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/models/upgrade_request_model.dart';
import '../../../../data/models/upgrade_status_choice_model.dart';
import '../providers/upgrade_requests_provider.dart';
import '../providers/upgrade_status_provider.dart';

/// Admin Upgrade Requests List Screen
/// 
/// Displays all upgrade requests with tabs for filtering by status
class AdminUpgradeRequestsScreen extends ConsumerStatefulWidget {
  const AdminUpgradeRequestsScreen({super.key});

  @override
  ConsumerState<AdminUpgradeRequestsScreen> createState() => _AdminUpgradeRequestsScreenState();
}

class _AdminUpgradeRequestsScreenState extends ConsumerState<AdminUpgradeRequestsScreen>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;
  final int _fallbackTabLength = 4; // Default for loading/error states

  @override
  void initState() {
    super.initState();
    
    // ✅ FIXED: Load ALL requests without filter
    // Backend doesn't support "pending" as a filter value
    // Frontend will filter by tabs client-side
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(upgradeRequestsProvider.notifier).loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }
  
  /// Initialize TabController with dynamic length from loaded statuses
  void _initializeTabController(int length) {
    if (_tabController == null || _tabController!.length != length) {
      _tabController?.dispose();
      _tabController = TabController(length: length, vsync: this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;
    
    // Check permissions
    final canView = user?.hasPermission('view_upgrade_req') ?? false;
    final canApprove = user?.hasPermission('approve_upgrade_req') ?? false;
    final canVote = user?.hasPermission('vote_upgrade_req') ?? false;

    // Permission check - must have view permission
    if (!canView) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/admin'),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outline,
                size: 64,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Permission Required',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to view upgrade requests.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin'),
                child: const Text('Back to Admin Dashboard'),
              ),
            ],
          ),
        ),
      );
    }

    final upgradeRequestsState = ref.watch(upgradeRequestsProvider);
    final statusesAsync = ref.watch(upgradeStatusChoicesProvider);

    return statusesAsync.when(
      data: (statuses) {
        // Initialize TabController with dynamic count (statuses + "All" tab)
        final tabCount = statuses.length + 1;
        _initializeTabController(tabCount);
        
        return _buildScaffold(
          context,
          theme,
          colors,
          upgradeRequestsState,
          statuses,
          canApprove,
          canVote,
          user,
        );
      },
      loading: () {
        // Initialize with fallback count during loading
        _initializeTabController(_fallbackTabLength);
        return _buildScaffold(
          context,
          theme,
          colors,
          upgradeRequestsState,
          _getFallbackStatuses(),
          canApprove,
          canVote,
          user,
        );
      },
      error: (e, s) {
        // Initialize with fallback count on error
        _initializeTabController(_fallbackTabLength);
        return _buildScaffold(
          context,
          theme,
          colors,
          upgradeRequestsState,
          _getFallbackStatuses(),
          canApprove,
          canVote,
          user,
        );
      },
    );
  }
  
  /// Fallback statuses for loading/error states
  List<UpgradeStatusChoice> _getFallbackStatuses() {
    return const [
      UpgradeStatusChoice(
        value: 'pending',
        label: 'Pending',
        description: 'Awaiting review',
        order: 1,
      ),
      UpgradeStatusChoice(
        value: 'approved',
        label: 'Approved',
        description: 'Request approved',
        order: 2,
      ),
      UpgradeStatusChoice(
        value: 'declined',
        label: 'Declined',
        description: 'Request declined',
        order: 3,
      ),
    ];
  }
  
  /// Build the main scaffold with dynamic tabs
  Widget _buildScaffold(
    BuildContext context,
    ThemeData theme,
    ColorScheme colors,
    UpgradeRequestsState upgradeRequestsState,
    List<UpgradeStatusChoice> statuses,
    bool canApprove,
    bool canVote,
    dynamic user,
  ) {
    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text('Upgrade Requests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
          isScrollable: true,
          onTap: (index) {
            // ✅ FIXED: Don't send status filter to API (backend doesn't support it)
            // Just switch tabs - filtering is done client-side in _buildTabViews
            // No need to call setStatusFilter which triggers API reload
          },
          tabs: _buildDynamicTabs(statuses, upgradeRequestsState, colors),
        ),
      ),
      body: upgradeRequestsState.isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: colors.primary),
                  const SizedBox(height: 16),
                  const Text('Loading upgrade requests...'),
                ],
              ),
            )
          : upgradeRequestsState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: colors.error),
                      const SizedBox(height: 16),
                      Text(
                        'Error Loading Requests',
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        upgradeRequestsState.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.7)),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => ref.read(upgradeRequestsProvider.notifier).refresh(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: _buildTabViews(
                    statuses,
                    upgradeRequestsState,
                    canApprove,
                    canVote,
                    colors,
                    theme,
                  ),
                ),
      floatingActionButton: user?.hasPermission('create_upgrade_req_for_self') ?? false
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/admin/upgrade-requests/create'),
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              icon: const Icon(Icons.add),
              label: const Text('Create Request'),
            )
          : null,
    );
  }

  /// Build dynamic tabs from status choices
  List<Widget> _buildDynamicTabs(
    List<UpgradeStatusChoice> statuses,
    UpgradeRequestsState state,
    ColorScheme colors,
  ) {
    final tabs = <Widget>[];
    
    // ✅ FIXED: Add "All" tab FIRST (not last)
    tabs.add(
      Tab(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('All'),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${state.requests.length}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
    
    // Create tab for each status
    for (final status in statuses) {
      // Get count for this status
      // ✅ UPDATED: Show "New" and "Pending"/"In Progress" separately
      final count = state.requests.where((r) {
        final requestStatus = r.status.toLowerCase();
        final filterStatus = status.value.toLowerCase();
        
        // Map status values to handle variations
        if (filterStatus == 'pending' || filterStatus == 'in progress' || filterStatus == 'in_progress') {
          // "Pending" or "In Progress" tab shows requests with votes
          return requestStatus == 'pending' || requestStatus == 'in progress' || requestStatus == 'in_progress';
        } else if (filterStatus == 'new') {
          // "New" tab shows requests without votes
          return requestStatus == 'new';
        }
        return requestStatus == filterStatus;
      }).length;
      
      // Determine color based on status value
      Color badgeColor;
      final statusLower = status.value.toLowerCase();
      if (statusLower == 'new') {
        badgeColor = const Color(0xFF9C27B0); // Purple for "New"
      } else if (statusLower == 'pending' || statusLower == 'in progress' || statusLower == 'in_progress' || status.value.toUpperCase() == 'P') {
        badgeColor = const Color(0xFFFFA726); // Orange for "Pending"/"In Progress"
      } else if (statusLower == 'approved' || status.value.toUpperCase() == 'A') {
        badgeColor = const Color(0xFF66BB6A); // Green for "Approved"
      } else if (statusLower == 'declined' || status.value.toUpperCase() == 'D') {
        badgeColor = colors.error; // Red for "Declined"
      } else {
        badgeColor = colors.primary; // Default
      }
      
      tabs.add(
        Tab(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(status.label),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: badgeColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // ✅ FIXED: "All" tab already added at the beginning
    return tabs;
  }
  
  /// Build dynamic tab views from status choices
  List<Widget> _buildTabViews(
    List<UpgradeStatusChoice> statuses,
    UpgradeRequestsState state,
    bool canApprove,
    bool canVote,
    ColorScheme colors,
    ThemeData theme,
  ) {
    final views = <Widget>[];
    
    // ✅ FIXED: Add "All" view FIRST (not last)
    views.add(
      _buildRequestsList(
        state.allRequests,
        canApprove,
        canVote,
        colors,
        theme,
      ),
    );
    
    // Create view for each status
    for (final status in statuses) {
      // ✅ UPDATED: Filter statuses with proper mapping
      final filteredRequests = state.requests.where((r) {
        final requestStatus = r.status.toLowerCase();
        final filterStatus = status.value.toLowerCase();
        
        // Map status values to handle variations
        if (filterStatus == 'pending' || filterStatus == 'in progress' || filterStatus == 'in_progress') {
          // \"Pending\" or \"In Progress\" filter shows requests with votes
          return requestStatus == 'pending' || requestStatus == 'in progress' || requestStatus == 'in_progress';
        } else if (filterStatus == 'new') {
          // \"New\" filter shows requests without votes
          return requestStatus == 'new';
        }
        return requestStatus == filterStatus;
      }).toList();
      
      views.add(
        _buildRequestsList(
          filteredRequests,
          canApprove,
          canVote,
          colors,
          theme,
        ),
      );
    }
    
    // ✅ FIXED: "All" view already added at the beginning
    return views;
  }

  Widget _buildRequestsList(
    List<UpgradeRequestListItem> requests,
    bool canApprove,
    bool canVote,
    ColorScheme colors,
    ThemeData theme,
  ) {
    if (requests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: colors.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No Requests',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'There are no upgrade requests in this category.',
              style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6)),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(upgradeRequestsProvider.notifier).refresh(),
      color: colors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: requests.length,
        itemBuilder: (context, index) {
          final request = requests[index];
          return _buildRequestCard(request, canApprove, canVote, colors, theme);
        },
      ),
    );
  }

  Widget _buildRequestCard(
    UpgradeRequestListItem request,
    bool canApprove,
    bool canVote,
    ColorScheme colors,
    ThemeData theme,
  ) {
    // Status colors
    Color statusColor;
    IconData statusIcon;
    
    if (request.isPending) {
      statusColor = const Color(0xFFFFA726); // Amber/Orange
      statusIcon = Icons.pending;
    } else if (request.isApproved) {
      statusColor = const Color(0xFF66BB6A); // Green
      statusIcon = Icons.check_circle;
    } else {
      statusColor = colors.error; // Red
      statusIcon = Icons.cancel;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/admin/upgrade-requests/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Member info + Status
              Row(
                children: [
                  // Member avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundImage: request.member.profileImage != null
                        ? NetworkImage(request.member.profileImage!)
                        : null,
                    child: request.member.profileImage == null
                        ? Text(
                            request.member.displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Member name and level change
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.member.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              request.currentLevel,
                              style: TextStyle(
                                color: colors.onSurface.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              size: 16,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              request.requestedLevel,
                              style: TextStyle(
                                color: colors.primary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 16, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          request.status.toUpperCase(),
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Vote and comment counts
              Row(
                children: [
                  // Approve votes
                  Icon(
                    Icons.thumb_up,
                    size: 18,
                    color: const Color(0xFF66BB6A),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.voteSummary.approveCount}',
                    style: const TextStyle(
                      color: Color(0xFF66BB6A),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Decline votes
                  Icon(
                    Icons.thumb_down,
                    size: 18,
                    color: colors.error,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.voteSummary.declineCount}',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Comments
                  Icon(
                    Icons.comment,
                    size: 18,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.commentCount}',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.8),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  
                  // Submitted date
                  Text(
                    DateFormat('MMM dd, yyyy').format(request.submittedAt),
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              
              // ✅ SIMPLIFIED UI: Progress bar instead of action buttons
              if (request.voteSummary.totalVotes > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Approval Rate',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: colors.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                          Text(
                            '${request.voteSummary.approvalPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: request.voteSummary.approvalPercentage / 100,
                          backgroundColor: colors.error.withValues(alpha: 0.2),
                          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF66BB6A)),
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
