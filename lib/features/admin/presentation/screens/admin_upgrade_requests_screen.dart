import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/error_log_service.dart';
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

    // 🔍 DEBUG: Log every build to see if widget rebuilds after data loads
    final errorLogService = ErrorLogService();
    errorLogService.logError(
      message: '''
🔍 WIDGET BUILD DEBUG
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Build Time: ${DateTime.now().millisecondsSinceEpoch}
state.requests.length: ${upgradeRequestsState.requests.length}
state.isLoading: ${upgradeRequestsState.isLoading}
state.totalCount: ${upgradeRequestsState.totalCount}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''',
      type: 'debug',
      context: 'AdminUpgradeRequestsScreen - Widget Build',
    );

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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: TabBar(
            key: ValueKey('tabbar_${upgradeRequestsState.requests.length}_${upgradeRequestsState.isLoading}'),
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
      // DEBUG: Always log status processing for debugging
      final logService = ErrorLogService();
      logService.logError(
        message: '''
🔧 PROCESSING TAB: ${status.label}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status Value: "${status.value}"
Status Label: "${status.label}"
Filter Value (lowercase): "${status.value.toLowerCase().trim()}"
Total Requests Available: ${state.requests.length}

Request Details:
${state.requests.map((r) => '  #${r.id}: status="${r.status}", isPending=${r.isPending}, isApproved=${r.isApproved}, isDeclined=${r.isDeclined}').join('\n')}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''',
        type: 'debug',
        context: 'AdminUpgradeRequestsScreen - Tab Processing',
      );
      
      // Get count for this status
      // ✅ FIXED: Use getter methods instead of string comparison for reliability
      final matchingRequests = state.requests.where((r) {
        final filterStatus = status.value.toLowerCase().trim();
        final requestStatus = r.status.toLowerCase().trim();
        
        // CRITICAL FIX: Backend returns single-letter codes for status.value!
        // status.value examples: "N" (New), "D" (Declined), "A" (Approved), "P" (Pending)
        // But request.status is the full word: "Declined", "Approved", etc.
        
        // Use model getters for accurate filtering (handles all variations)
        if (filterStatus == 'declined' || filterStatus == 'rejected' || filterStatus == 'denied' || filterStatus == 'd') {
          return r.isDeclined;  // Use getter method!
        } else if (filterStatus == 'approved' || filterStatus == 'accepted' || filterStatus == 'a') {
          return r.isApproved;  // Use getter method!
        } else if (filterStatus == 'pending' || filterStatus == 'in progress' || filterStatus == 'in_progress' || filterStatus == 'new' || filterStatus == 'n' || filterStatus == 'p') {
          return r.isPending;  // Use getter method!
        }
        
        // Fallback to string comparison for unknown statuses
        return requestStatus == filterStatus;
      }).toList();
      
      final count = matchingRequests.length;
      
      // 🔍 DEBUG: Log status filtering for declined/rejected requests
      // Log ALWAYS when it's declined tab - remove restrictive conditions
      if (status.value.toLowerCase() == 'declined' || status.value.toLowerCase() == 'rejected') {
        final logService = ErrorLogService();
        final allStatuses = state.requests.map((r) => '"${r.status}"').join(', ');
        
        // Debug the conditions themselves
        final conditionDebug = '''
Debug Conditions:
  • status.value: "${status.value}"
  • state.isLoading: ${state.isLoading}
  • state.requests.length: ${state.requests.length}
  • state.requests.isNotEmpty: ${state.requests.isNotEmpty}
  • state.errorMessage: ${state.errorMessage ?? 'null'}
  • state.totalCount: ${state.totalCount}
  • state.statusFilter: ${state.statusFilter ?? 'null'}
''';
        
        final debugMessage = '''
🔍 STATUS FILTER DEBUG - ${status.label} (${status.value})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Filter Value: "${status.value}"
Matched Count: $count
Total Requests: ${state.requests.length}

$conditionDebug

All Request Statuses:
$allStatuses

Matched Requests:
${matchingRequests.map((r) => '  #${r.id}: "${r.status}" (${r.member.displayName})').join('\n')}

isPending check:
${state.requests.map((r) => '  #${r.id}: isPending=${r.isPending}, isApproved=${r.isApproved}, isDeclined=${r.isDeclined}, status="${r.status}"').join('\n')}

Filter Logic:
  requestStatus.toLowerCase().trim() == "${status.value.toLowerCase().trim()}"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
''';
        
        logService.logError(
          message: debugMessage,
          type: 'debug',
          context: 'AdminUpgradeRequestsScreen - Status Filter',
        );
      }
      
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
      // ✅ FIXED: Use getter methods instead of string comparison for reliability
      final filteredRequests = state.requests.where((r) {
        final filterStatus = status.value.toLowerCase().trim();
        
        // CRITICAL FIX: Backend returns single-letter codes!
        // status.value examples: "N" (New), "D" (Declined), "A" (Approved), "P" (Pending)
        
        // Use model getters for accurate filtering (handles all variations including single-letter codes)
        if (filterStatus == 'declined' || filterStatus == 'rejected' || filterStatus == 'denied' || filterStatus == 'd') {
          return r.isDeclined;  // Use getter method!
        } else if (filterStatus == 'approved' || filterStatus == 'accepted' || filterStatus == 'a') {
          return r.isApproved;  // Use getter method!
        } else if (filterStatus == 'pending' || filterStatus == 'in progress' || filterStatus == 'in_progress' || filterStatus == 'new' || filterStatus == 'n' || filterStatus == 'p') {
          return r.isPending;  // Use getter method!
        }
        
        // Fallback to string comparison for unknown statuses
        final requestStatus = r.status.toLowerCase().trim();
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
      elevation: 2,
      child: InkWell(
        onTap: () => context.push('/admin/upgrade-requests/${request.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Member info + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Member avatar
                  CircleAvatar(
                    radius: 28,
                    backgroundImage: request.member.profileImage != null
                        ? NetworkImage(request.member.profileImage!)
                        : null,
                    child: request.member.profileImage == null
                        ? Text(
                            request.member.displayName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  // Member name and level change
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.member.displayName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        // Level change on separate line for better readability
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: Text(
                                  request.currentLevel,
                                  style: TextStyle(
                                    color: colors.onSurface.withValues(alpha: 0.7),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                size: 16,
                                color: colors.primary,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  request.requestedLevel,
                                  style: TextStyle(
                                    color: colors.primary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Status badge - full width for better visibility
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 18, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      request.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Divider for better separation
              Divider(
                color: colors.onSurface.withValues(alpha: 0.1),
                height: 1,
              ),
              const SizedBox(height: 16),
              
              // Vote and comment counts with date
              Row(
                children: [
                  // Approve votes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.thumb_up,
                          size: 16,
                          color: Color(0xFF66BB6A),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${request.voteSummary.approveCount}',
                          style: const TextStyle(
                            color: Color(0xFF66BB6A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Decline votes
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.thumb_down,
                          size: 16,
                          color: colors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${request.voteSummary.declineCount}',
                          style: TextStyle(
                            color: colors.error,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Comments
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.comment,
                          size: 16,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${request.commentCount}',
                          style: TextStyle(
                            color: colors.onSurface.withValues(alpha: 0.8),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Submitted date - separate line for better visibility
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colors.onSurface.withValues(alpha: 0.5),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('MMM dd, yyyy').format(request.submittedAt),
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
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
