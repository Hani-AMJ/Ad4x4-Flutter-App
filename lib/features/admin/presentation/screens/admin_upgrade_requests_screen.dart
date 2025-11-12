import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/utils/image_proxy.dart';
import '../../../../data/models/upgrade_request_model.dart';
import '../providers/upgrade_requests_provider.dart';

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
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load upgrade requests on first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(upgradeRequestsProvider.notifier).loadRequests();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        title: const Text('Upgrade Requests'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colors.primary,
          labelColor: colors.primary,
          unselectedLabelColor: colors.onSurface.withValues(alpha: 0.6),
          onTap: (index) {
            // Update filter based on tab
            String? status;
            switch (index) {
              case 0:
                status = 'pending';
                break;
              case 1:
                status = 'approved';
                break;
              case 2:
                status = 'declined';
                break;
              case 3:
                status = null; // All
                break;
            }
            ref.read(upgradeRequestsProvider.notifier).setStatusFilter(status);
          },
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Pending'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFA726).withValues(alpha: 0.15), // Amber/Orange
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${upgradeRequestsState.pendingRequests.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFA726),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Approved'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF66BB6A).withValues(alpha: 0.15), // Green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${upgradeRequestsState.approvedRequests.length}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Declined'),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${upgradeRequestsState.declinedRequests.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colors.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
                      '${upgradeRequestsState.totalCount}',
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
          ],
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
                  children: [
                    _buildRequestsList(
                      upgradeRequestsState.pendingRequests,
                      canApprove,
                      canVote,
                      colors,
                      theme,
                    ),
                    _buildRequestsList(
                      upgradeRequestsState.approvedRequests,
                      canApprove,
                      canVote,
                      colors,
                      theme,
                    ),
                    _buildRequestsList(
                      upgradeRequestsState.declinedRequests,
                      canApprove,
                      canVote,
                      colors,
                      theme,
                    ),
                    _buildRequestsList(
                      upgradeRequestsState.allRequests,
                      canApprove,
                      canVote,
                      colors,
                      theme,
                    ),
                  ],
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
                        ? NetworkImage(ImageProxy.getProxiedUrl(request.member.profileImage))
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
              
              // Action buttons (only for pending requests with proper permissions)
              if (request.isPending && (canApprove || canVote))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      if (canApprove) ...[
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              // Quick approve action
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('Approve Upgrade Request'),
                                  content: Text('Approve ${request.member.displayName} for ${request.requestedLevel}?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF66BB6A),
                                      ),
                                      child: const Text('Approve'),
                                    ),
                                  ],
                                ),
                              );
                              
                              if (confirm == true && mounted) {
                                try {
                                  await ref.read(upgradeRequestActionsProvider.notifier).approve(request.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Request approved successfully!'),
                                        backgroundColor: Color(0xFF66BB6A),
                                      ),
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error: $e'),
                                        backgroundColor: colors.error,
                                      ),
                                    );
                                  }
                                }
                              }
                            },
                            icon: const Icon(Icons.check, color: Color(0xFF66BB6A)),
                            label: const Text('Approve', style: TextStyle(color: Color(0xFF66BB6A))),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF66BB6A)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => context.push('/admin/upgrade-requests/${request.id}'),
                            icon: Icon(Icons.cancel, color: colors.error),
                            label: Text('Decline', style: TextStyle(color: colors.error)),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: colors.error),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => context.push('/admin/upgrade-requests/${request.id}'),
                          icon: const Icon(Icons.visibility),
                          label: const Text('View Details'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors.primary,
                            foregroundColor: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
              // View details button for non-pending or non-approve users
              if (!request.isPending || (!canApprove && !canVote))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/admin/upgrade-requests/${request.id}'),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Details'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        foregroundColor: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
