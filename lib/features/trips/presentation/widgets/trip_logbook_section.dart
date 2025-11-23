import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import 'sign_off_bottom_sheet.dart';
import 'bulk_sign_off_bottom_sheet.dart';

/// Trip Logbook Section Widget
/// 
/// Displays logbook information in trip details context
/// - For marshals: Shows attendees with sign-off actions
/// - For members: Shows their logbook entry status
/// - For others: Shows logbook summary
class TripLogbookSection extends ConsumerStatefulWidget {
  final dynamic trip; // Trip model
  final ColorScheme colors;

  const TripLogbookSection({
    super.key,
    required this.trip,
    required this.colors,
  });

  @override
  ConsumerState<TripLogbookSection> createState() => _TripLogbookSectionState();
}

class _TripLogbookSectionState extends ConsumerState<TripLogbookSection> {
  bool _isLoadingEntries = false;
  List<Map<String, dynamic>> _logbookEntries = [];
  Map<int, LogbookEntry?> _memberEntries = {}; // memberId -> LogbookEntry
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTripLogbookEntries();
  }

  Future<void> _loadTripLogbookEntries() async {
    setState(() {
      _isLoadingEntries = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final tripId = widget.trip['id'] as int;
      
      // Get logbook entries for this trip
      final response = await repository.getLogbookEntries(
        tripId: tripId,
        pageSize: 100, // Get all entries for this trip
      );

      if (kDebugMode) {
        debugPrint('📊 Logbook API Response: $response');
      }

      final entries = response['results'] as List<dynamic>? ?? [];
      
      if (kDebugMode) {
        debugPrint('📊 Total entries: ${entries.length}');
        if (entries.isNotEmpty) {
          debugPrint('📊 First entry structure: ${entries.first}');
        }
      }
      
      // Build a map of member IDs to full member data from trip.registered
      final registeredMembers = widget.trip['registered'] as List? ?? [];
      final memberDataMap = <int, Map<String, dynamic>>{};
      for (var registration in registeredMembers) {
        final memberData = registration['member'] as Map<String, dynamic>;
        final memberId = memberData['id'] as int;
        memberDataMap[memberId] = memberData;
      }
      
      setState(() {
        _logbookEntries = entries.cast<Map<String, dynamic>>();
        
        // Build member -> entry map for quick lookup
        // Enrich entries with full member details from trip.registered
        _memberEntries = {};
        for (var entryData in _logbookEntries) {
          try {
            // Create a copy of entryData to enrich with full member info
            final enrichedData = Map<String, dynamic>.from(entryData);
            
            // If member is just an ID, replace with full member data
            final memberId = entryData['member'];
            if (memberId is int && memberDataMap.containsKey(memberId)) {
              enrichedData['member'] = memberDataMap[memberId];
            }
            
            // If signedBy is just an ID, replace with full member data
            final signedById = entryData['signedBy'];
            if (signedById is int && memberDataMap.containsKey(signedById)) {
              enrichedData['signedBy'] = memberDataMap[signedById];
            }
            
            // Parse the enriched entry
            final entry = LogbookEntry.fromJson(enrichedData);
            _memberEntries[entry.member.id] = entry;
          } catch (e) {
            // Skip entries that fail to parse but log the error
            if (kDebugMode) {
              debugPrint('⚠️ Failed to parse logbook entry: $e');
              debugPrint('Entry data: $entryData');
            }
          }
        }
        
        _isLoadingEntries = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load logbook entries: $e';
        _isLoadingEntries = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProviderV2).user;
    final theme = Theme.of(context);
    
    // Check permissions
    final canSignOff = user?.hasPermission('sign_logbook_skills') ?? false;
    final isLead = user != null && widget.trip['lead']?['id'] == user.id;
    final isDeputy = user != null && 
        (widget.trip['deputyLeads'] as List?)?.any((deputy) => deputy['id'] == user.id) == true;
    final isMarshal = canSignOff && (isLead || isDeputy);
    
    // Check if user is registered for this trip
    final registeredMembers = widget.trip['registered'] as List? ?? [];
    final isRegistered = user != null &&
        registeredMembers.any((member) => (member['member'] as Map?)?['id'] == user.id);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Header
            Row(
              children: [
                Icon(Icons.book, color: widget.colors.primary, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Trip Logbook',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: widget.colors.primary,
                        ),
                      ),
                      Text(
                        isMarshal
                            ? 'Sign off skills for trip attendees'
                            : 'View logbook entries for this trip',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: widget.colors.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingEntries)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            
            // Content based on role
            if (_error != null)
              _buildErrorState(theme)
            else if (_isLoadingEntries)
              _buildLoadingState()
            else if (isMarshal)
              _buildMarshalView(theme)
            else if (isRegistered)
              _buildMemberView(user!, theme)
            else
              _buildGuestView(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: widget.colors.error),
          const SizedBox(height: 8),
          Text(
            _error!,
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadTripLogbookEntries,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  /// Marshal View: Shows all registered members with sign-off buttons
  Widget _buildMarshalView(ThemeData theme) {
    final registeredMembers = widget.trip['registered'] as List? ?? [];
    
    if (registeredMembers.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.people_outline,
                size: 48,
                color: widget.colors.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 8),
              Text(
                'No registered members yet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary stats
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.colors.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                icon: Icons.people,
                label: 'Attendees',
                value: '${registeredMembers.length}',
                theme: theme,
              ),
              _buildStatItem(
                icon: Icons.verified,
                label: 'Signed Off',
                value: '${_memberEntries.length}',
                theme: theme,
              ),
              _buildStatItem(
                icon: Icons.pending_actions,
                label: 'Pending',
                value: '${registeredMembers.length - _memberEntries.length}',
                theme: theme,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Bulk Sign-Off Button
        if (registeredMembers.isNotEmpty)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _showBulkSignOffSheet(registeredMembers, theme),
              icon: const Icon(Icons.checklist),
              label: const Text('Bulk Sign Off'),
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.colors.secondaryContainer,
                foregroundColor: widget.colors.onSecondaryContainer,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
            ),
          ),
        
        const SizedBox(height: 16),
        
        Text(
          'Registered Members',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        
        // Member list with sign-off status
        ...registeredMembers.map((registrationData) {
          final memberData = registrationData['member'] as Map<String, dynamic>;
          final memberId = memberData['id'] as int;
          final entry = _memberEntries[memberId];
          final hasEntry = entry != null;
          
          return _buildMemberCard(
            memberData: memberData,
            entry: entry,
            hasEntry: hasEntry,
            theme: theme,
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required ThemeData theme,
  }) {
    return Column(
      children: [
        Icon(icon, color: widget.colors.primary, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: widget.colors.primary,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: widget.colors.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard({
    required Map<String, dynamic> memberData,
    required LogbookEntry? entry,
    required bool hasEntry,
    required ThemeData theme,
  }) {
    final firstName = memberData['firstName'] as String? ?? '';
    final lastName = memberData['lastName'] as String? ?? '';
    final username = memberData['username'] as String? ?? '';
    final displayName = '$firstName $lastName'.trim();
    final profilePicture = memberData['profilePicture'] as String?;
    
    // Extract level info
    String levelName = 'No Level';
    final levelData = memberData['level'];
    if (levelData is String) {
      levelName = levelData;
    } else if (levelData is Map<String, dynamic>) {
      levelName = levelData['name'] as String? ?? 'No Level';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Member avatar
            CircleAvatar(
              radius: 24,
              backgroundImage: profilePicture != null
                  ? NetworkImage(profilePicture)
                  : null,
              child: profilePicture == null
                  ? Text(
                      firstName.isNotEmpty ? firstName[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 18),
                    )
                  : null,
            ),
            
            const SizedBox(width: 12),
            
            // Member info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName.isNotEmpty ? displayName : username,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (username.isNotEmpty)
                    Text(
                      '@$username',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.colors.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  Chip(
                    label: Text(levelName),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    backgroundColor: widget.colors.primaryContainer,
                    labelStyle: TextStyle(
                      fontSize: 11,
                      color: widget.colors.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            
            // Status/Action
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (hasEntry) ...[
                  Icon(
                    Icons.check_circle,
                    color: widget.colors.primary,
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${entry?.skillsVerified.length ?? 0} skills',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.colors.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  OutlinedButton(
                    onPressed: () => _showSignOffSheet(memberData, entry),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('More Skills', style: TextStyle(fontSize: 12)),
                  ),
                ] else ...[
                  Icon(
                    Icons.pending_actions,
                    color: widget.colors.onSurface.withValues(alpha: 0.4),
                    size: 28,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Not signed off',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: widget.colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ElevatedButton(
                    onPressed: () => _showSignOffSheet(memberData, null),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text('Sign Off', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Member View: Shows their own logbook entry
  Widget _buildMemberView(dynamic user, ThemeData theme) {
    final entry = _memberEntries[user.id];
    
    if (entry == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(
                Icons.pending_actions,
                size: 48,
                color: widget.colors.onSurface.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 12),
              Text(
                'No logbook entry yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Your marshal will sign off skills after the trip',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: widget.colors.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.colors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.colors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.verified, color: widget.colors.primary, size: 28),
              const SizedBox(width: 12),
              Text(
                'Your Logbook Entry',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: widget.colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Skills verified
          Text(
            'Skills Verified (${entry.skillsVerified.length})',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: entry.skillsVerified.map((skill) {
              return Chip(
                avatar: const Icon(Icons.check_circle, size: 16),
                label: Text(skill.name),
                backgroundColor: widget.colors.primaryContainer,
                labelStyle: TextStyle(
                  color: widget.colors.onPrimaryContainer,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          
          // Marshal info
          Row(
            children: [
              Icon(Icons.badge, size: 20, color: widget.colors.tertiary),
              const SizedBox(width: 8),
              Text(
                'Signed by ${entry.signedBy.displayName}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 20, color: widget.colors.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                dateFormat.format(entry.createdAt),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: widget.colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          
          // Comment (if any)
          if (entry.comment != null && entry.comment!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: widget.colors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.comment,
                    size: 16,
                    color: widget.colors.onSurface.withValues(alpha: 0.6),
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
    );
  }

  /// Guest View: Shows summary
  Widget _buildGuestView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.book_outlined,
              size: 48,
              color: widget.colors.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 12),
            Text(
              '${_logbookEntries.length} logbook ${_logbookEntries.length == 1 ? 'entry' : 'entries'}',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Register for this trip to receive logbook entries',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: widget.colors.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOffSheet(Map<String, dynamic> memberData, LogbookEntry? existingEntry) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SignOffBottomSheet(
        trip: widget.trip,
        memberData: memberData,
        existingEntry: existingEntry,
        onSuccess: () {
          // Reload entries after successful sign-off
          _loadTripLogbookEntries();
        },
      ),
    );
  }

  void _showBulkSignOffSheet(List<dynamic> registrations, ThemeData theme) {
    // Extract member data from registrations
    final members = registrations
        .map((reg) => reg['member'] as Map<String, dynamic>)
        .toList();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BulkSignOffBottomSheet(
        trip: widget.trip,
        members: members,
        existingEntries: _memberEntries,
        onSuccess: () {
          // Reload entries after successful bulk sign-off
          _loadTripLogbookEntries();
        },
      ),
    );
  }
}
