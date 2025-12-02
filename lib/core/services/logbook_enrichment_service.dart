import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/logbook_model.dart';
import '../../data/repositories/main_api_repository.dart';
import '../providers/repository_providers.dart';

/// Logbook Data Enrichment Service
/// 
/// Centralized service for enriching logbook entries with actual names
/// instead of ID placeholders. Caches member profiles, trip details, and
/// skill information for performance optimization.
/// 
/// Usage:
/// ```dart
/// final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
/// final enrichedEntries = await enrichmentService.enrichLogbookEntries(entries);
/// ```
class LogbookEnrichmentService {
  final MainApiRepository _repository;

  // Global caches for enrichment data
  final Map<int, Map<String, dynamic>> _memberCache = {};
  final Map<int, Map<String, dynamic>> _tripCache = {};
  final Map<int, Map<String, dynamic>> _skillCache = {};

  LogbookEnrichmentService(this._repository);

  /// Clear all caches (useful for testing or forcing refresh)
  void clearCaches() {
    _memberCache.clear();
    _tripCache.clear();
    _skillCache.clear();
    print('🧹 LogbookEnrichmentService: All caches cleared');
  }

  /// Enrich a single logbook entry with actual names
  Future<LogbookEntry> enrichLogbookEntry(LogbookEntry entry) async {
    print('🔄 Enriching logbook entry #${entry.id}...');
    print('   Member: ${entry.member.firstName} ${entry.member.lastName} (ID: ${entry.member.id})');
    print('   SignedBy: ${entry.signedBy.firstName} ${entry.signedBy.lastName} (ID: ${entry.signedBy.id})');

    // Enrich member
    final enrichedMember = await _enrichMember(entry.member);
    print('   → Enriched Member: ${enrichedMember.displayName}');

    // Enrich signedBy (marshal)
    final enrichedSignedBy = await _enrichMember(entry.signedBy);
    print('   → Enriched Marshal: ${enrichedSignedBy.displayName}');

    // Enrich trip
    final enrichedTrip = entry.trip != null 
        ? await _enrichTrip(entry.trip!)
        : null;

    // Enrich skills
    final enrichedSkills = await _enrichSkills(entry.skillsVerified);

    // Create enriched entry
    return LogbookEntry(
      id: entry.id,
      member: enrichedMember,
      trip: enrichedTrip,
      signedBy: enrichedSignedBy,
      skillsVerified: enrichedSkills,
      comment: entry.comment,
      createdAt: entry.createdAt,
      updatedAt: entry.updatedAt,
    );
  }

  /// Enrich multiple logbook entries (batch operation)
  Future<List<LogbookEntry>> enrichLogbookEntries(
    List<LogbookEntry> entries,
  ) async {
    if (entries.isEmpty) {
      print('⚠️ enrichLogbookEntries called with empty list');
      return [];
    }

    print('═══════════════════════════════════════════════════════');
    print('🔄 STARTING BATCH ENRICHMENT: ${entries.length} entries');
    print('═══════════════════════════════════════════════════════');

    // Step 1: Pre-fetch skills (small dataset, can load all at once)
    await _prefetchSkills();

    // Step 2: Collect unique member IDs (member + signedBy)
    final uniqueMemberIds = <int>{};
    for (final entry in entries) {
      uniqueMemberIds.add(entry.member.id);
      uniqueMemberIds.add(entry.signedBy.id);
    }

    // Step 3: Collect unique trip IDs
    final uniqueTripIds = <int>{};
    for (final entry in entries) {
      if (entry.trip != null) {
        uniqueTripIds.add(entry.trip!.id);
      }
    }

    // Step 4: Batch fetch missing members
    await _batchFetchMembers(uniqueMemberIds);

    // Step 5: Batch fetch missing trips
    await _batchFetchTrips(uniqueTripIds);

    // Step 6: Enrich all entries
    print('\n📋 STEP 6: Enriching all entries...');
    final enrichedEntries = <LogbookEntry>[];
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      try {
        print('\n───────────────────────────────────────────────────────');
        print('Processing entry ${i + 1}/${entries.length}: #${entry.id}');
        final enriched = await enrichLogbookEntry(entry);
        enrichedEntries.add(enriched);
        print('✅ Entry #${entry.id} enriched successfully');
      } catch (e, stackTrace) {
        print('❌ Failed to enrich entry #${entry.id}: $e');
        print('Stack trace: $stackTrace');
        enrichedEntries.add(entry); // Use original if enrichment fails
      }
    }

    print('\n═══════════════════════════════════════════════════════');
    print('✅ BATCH ENRICHMENT COMPLETE: ${enrichedEntries.length} entries');
    print('═══════════════════════════════════════════════════════\n');
    return enrichedEntries;
  }

  // ============================================================================
  // MEMBER ENRICHMENT
  // ============================================================================

  /// Enrich a member with actual profile data
  Future<MemberBasicInfo> _enrichMember(MemberBasicInfo member) async {
    // Check if this is a placeholder
    // Look for 'Member', 'Marshal', or lastName starting with '#'
    final isPlaceholder = member.firstName == 'Member' || 
                          member.firstName == 'Marshal' ||
                          member.lastName.startsWith('#');

    if (!isPlaceholder) {
      // Already enriched, return as-is
      return member;
    }
    
    print('🔍 Enriching ${member.firstName} ${member.lastName} (ID: ${member.id})...');

    // Fetch from cache or API
    final profile = await _fetchMemberProfile(member.id);

    // Extract name components
    final username = profile['username'] as String?;
    final displayName = profile['displayName'] as String?;
    final firstName = profile['firstName'] as String?;
    final lastName = profile['lastName'] as String?;
    final profilePicture = profile['profilePicture'] as String?;
    final level = profile['level'] as Map<String, dynamic>?;

    // Construct enriched MemberBasicInfo
    // IMPORTANT: Use username as the display name by setting it as firstName
    // This ensures displayName getter returns the username
    String finalFirstName;
    String finalLastName = '';
    
    if (username != null && username.isNotEmpty) {
      // Use username directly as firstName so displayName shows username
      finalFirstName = username;
      finalLastName = '';  // Empty lastName so displayName is just the username
      print('   ✅ Using username: "$username" for member ${member.id}');
    } else if (displayName != null && displayName.isNotEmpty) {
      // Fallback to displayName
      finalFirstName = displayName;
      finalLastName = '';
      print('   ⚠️ No username, using displayName: "$displayName" for member ${member.id}');
    } else if (firstName != null && firstName.isNotEmpty) {
      // Last resort: use firstName + lastName
      finalFirstName = firstName;
      finalLastName = lastName ?? '';
      print('   ⚠️ No username/displayName, using firstName+lastName: "$firstName $lastName" for member ${member.id}');
    } else {
      finalFirstName = 'Unknown';
      finalLastName = '';
      print('   ❌ No name data available for member ${member.id}');
    }
    
    print('   → Final displayName will be: "$finalFirstName${finalLastName.isNotEmpty ? " $finalLastName" : ""}"');
    
    return MemberBasicInfo(
      id: member.id,
      firstName: finalFirstName,
      lastName: finalLastName,
      profilePicture: profilePicture,
      level: level != null ? LevelBasicInfo.fromJson(level) : null,
    );
  }

  /// Fetch member profile from cache or API
  Future<Map<String, dynamic>> _fetchMemberProfile(int memberId) async {
    // Check cache first
    if (_memberCache.containsKey(memberId)) {
      return _memberCache[memberId]!;
    }

    // Fetch from API
    try {
      final profile = await _repository.getMemberDetail(memberId);
      _memberCache[memberId] = profile;
      print('   ✅ Member $memberId → "${profile['username'] ?? profile['displayName']}"');
      return profile;
    } catch (e) {
      print('   ⚠️ Failed to fetch member $memberId: $e');
      // Return minimal fallback
      return {
        'id': memberId,
        'username': 'Member #$memberId',
        'firstName': 'Member',
        'lastName': '#$memberId',
      };
    }
  }

  /// Batch fetch multiple members
  Future<void> _batchFetchMembers(Set<int> memberIds) async {
    final missingIds = memberIds.where((id) => !_memberCache.containsKey(id));
    if (missingIds.isEmpty) {
      print('✅ All members cached (${_memberCache.length} total)');
      return;
    }

    print('🔍 Fetching ${missingIds.length} member profiles...');
    for (final memberId in missingIds) {
      await _fetchMemberProfile(memberId);
    }
    print('✅ Member cache built: ${_memberCache.length} members');
  }

  // ============================================================================
  // TRIP ENRICHMENT
  // ============================================================================

  /// Enrich a trip with actual details
  Future<TripBasicInfo> _enrichTrip(TripBasicInfo trip) async {
    // Check if this is a placeholder (title starts with 'Trip #')
    final isPlaceholder = trip.title.startsWith('Trip #');

    if (!isPlaceholder) {
      // Already enriched, return as-is
      return trip;
    }

    // Fetch from cache or API
    final details = await _fetchTripDetails(trip.id);

    // Extract trip info
    final title = details['title'] as String?;
    final startTime = details['startTime'] as String?;
    
    // Handle level - could be int or Map
    final levelData = details['level'];
    LevelBasicInfo? enrichedLevel;
    
    if (levelData is Map<String, dynamic>) {
      enrichedLevel = LevelBasicInfo.fromJson(levelData);
    } else if (levelData is int) {
      // If level is just an ID, keep original trip level
      enrichedLevel = trip.level;
      print('   ⚠️ Trip level is ID ($levelData), keeping original level');
    } else {
      enrichedLevel = trip.level;
    }

    return TripBasicInfo(
      id: trip.id,
      title: title ?? 'Trip #${trip.id}',
      startTime: startTime != null ? DateTime.parse(startTime) : trip.startTime,
      level: enrichedLevel,
    );
  }

  /// Fetch trip details from cache or API
  Future<Map<String, dynamic>> _fetchTripDetails(int tripId) async {
    // Check cache first
    if (_tripCache.containsKey(tripId)) {
      return _tripCache[tripId]!;
    }

    // Fetch from API
    try {
      final details = await _repository.getTripDetail(tripId);
      _tripCache[tripId] = details;
      print('   ✅ Trip $tripId → "${details['title']}"');
      return details;
    } catch (e) {
      print('   ⚠️ Failed to fetch trip $tripId: $e');
      // Return minimal fallback
      return {
        'id': tripId,
        'title': 'Trip #$tripId',
        'startTime': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Batch fetch multiple trips
  Future<void> _batchFetchTrips(Set<int> tripIds) async {
    final missingIds = tripIds.where((id) => !_tripCache.containsKey(id));
    if (missingIds.isEmpty) {
      print('✅ All trips cached (${_tripCache.length} total)');
      return;
    }

    print('🔍 Fetching ${missingIds.length} trip details...');
    for (final tripId in missingIds) {
      await _fetchTripDetails(tripId);
    }
    print('✅ Trip cache built: ${_tripCache.length} trips');
  }

  // ============================================================================
  // SKILL ENRICHMENT
  // ============================================================================

  /// Enrich skills with actual names
  Future<List<LogbookSkillBasicInfo>> _enrichSkills(
    List<LogbookSkillBasicInfo> skills,
  ) async {
    if (skills.isEmpty) return [];

    // Ensure skills are pre-fetched
    await _prefetchSkills();

    final enrichedSkills = <LogbookSkillBasicInfo>[];
    for (final skill in skills) {
      // Check if this is a placeholder (name starts with 'Skill #')
      final isPlaceholder = skill.name.startsWith('Skill #');

      if (!isPlaceholder) {
        // Already enriched
        enrichedSkills.add(skill);
        continue;
      }

      // Get from cache
      final skillDetails = _skillCache[skill.id];
      if (skillDetails != null) {
        // Parse level from skillDetails if available
        LevelBasicInfo levelInfo = skill.level;
        final levelReq = skillDetails['levelRequirement'];
        
        // Handle levelRequirement - could be int (ID) or Map (full object)
        if (levelReq is Map<String, dynamic>) {
          try {
            levelInfo = LevelBasicInfo.fromJson(levelReq);
            print('   → Parsed level from Map for skill ${skill.id}');
          } catch (e) {
            print('   ⚠️ Failed to parse level Map for skill ${skill.id}: $e');
          }
        } else if (levelReq is int) {
          // Level is just an ID - keep original skill level
          print('   → Level is ID ($levelReq), keeping original level for skill ${skill.id}');
        }
        
        enrichedSkills.add(LogbookSkillBasicInfo(
          id: skill.id,
          name: skillDetails['name'] as String? ?? 'Skill #${skill.id}',
          description: skillDetails['description'] as String? ?? '',
          level: levelInfo,
        ));
      } else {
        // Fallback to original
        enrichedSkills.add(skill);
      }
    }

    return enrichedSkills;
  }

  /// Pre-fetch all skills (small dataset)
  Future<void> _prefetchSkills() async {
    if (_skillCache.isNotEmpty) {
      print('✅ Skills already cached (${_skillCache.length} skills)');
      return;
    }

    print('🔍 Fetching all skills...');
    try {
      final response = await _repository.getLogbookSkills(pageSize: 100);
      final skillsResults = response['results'] as List;

      for (final skillJson in skillsResults) {
        final skill = skillJson as Map<String, dynamic>;
        final id = skill['id'] as int;
        _skillCache[id] = skill;
      }

      print('✅ Skill cache built: ${_skillCache.length} skills');
    } catch (e) {
      print('⚠️ Failed to fetch skills: $e');
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Get cache statistics
  Map<String, int> getCacheStats() {
    return {
      'members': _memberCache.length,
      'trips': _tripCache.length,
      'skills': _skillCache.length,
    };
  }

  /// Check if caches are warmed up
  bool get isCacheWarmed => _skillCache.isNotEmpty;
}

// ============================================================================
// RIVERPOD PROVIDER
// ============================================================================

/// Provider for LogbookEnrichmentService
final logbookEnrichmentServiceProvider = Provider<LogbookEnrichmentService>((ref) {
  final repository = ref.watch(mainApiRepositoryProvider);
  return LogbookEnrichmentService(repository);
});
