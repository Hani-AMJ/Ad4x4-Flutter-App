import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/level_configuration_service.dart';
import 'repository_providers.dart';

/// Provider for LevelConfigurationService
/// 
/// Usage:
/// ```dart
/// final levelConfig = ref.watch(levelConfigurationProvider);
/// final cleanName = levelConfig.getCleanLevelName(level.name);
/// final color = levelConfig.getLevelColor(level.id);
/// ```
final levelConfigurationProvider = Provider<LevelConfigurationService>((ref) {
  final apiClient = ref.watch(mainApiClientProvider);
  final repository = ref.watch(mainApiRepositoryProvider);
  return LevelConfigurationService(apiClient, repository);
});
