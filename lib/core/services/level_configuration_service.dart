import 'package:flutter/material.dart';
import 'dart:math';
import '../../data/models/user_model.dart';
import '../../data/models/logbook_model.dart';
import '../../data/repositories/main_api_repository.dart';
import '../network/api_client.dart';

/// Level Configuration Service
/// 
/// Centralized service for managing level-related UI configuration
/// - Fetches levels from API
/// - Filters to only levels with skills
/// - Provides colors, emojis, names, and status labels
/// - Automatically adapts to new levels added by admin
class LevelConfigurationService {
  final ApiClient _apiClient;
  final MainApiRepository _repository;
  
  // Cache for fetched levels (24 hour TTL)
  List<UserLevel>? _cachedLevels;
  DateTime? _cacheTimestamp;
  static const _cacheDuration = Duration(hours: 24);
  
  // Cache for skills (used for filtering)
  List<LogbookSkill>? _cachedSkills;
  
  LevelConfigurationService(this._apiClient, this._repository);
  
  /// Pre-warm cache by loading levels and skills
  /// ⚡ Call this early (e.g., in app startup or provider initialization)
  Future<void> prewarmCache() async {
    try {
      await getLevelsWithSkills(forceRefresh: false);
      print('✅ [LevelConfig] Cache prewarmed successfully');
    } catch (e) {
      print('⚠️ [LevelConfig] Cache prewarm failed: $e');
    }
  }
  
  /// Fetch all levels from API
  Future<List<UserLevel>> getLevels({bool forceRefresh = false}) async {
    // Return cached levels if still valid
    if (!forceRefresh && 
        _cachedLevels != null && 
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedLevels!;
    }
    
    try {
      final response = await _apiClient.get('/api/levels/');
      final data = response.data['results'] ?? response.data['data'] ?? response.data;
      
      final List<UserLevel> levels = [];
      if (data is List) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            levels.add(UserLevel.fromJson(item));
          }
        }
      }
      
      // Sort by numeric level (ascending)
      levels.sort((a, b) => a.numericLevel.compareTo(b.numericLevel));
      
      _cachedLevels = levels;
      _cacheTimestamp = DateTime.now();
      
      return levels;
    } catch (e) {
      print('❌ [LevelConfig] Error fetching levels: $e');
      // Return cached levels if available, even if expired
      return _cachedLevels ?? [];
    }
  }
  
  /// Fetch all skills (for filtering levels)
  Future<List<LogbookSkill>> _getAllSkills() async {
    if (_cachedSkills != null) return _cachedSkills!;
    
    try {
      final response = await _repository.getLogbookSkills(pageSize: 500);
      final data = response['results'] ?? response['data'] ?? response;
      
      final List<LogbookSkill> skills = [];
      if (data is List) {
        for (var item in data) {
          if (item is Map<String, dynamic>) {
            try {
              skills.add(LogbookSkill.fromJson(item));
            } catch (e) {
              print('⚠️ [LevelConfig] Error parsing skill: $e');
            }
          }
        }
      }
      
      _cachedSkills = skills;
      return skills;
    } catch (e) {
      print('❌ [LevelConfig] Error fetching skills: $e');
      return [];
    }
  }
  
  /// Get only levels that have skills assigned
  /// CRITICAL: Only show levels with at least 1 skill
  Future<List<UserLevel>> getLevelsWithSkills({bool forceRefresh = false}) async {
    final allLevels = await getLevels(forceRefresh: forceRefresh);
    final allSkills = await _getAllSkills();
    
    // Filter to only levels that have skills
    final levelsWithSkills = allLevels.where((level) {
      return allSkills.any((skill) => skill.level.id == level.id);
    }).toList();
    
    print('📊 [LevelConfig] Levels: ${allLevels.length} total, ${levelsWithSkills.length} with skills');
    
    return levelsWithSkills;
  }
  
  /// Get clean level name (strip numeric suffix, proper case)
  /// "Board member-800" → "Board Member"
  /// "Intermediate-100" → "Intermediate"
  /// "ANTI--10" → "Anti"
  String getCleanLevelName(String rawName) {
    // Remove numeric suffix (e.g., "-800", "-100", "--10")
    String cleaned = rawName.replaceAll(RegExp(r'-+\d+$'), '');
    
    // Proper case: capitalize first letter of each word
    final words = cleaned.split(' ');
    final properCase = words.map((word) {
      if (word.isEmpty) return word;
      if (word.toUpperCase() == word && word.length <= 4) {
        // Keep all-caps acronyms (e.g., "ANTI" → "ANTI")
        return word;
      }
      // Capitalize first letter, lowercase rest
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
    
    return properCase.trim();
  }
  
  /// Get level color matching brand tokens (brand_tokens.json)
  /// Position-based progression: Green → Gold → Orange → Red-Orange → Blue → Purple → Violet
  /// ⚡ Uses cache - ensure prewarmCache() was called
  Color getLevelColor(int levelId) {
    final levelsWithSkills = _cachedLevels?.where((level) {
      return _cachedSkills?.any((skill) => skill.level.id == level.id) ?? false;
    }).toList() ?? [];
    
    if (levelsWithSkills.isEmpty) return Colors.grey;
    
    // Find position of this level
    final index = levelsWithSkills.indexWhere((l) => l.id == levelId);
    if (index == -1) return Colors.grey;
    
    // Calculate position (0.0 to 1.0)
    final progress = levelsWithSkills.length > 1 
        ? index / (levelsWithSkills.length - 1) 
        : 0.0;
    
    // Brand token colors + extended palette for additional levels
    final colors = [
      const Color(0xFF38B26E), // Newbie: Green (brand token)
      const Color(0xFFE0B223), // Intermediate: Yellow-Gold (brand token)
      const Color(0xFFD9822B), // Advanced: Orange-Brown (brand token)
      const Color(0xFFDA5547), // Explorer: Red-Orange (brand token)
      const Color(0xFF4BA3C7), // Marshal: Blue-Cyan (brand token)
      const Color(0xFF7E57C2), // Expert: Purple (extended - harmonizes with blue)
      const Color(0xFF9C27B0), // Board Member: Violet-Purple (extended - final tier)
    ];
    
    // Map progress to color index
    final colorIndex = (progress * (colors.length - 1)).round();
    return colors[colorIndex.clamp(0, colors.length - 1)];
  }
  
  /// Get level color async (populates cache first)
  /// 🔄 For use in async contexts only  
  Future<Color> getLevelColorAsync(int levelId) async {
    // Ensure caches are populated
    final levelsWithSkills = await getLevelsWithSkills();
    
    if (levelsWithSkills.isEmpty) return Colors.grey;
    
    final index = levelsWithSkills.indexWhere((l) => l.id == levelId);
    if (index == -1) return Colors.grey;
    
    final progress = levelsWithSkills.length > 1 
        ? index / (levelsWithSkills.length - 1) 
        : 0.0;
    
    // Brand token colors + extended palette
    final colors = [
      const Color(0xFF38B26E), const Color(0xFFE0B223), const Color(0xFFD9822B),
      const Color(0xFFDA5547), const Color(0xFF4BA3C7), const Color(0xFF7E57C2),
      const Color(0xFF9C27B0),
    ];
    
    final colorIndex = (progress * (colors.length - 1)).round();
    return colors[colorIndex.clamp(0, colors.length - 1)];
  }
  
  /// Get level emoji using military star progression
  /// - Newbie: ⭐ (1 star)
  /// - Intermediate: ⭐⭐ (2 stars)
  /// - Advanced: ⭐⭐⭐ (3 stars)
  /// - Expert: ⭐⭐⭐⭐ (4 stars)
  /// - Explorer: ⭐⭐⭐⭐ (4 stars)
  /// - Marshal: ⭐⭐⭐⭐⭐ (5 stars)
  /// - Board Member: 🎖️ (badge)
  /// ⚡ Uses cache - ensure prewarmCache() was called
  String getLevelEmoji(int levelId) {
    final levelsWithSkills = _cachedLevels?.where((level) {
      return _cachedSkills?.any((skill) => skill.level.id == level.id) ?? false;
    }).toList() ?? [];
    
    if (levelsWithSkills.isEmpty) {
      print('⚠️ [getLevelEmoji] Cache empty! Level ID: $levelId');
      return '⚪';
    }
    
    // Find position of this level
    final index = levelsWithSkills.indexWhere((l) => l.id == levelId);
    if (index == -1) {
      print('⚠️ [getLevelEmoji] Level ID $levelId not found in levelsWithSkills');
      return '⚪';
    }
    
    // Get level name for special handling
    final level = levelsWithSkills[index];
    final cleanName = getCleanLevelName(level.name).toLowerCase();
    
    // 🔍 DEBUG: Log what we're matching against
    print('🔍 [getLevelEmoji] Level ID: $levelId, Raw: "${level.name}", Clean: "$cleanName", Index: $index');
    print('   🔍 Testing "board": ${cleanName.contains('board')}');
    print('   🔍 Testing "marshal": ${cleanName.contains('marshal')}');
    print('   🔍 Testing "expert": ${cleanName.contains('expert')}');
    print('   🔍 Testing "advanced": ${cleanName.contains('advanced')}');
    print('   🔍 Testing "intermediate": ${cleanName.contains('intermediate')}');
    print('   🔍 Testing "anit": ${cleanName.contains('anit')}');
    print('   🔍 Testing "newbie": ${cleanName.contains('newbie')}');
    
    // Special cases based on level name
    // ⭐ U+2B50 (White Medium Star) - Using Text widget styling to ensure proper rendering
    if (cleanName.contains('board')) {
      print('   ✅ Matched: Board Member → 🎖️');
      return '🎖️'; // Badge for Board Member
    } else if (cleanName.contains('marshal')) {
      print('   ✅ Matched: Marshal → ⭐⭐⭐⭐⭐');
      return '⭐⭐⭐⭐⭐'; // 5 stars for Marshal
    } else if (cleanName.contains('expert') || cleanName.contains('explorer')) {
      print('   ✅ Matched: Expert/Explorer → ⭐⭐⭐⭐');
      return '⭐⭐⭐⭐'; // 4 stars for Expert and Explorer
    } else if (cleanName.contains('advanced') || cleanName.contains('advance')) {
      print('   ✅ Matched: Advanced → ⭐⭐⭐');
      return '⭐⭐⭐'; // 3 stars for Advanced
    } else if (cleanName.contains('intermediate')) {
      print('   ✅ Matched: Intermediate → ⭐⭐');
      return '⭐⭐'; // 2 stars for Intermediate
    } else if (cleanName.contains('anit')) {
      print('   ✅ Matched: ANIT → ⭐');
      return '⭐'; // 1 star for ANIT (same as Newbie)
    } else if (cleanName.contains('newbie') || cleanName.contains('beginner')) {
      print('   ✅ Matched: Newbie/Beginner → ⭐');
      return '⭐'; // 1 star for Newbie/Beginner
    }
    
    // Default: position-based stars (1-5)
    final starCount = min(index + 1, 5);
    print('   ⚠️ No match! Falling back to position-based: $starCount stars (index $index)');
    print('   ⚠️ All levels with skills: ${levelsWithSkills.map((l) => "ID=${l.id} Name=${l.name}").join(", ")}');
    return '⭐' * starCount;
  }
  
  /// Get level emoji async (populates cache first)
  /// 🔄 For use in async contexts only
  Future<String> getLevelEmojiAsync(int levelId) async {
    // Ensure caches are populated
    final levelsWithSkills = await getLevelsWithSkills();
    
    if (levelsWithSkills.isEmpty) return '⚪';
    
    final index = levelsWithSkills.indexWhere((l) => l.id == levelId);
    if (index == -1) return '⚪';
    
    final level = levelsWithSkills[index];
    final cleanName = getCleanLevelName(level.name).toLowerCase();
    
    if (cleanName.contains('board')) {
      return '🎖️';
    } else if (cleanName.contains('marshal')) return '⭐⭐⭐⭐⭐';
    else if (cleanName.contains('expert') || cleanName.contains('explorer')) return '⭐⭐⭐⭐';
    else if (cleanName.contains('advanced') || cleanName.contains('advance')) return '⭐⭐⭐';
    else if (cleanName.contains('intermediate')) return '⭐⭐';
    else if (cleanName.contains('anit')) return '⭐'; // 1 star for ANIT (same as Newbie)
    else if (cleanName.contains('newbie') || cleanName.contains('beginner')) return '⭐';
    
    final starCount = min(index + 1, 5);
    return '⭐' * starCount;
  }
  
  /// Get level status label based on user's current level
  /// - Current level: "In Progress"
  /// - Completed levels: "Completed ✓"
  /// - Future levels: "Next Goal"
  String getLevelStatusLabel(int levelId, int currentLevelId) {
    final levelsWithSkills = _cachedLevels?.where((level) {
      return _cachedSkills?.any((skill) => skill.level.id == level.id) ?? false;
    }).toList() ?? [];
    
    if (levelsWithSkills.isEmpty) return '';
    
    // Find positions
    final levelIndex = levelsWithSkills.indexWhere((l) => l.id == levelId);
    final currentIndex = levelsWithSkills.indexWhere((l) => l.id == currentLevelId);
    
    if (levelIndex == -1 || currentIndex == -1) return '';
    
    if (levelId == currentLevelId) {
      return 'In Progress';
    } else if (levelIndex < currentIndex) {
      return 'Completed ✓';
    } else {
      return 'Next Goal';
    }
  }
  
  /// Get smart abbreviation for level name
  /// - Single word: First 3-4 letters ("Expert" → "Exp")
  /// - Two words: First letter of each ("Board Member" → "BM")
  /// - All caps: Keep as-is ("ANTI" → "ANTI")
  String getAbbreviation(String levelName) {
    final clean = getCleanLevelName(levelName);
    final words = clean.split(' ');
    
    if (words.length == 1) {
      // Single word: take first 3-4 letters
      final word = words[0];
      if (word.length <= 4) return word;
      return word.substring(0, min(4, word.length));
    } else if (words.length == 2) {
      // Two words: first letter of each
      return words.map((w) => w[0].toUpperCase()).join('');
    } else {
      // Three+ words: first letter of each (up to 3)
      return words.take(3).map((w) => w[0].toUpperCase()).join('');
    }
  }
  
  /// Check if a level has any skills assigned
  bool hasSkills(int levelId) {
    return _cachedSkills?.any((skill) => skill.level.id == levelId) ?? false;
  }
  
  /// Clear cache (useful for testing or manual refresh)
  void clearCache() {
    _cachedLevels = null;
    _cachedSkills = null;
    _cacheTimestamp = null;
    print('🔄 [LevelConfig] Cache cleared');
  }
  
  /// Get level by ID
  UserLevel? getLevelById(int levelId) {
    return _cachedLevels?.firstWhere(
      (level) => level.id == levelId,
      orElse: () => UserLevel(
        id: levelId,
        name: 'Unknown',
        numericLevel: 0,
      ),
    );
  }
}
