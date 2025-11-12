import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/level_model.dart';

/// Levels Provider - Fetches and caches trip difficulty levels
final levelsProvider = FutureProvider<List<Level>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getLevels();
    
    // Parse levels from API response
    final levels = <Level>[];
    for (var levelJson in response) {
      try {
        final level = Level.fromJson(levelJson as Map<String, dynamic>);
        // Only include active levels
        if (level.active) {
          levels.add(level);
        }
      } catch (e) {
        print('⚠️ Error parsing level: $e');
      }
    }
    
    // Sort by numeric level
    levels.sort((a, b) => a.numericLevel.compareTo(b.numericLevel));
    
    return levels;
  } catch (e) {
    print('❌ Error loading levels: $e');
    rethrow;
  }
});
