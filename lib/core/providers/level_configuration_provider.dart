import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/level_configuration_service.dart';
import 'repository_providers.dart';

/// Provider for LevelConfigurationService (Sync - for immediate access)
/// 
/// ⚠️ NOTE: Cache may not be populated immediately. Use levelConfigurationReadyProvider
/// to ensure cache is ready before accessing colors/emojis.
final levelConfigurationProvider = Provider<LevelConfigurationService>((ref) {
  final apiClient = ref.watch(mainApiClientProvider);
  final repository = ref.watch(mainApiRepositoryProvider);
  final service = LevelConfigurationService(apiClient, repository);
  
  // Fire-and-forget prewarm (for backward compatibility)
  service.prewarmCache();
  
  return service;
});

/// FutureProvider that waits for cache to be ready
/// 
/// ✅ RECOMMENDED: Use this provider to ensure cache is populated
/// 
/// Usage:
/// ```dart
/// final levelConfigAsync = ref.watch(levelConfigurationReadyProvider);
/// levelConfigAsync.when(
///   data: (levelConfig) {
///     final color = levelConfig.getLevelColor(levelId);  // Cache is ready!
///     final emoji = levelConfig.getLevelEmoji(levelId);  // Cache is ready!
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (e, s) => ErrorWidget(e),
/// );
/// ```
final levelConfigurationReadyProvider = FutureProvider<LevelConfigurationService>((ref) async {
  final apiClient = ref.watch(mainApiClientProvider);
  final repository = ref.watch(mainApiRepositoryProvider);
  final service = LevelConfigurationService(apiClient, repository);
  
  // ✅ CRITICAL: Wait for cache to be populated before returning service
  await service.prewarmCache();
  
  return service;
});
