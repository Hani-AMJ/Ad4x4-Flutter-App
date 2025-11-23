import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/upgrade_request_model.dart';
import '../providers/upgrade_requests_provider.dart';

/// Admin Upgrade Request Details Screen
/// 
/// Shows complete details of an upgrade request including votes and comments
class AdminUpgradeRequestDetailsScreen extends ConsumerStatefulWidget {
  final String requestId;

  const AdminUpgradeRequestDetailsScreen({
    super.key,
    required this.requestId,
  });

  @override
  ConsumerState<AdminUpgradeRequestDetailsScreen> createState() => _AdminUpgradeRequestDetailsScreenState();
}

class _AdminUpgradeRequestDetailsScreenState extends ConsumerState<AdminUpgradeRequestDetailsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _declineReasonController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    _declineReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;
    
    // Check permissions
    final canView = user?.hasPermission('view_upgrade_req') ?? false;
    final canVote = user?.hasPermission('vote_upgrade_req') ?? false;
    final canComment = user?.hasPermission('create_comment_upgrade_req') ?? false;
    final canDeleteComment = user?.hasPermission('delete_comment_upgrade_req') ?? false;
    final canApprove = user?.hasPermission('approve_upgrade_req') ?? false;
    final canEdit = user?.hasPermission('edit_upgrade_req') ?? false;
    final canDelete = user?.hasPermission('delete_upgrade_req') ?? false;

    // Permission check
    if (!canView) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Permission Required', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'You do not have permission to view upgrade request details.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => context.go('/admin/upgrade-requests'),
                child: const Text('Back to Upgrade Requests'),
              ),
            ],
          ),
        ),
      );
    }

    final requestAsync = ref.watch(upgradeRequestDetailProvider(int.parse(widget.requestId)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade Request Details'),
        actions: [
          if (canEdit)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                // TODO: Navigate to edit screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit feature coming soon')),
                );
              },
            ),
          if (canDelete)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () => _handleDelete(context),
            ),
        ],
      ),
      body: requestAsync.when(
        data: (request) => _buildContent(request, canVote, canComment, canDeleteComment, canApprove, colors, theme),
        loading: () => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: colors.primary),
              const SizedBox(height: 16),
              const Text('Loading request details...'),
            ],
          ),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.error),
              const SizedBox(height: 16),
              Text('Error Loading Request', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('$error', textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.invalidate(upgradeRequestDetailProvider(int.parse(widget.requestId))),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    UpgradeRequestDetail request,
    bool canVote,
    bool canComment,
    bool canDeleteComment,
    bool canApprove,
    ColorScheme colors,
    ThemeData theme,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Member Profile
          _buildMemberHeader(request, colors, theme),
          
          const Divider(height: 1),
          
          // Request Details
          _buildRequestDetails(request, colors, theme),
          
          const Divider(height: 32, thickness: 8),
          
          // Voting Panel
          _buildVotingPanel(request, canVote, colors, theme),
          
          const Divider(height: 32, thickness: 8),
          
          // Comments Section
          _buildCommentsSection(request, canComment, canDeleteComment, colors, theme),
          
          // Admin Actions (for pending requests)
          if (request.isPending && canApprove)
            _buildAdminActions(request, colors, theme),
          
          // Approval Info (for approved/declined requests)
          if (!request.isPending && request.approvalInfo != null)
            _buildApprovalInfo(request.approvalInfo!, colors, theme),
          
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildMemberHeader(UpgradeRequestDetail request, ColorScheme colors, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: colors.surfaceContainerHighest,
      child: Column(
        children: [
          // Member avatar
          CircleAvatar(
            radius: 48,
            backgroundImage: request.member.profileImage != null
                ? NetworkImage(request.member.profileImage!)
                : null,
            child: request.member.profileImage == null
                ? Text(
                    request.member.displayName[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(height: 16),
          
          // Member name
          Text(
            request.member.displayName,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Member email
          if (request.member.email != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                request.member.email!,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontSize: 14,
                ),
              ),
            ),
          
          const SizedBox(height: 24),
          
          // Level change
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Current level
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outline),
                ),
                child: Column(
                  children: [
                    Text(
                      'CURRENT',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.onSurface.withValues(alpha: 0.6),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.currentLevel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Icon(
                  Icons.arrow_forward,
                  size: 32,
                  color: colors.primary,
                ),
              ),
              
              // Requested level
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.primary),
                ),
                child: Column(
                  children: [
                    Text(
                      'REQUESTED',
                      style: TextStyle(
                        fontSize: 10,
                        color: colors.primary,
                        letterSpacing: 1,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      request.requestedLevel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Member stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatItem(
                'Trips',
                '${request.member.tripCount}',
                Icons.explore,
                colors,
              ),
              Container(width: 1, height: 40, color: colors.outline),
              _buildStatItem(
                'Member Since',
                request.member.dateJoined != null
                    ? DateFormat('MMM yyyy').format(request.member.dateJoined!)
                    : 'N/A',
                Icons.calendar_today,
                colors,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, ColorScheme colors) {
    return Column(
      children: [
        Icon(icon, size: 24, color: colors.primary),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.onSurface,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildRequestDetails(UpgradeRequestDetail request, ColorScheme colors, ThemeData theme) {
    // Status color
    Color statusColor;
    IconData statusIcon;
    
    if (request.isPending) {
      statusColor = const Color(0xFFFFA726);
      statusIcon = Icons.pending;
    } else if (request.isApproved) {
      statusColor = const Color(0xFF66BB6A);
      statusIcon = Icons.check_circle;
    } else {
      statusColor = colors.error;
      statusIcon = Icons.cancel;
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status and date
          Row(
            children: [
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
              const Spacer(),
              Text(
                'Submitted ${DateFormat('MMM dd, yyyy').format(request.submittedAt)}',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Reason section
          Text(
            'Reason for Upgrade',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outline),
            ),
            child: Text(
              request.reason,
              style: TextStyle(
                fontSize: 15,
                height: 1.5,
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVotingPanel(UpgradeRequestDetail request, bool canVote, ColorScheme colors, ThemeData theme) {
    final voteSummary = request.voteSummary;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Board Votes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Vote summary
          Row(
            children: [
              Expanded(
                child: _buildVoteSummaryCard(
                  'Approve',
                  voteSummary.approveCount,
                  Icons.thumb_up,
                  const Color(0xFF66BB6A),
                  colors,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildVoteSummaryCard(
                  'Decline',
                  voteSummary.declineCount,
                  Icons.thumb_down,
                  colors.error,
                  colors,
                ),
              ),
            ],
          ),
          
          // Approval percentage
          if (voteSummary.totalVotes > 0)
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
                          fontSize: 14,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        '${voteSummary.approvalPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: voteSummary.approvalPercentage / 100,
                    backgroundColor: colors.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(colors.primary),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            ),
          
          // Your vote status
          if (voteSummary.currentUserVoted)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (voteSummary.currentUserVote ?? false)
                      ? const Color(0xFF66BB6A).withValues(alpha: 0.1)
                      : colors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: (voteSummary.currentUserVote ?? false)
                        ? const Color(0xFF66BB6A)
                        : colors.error,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      (voteSummary.currentUserVote ?? false) ? Icons.thumb_up : Icons.thumb_down,
                      size: 20,
                      color: (voteSummary.currentUserVote ?? false)
                          ? const Color(0xFF66BB6A)
                          : colors.error,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'You voted to ${(voteSummary.currentUserVote ?? false) ? "approve" : "decline"}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: (voteSummary.currentUserVote ?? false)
                            ? const Color(0xFF66BB6A)
                            : colors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Vote buttons (if can vote and pending)
          if (canVote && request.isPending)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleVote(true),
                      icon: const Icon(Icons.thumb_up),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF66BB6A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _handleVote(false),
                      icon: const Icon(Icons.thumb_down),
                      label: const Text('Decline'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          
          // Individual votes list
          if (request.votes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Individual Votes (${request.votes.length})',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...request.votes.map((vote) => _buildVoteItem(vote, colors, theme)),
          ],
        ],
      ),
    );
  }

  Widget _buildVoteSummaryCard(String label, int count, IconData icon, Color color, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32, color: color),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoteItem(Vote vote, ColorScheme colors, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: vote.voter.profileImage != null
                ? NetworkImage(vote.voter.profileImage!)
                : null,
            child: vote.voter.profileImage == null
                ? Text(vote.voter.displayName[0].toUpperCase())
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  vote.voter.displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  DateFormat('MMM dd, yyyy - HH:mm').format(vote.votedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                if (vote.comment != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      vote.comment!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: colors.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            vote.approve ? Icons.thumb_up : Icons.thumb_down,
            color: vote.approve ? const Color(0xFF66BB6A) : colors.error,
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(
    UpgradeRequestDetail request,
    bool canComment,
    bool canDeleteComment,
    ColorScheme colors,
    ThemeData theme,
  ) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Comments (${request.comments.length})',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          
          // Add comment form
          if (canComment && request.isPending)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Add a comment...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: colors.surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filled(
                    onPressed: _handleAddComment,
                    icon: const Icon(Icons.send),
                    style: IconButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ],
              ),
            ),
          
          // Comments list
          if (request.comments.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.comment_outlined,
                      size: 48,
                      color: colors.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No comments yet',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Column(
                children: request.comments.map((comment) {
                  return _buildCommentItem(comment, canDeleteComment, colors, theme);
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(UpgradeRequestComment comment, bool canDeleteComment, ColorScheme colors, ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundImage: comment.author.profileImage != null
                      ? NetworkImage(comment.author.profileImage!)
                      : null,
                  child: comment.author.profileImage == null
                      ? Text(
                          comment.author.displayName[0].toUpperCase(),
                          style: const TextStyle(fontSize: 14),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.author.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy - HH:mm').format(comment.createdAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (comment.canDelete || canDeleteComment)
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colors.error),
                    onPressed: () => _handleDeleteComment(comment.id),
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              comment.text,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminActions(UpgradeRequestDetail request, ColorScheme colors, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                'Admin Actions',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApprove(request.id),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Approve Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF66BB6A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleDeclineDialog(request.id),
                  icon: const Icon(Icons.cancel),
                  label: const Text('Decline Request'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApprovalInfo(ApprovalInfo info, ColorScheme colors, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: info.isApproved
            ? const Color(0xFF66BB6A).withValues(alpha: 0.1)
            : colors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: info.isApproved
              ? const Color(0xFF66BB6A)
              : colors.error,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                info.isApproved ? Icons.check_circle : Icons.cancel,
                color: info.isApproved ? const Color(0xFF66BB6A) : colors.error,
              ),
              const SizedBox(width: 8),
              Text(
                info.isApproved ? 'Approved' : 'Declined',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: info.isApproved ? const Color(0xFF66BB6A) : colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'By: ${info.decidedBy.displayName}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          Text(
            'On: ${DateFormat('MMM dd, yyyy - HH:mm').format(info.decidedAt)}',
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          if (info.reason != null) ...[
            const SizedBox(height: 12),
            Text(
              'Reason:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              info.reason!,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurface.withValues(alpha: 0.8),
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Action handlers
  Future<void> _handleVote(bool approve) async {
    try {
      await ref.read(upgradeRequestActionsProvider.notifier).vote(
        requestId: int.parse(widget.requestId),
        vote: approve ? 'Y' : 'N',  // Convert bool to Y/N format
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Vote submitted: ${approve ? "Approve" : "Decline"}'),
            backgroundColor: approve ? const Color(0xFF66BB6A) : Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit vote: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleAddComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await ref.read(upgradeRequestActionsProvider.notifier).addComment(
        requestId: int.parse(widget.requestId),
        text: _commentController.text.trim(),
      );
      
      _commentController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added successfully'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add comment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteComment(int commentId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await ref.read(upgradeRequestActionsProvider.notifier).deleteComment(
        requestId: int.parse(widget.requestId),
        commentId: commentId,
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete comment: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleApprove(int requestId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Upgrade Request'),
        content: const Text('Are you sure you want to approve this upgrade request? This action is final.'),
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

    if (confirm != true) return;

    try {
      await ref.read(upgradeRequestActionsProvider.notifier).approve(requestId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Request approved successfully!'),
            backgroundColor: Color(0xFF66BB6A),
          ),
        );
        
        // Navigate back to list
        context.go('/admin/upgrade-requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve request: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDeclineDialog(int requestId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Upgrade Request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for declining this request:'),
            const SizedBox(height: 16),
            TextField(
              controller: _declineReasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Reason for declining...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_declineReasonController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a reason')),
                );
                return;
              }
              Navigator.pop(context, _declineReasonController.text.trim());
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Decline'),
          ),
        ],
      ),
    );

    if (result == null) return;

    try {
      await ref.read(upgradeRequestActionsProvider.notifier).decline(
        requestId: requestId,
        reason: result,
      );
      
      _declineReasonController.clear();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request declined')),
        );
        
        // Navigate back to list
        context.go('/admin/upgrade-requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline request: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Upgrade Request'),
        content: const Text('Are you sure you want to delete this upgrade request? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      await repository.deleteUpgradeRequest(int.parse(widget.requestId));
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request deleted successfully')),
        );
        
        // Navigate back to list
        context.go('/admin/upgrade-requests');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete request: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
