import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../data/models/upgrade_request_model.dart';

/// Member Upgrade Requests Screen
/// 
/// Displays member's own upgrade request history and allows creating new requests
class MemberUpgradeRequestsScreen extends ConsumerStatefulWidget {
  const MemberUpgradeRequestsScreen({super.key});

  @override
  ConsumerState<MemberUpgradeRequestsScreen> createState() => _MemberUpgradeRequestsScreenState();
}

class _MemberUpgradeRequestsScreenState extends ConsumerState<MemberUpgradeRequestsScreen> {
  final MainApiRepository _repository = MainApiRepository();
  List<UpgradeRequestListItem> _requests = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUpgradeRequests();
  }

  Future<void> _loadUpgradeRequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authState = ref.read(authProviderV2);
      final userId = authState.user?.id;
      
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // ✅ FIXED: Use member-specific endpoint instead of admin endpoint
      // This endpoint returns only the current member's upgrade requests
      final response = await _repository.getMemberUpgradeRequests(
        memberId: userId,
        page: 1,
        pageSize: 100,
      );

      // 🔍 DEBUG: Log raw response to understand structure
      if (kDebugMode) {
        print('📦 ===== RAW API RESPONSE =====');
        print('Response type: ${response.runtimeType}');
        print('Response keys: ${response.keys.toList()}');
        print('Full response: $response');
        print('==============================');
      }

      // ⚠️ CRITICAL: Member endpoint returns different format than admin endpoint
      // The response might be MemberUpgradeHistory instead of UpgradeRequestListItem
      if (response['results'] == null) {
        // If results is null, response might be formatted differently
        setState(() {
          _requests = [];
          _isLoading = false;
        });
        return;
      }

      final results = response['results'] as List<dynamic>? ?? [];
      
      // 🔍 DEBUG: Log results array
      if (kDebugMode) {
        print('📦 Results count: ${results.length}');
        print('📦 Results type: ${results.runtimeType}');
        if (results.isNotEmpty) {
          print('📦 First result type: ${results[0].runtimeType}');
          print('📦 First result: ${results[0]}');
        }
      }
      
      // Try to parse with defensive handling
      final requests = <UpgradeRequestListItem>[];
      for (int i = 0; i < results.length; i++) {
        final item = results[i];
        try {
          if (kDebugMode) {
            print('🔄 Parsing item $i: type=${item.runtimeType}');
          }
          
          if (item is Map<String, dynamic>) {
            if (kDebugMode) {
              print('   Item keys: ${item.keys.toList()}');
              print('   Member field: ${item['member']}');
              print('   Member field type: ${item['member']?.runtimeType}');
            }
            
            requests.add(UpgradeRequestListItem.fromJson(item));
            
            if (kDebugMode) {
              print('   ✅ Parsed successfully');
            }
          } else {
            if (kDebugMode) {
              print('   ⚠️ Item is not Map<String, dynamic>, skipping');
            }
          }
        } catch (parseError, stackTrace) {
          // Skip items that fail to parse
          if (kDebugMode) {
            print('❌ Failed to parse upgrade request item $i: $parseError');
            print('   Item type: ${item.runtimeType}');
            print('   Item data: $item');
            print('   Stack trace: $stackTrace');
          }
        }
      }

      // Sort by submitted date (newest first)
      requests.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

      setState(() {
        _requests = requests;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error loading upgrade requests: $e');
        print('   Stack trace: $stackTrace');
      }
      setState(() {
        _error = 'Failed to load upgrade requests: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final authState = ref.watch(authProviderV2);
    final user = authState.user;
    
    // Check if user can create upgrade requests
    final canCreateRequest = user?.hasPermission('create_upgrade_req_for_self') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Upgrade Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Help',
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _requests.isEmpty
                  ? _buildEmptyState(colors, canCreateRequest)
                  : _buildRequestsList(colors),
      floatingActionButton: canCreateRequest
          ? FloatingActionButton.extended(
              onPressed: () async {
                // ✅ FIXED: Await navigation and reload if successful
                final result = await context.push('/logbook/upgrade-requests/create');
                if (result == true && mounted) {
                  // Reload the list after successful creation
                  _loadUpgradeRequests();
                }
              },
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Request Upgrade'),
            )
          : null,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _loadUpgradeRequests,
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colors, bool canCreateRequest) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.trending_up,
              size: 80,
              color: colors.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 24),
            Text(
              'No Upgrade Requests',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              canCreateRequest
                  ? 'Ready to level up? Request an upgrade to advance your off-road skills certification.'
                  : 'You haven\'t submitted any upgrade requests yet.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            if (canCreateRequest) ...[
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () async {
                  // ✅ FIXED: Await navigation and reload if successful
                  final result = await context.push('/logbook/upgrade-requests/create');
                  if (result == true && mounted) {
                    _loadUpgradeRequests();
                  }
                },
                icon: const Icon(Icons.arrow_upward),
                label: const Text('Request Upgrade'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRequestsList(ColorScheme colors) {
    return RefreshIndicator(
      onRefresh: _loadUpgradeRequests,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          return _buildRequestCard(request, colors);
        },
      ),
    );
  }

  Widget _buildRequestCard(UpgradeRequestListItem request, ColorScheme colors) {
    final statusColor = _getStatusColor(request.status);
    final statusIcon = _getStatusIcon(request.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showRequestDetails(request),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Level Progression and Status
              Row(
                children: [
                  Icon(Icons.trending_up, color: colors.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      children: [
                        // Current Level
                        Flexible(
                          child: Text(
                            request.currentLevel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: colors.onSurface.withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            Icons.arrow_forward,
                            size: 16,
                            color: colors.primary,
                          ),
                        ),
                        // Requested Level
                        Flexible(
                          child: Text(
                            request.requestedLevel,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: colors.primary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          _formatStatus(request.status),
                          style: TextStyle(
                            fontSize: 12,
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Voting Progress
              if (request.voteSummary != null) ...[
                Row(
                  children: [
                    Icon(
                      Icons.how_to_vote,
                      size: 16,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Votes: ${request.voteSummary!.totalVotes}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: LinearProgressIndicator(
                        value: request.voteSummary!.approvalPercentage / 100,
                        backgroundColor: Colors.red.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${request.voteSummary!.approvalPercentage.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              
              // Date info
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Submitted ${DateFormat('MMM dd, yyyy').format(request.submittedAt)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(
                    Icons.comment,
                    size: 14,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${request.commentCount} comments',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStatus(String status) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'pending':
        return 'Pending';
      case 'approved':
        return 'Approved';
      case 'declined':
        return 'Declined';
      case 'in_progress':
        return 'In Progress';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'pending':
        return Colors.blue;
      case 'in_progress':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'declined':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    final normalized = status.toLowerCase();
    switch (normalized) {
      case 'pending':
        return Icons.new_releases;
      case 'in_progress':
        return Icons.pending;
      case 'approved':
        return Icons.check_circle;
      case 'declined':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  void _showRequestDetails(UpgradeRequestListItem request) {
    showDialog(
      context: context,
      builder: (context) => _buildRequestDetailDialog(request),
    );
  }

  Widget _buildRequestDetailDialog(UpgradeRequestListItem request) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final statusColor = _getStatusColor(request.status);
    final isDeclined = request.isDeclined;
    final isApproved = request.isApproved;
    final isPending = request.isPending;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status
                Row(
                  children: [
                    Icon(
                      _getStatusIcon(request.status),
                      color: statusColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Upgrade Request',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: statusColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _formatStatus(request.status),
                              style: TextStyle(
                                fontSize: 12,
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Close',
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Level progression
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Current Level',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                request.currentLevel,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Icon(
                        Icons.arrow_forward,
                        color: colors.primary,
                        size: 24,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Requested Level',
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.primary.withValues(alpha: 0.8),
                              ),
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                request.requestedLevel,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Submission date
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Submitted on ${DateFormat('MMMM dd, yyyy').format(request.submittedAt)}',
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),

                // Voting progress (for pending/in-progress requests)
                if (isPending && request.voteSummary != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'Voting Progress',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.how_to_vote,
                        size: 18,
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${request.voteSummary!.totalVotes} votes received',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: request.voteSummary!.approvalPercentage / 100,
                    backgroundColor: Colors.red.shade100,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade400),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${request.voteSummary!.approvalPercentage.toStringAsFixed(0)}% approval',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                ],

                // Decline reason (for declined requests)
                if (isDeclined) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Decline Reason',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade200,
                        width: 1,
                      ),
                    ),
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _repository.getUpgradeRequestDetail(request.id),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              SizedBox(width: 12),
                              Text('Loading decline reason...'),
                            ],
                          );
                        }
                        
                        if (snapshot.hasError) {
                          // Log error for debugging
                          if (kDebugMode) {
                            debugPrint('❌ Error loading decline reason: ${snapshot.error}');
                          }
                          return Text(
                            'Unable to load decline reason: ${snapshot.error}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.red.shade900,
                            ),
                          );
                        }
                        
                        if (snapshot.hasData) {
                          try {
                            // Log raw data for debugging
                            if (kDebugMode) {
                              debugPrint('📦 Decline reason data: ${snapshot.data}');
                            }
                            
                            final detail = UpgradeRequestDetail.fromJson(snapshot.data!);
                            
                            // Check multiple possible sources for decline reason
                            String? reason;
                            
                            // Try approval_info.reason first
                            if (detail.approvalInfo?.reason != null && detail.approvalInfo!.reason!.isNotEmpty) {
                              reason = detail.approvalInfo!.reason;
                            }
                            // Try direct reason field
                            else if (snapshot.data!['reason'] != null && snapshot.data!['reason'].toString().isNotEmpty) {
                              reason = snapshot.data!['reason'].toString();
                            }
                            // Try declineReason field
                            else if (snapshot.data!['declineReason'] != null && snapshot.data!['declineReason'].toString().isNotEmpty) {
                              reason = snapshot.data!['declineReason'].toString();
                            }
                            // Try decline_reason field
                            else if (snapshot.data!['decline_reason'] != null && snapshot.data!['decline_reason'].toString().isNotEmpty) {
                              reason = snapshot.data!['decline_reason'].toString();
                            }
                            
                            final displayReason = reason ?? 'No reason provided by admin';
                            
                            if (kDebugMode) {
                              debugPrint('📝 Display reason: $displayReason');
                            }
                            
                            return Text(
                              displayReason,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.5,
                                color: Colors.red.shade900,
                              ),
                            );
                          } catch (e) {
                            if (kDebugMode) {
                              debugPrint('❌ Error parsing decline reason: $e');
                            }
                            return Text(
                              'Unable to parse decline reason: $e',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.red.shade900,
                              ),
                            );
                          }
                        }
                        
                        return Text(
                          'No decline reason available',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.red.shade900,
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Approval info (for approved requests)
                if (isApproved) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.green.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Congratulations! Your upgrade request has been approved.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // Close button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline),
              SizedBox(width: 12),
              Text('Upgrade Requests'),
            ],
          ),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'About Upgrade Requests',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Submit upgrade requests to advance to higher skill levels. Your request will be reviewed and voted on by nominated marshals and board members.',
                ),
                SizedBox(height: 16),
                Text(
                  'Request Process:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('1. Submit upgrade request with justification'),
                Text('2. Nominated voters review and vote'),
                Text('3. Board makes final decision'),
                Text('4. You receive notification of outcome'),
                SizedBox(height: 16),
                Text(
                  'Status Meanings:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text('• New - Just submitted, pending review'),
                Text('• In Progress - Voting is underway'),
                Text('• Approved - Congratulations! Level upgraded'),
                Text('• Declined - Not approved this time'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Got it'),
            ),
          ],
        );
      },
    );
  }
}
