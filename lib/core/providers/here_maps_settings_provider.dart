import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/here_maps_settings.dart';
import '../services/here_maps_service.dart';
import 'here_maps_service_provider.dart';

/// Here Maps Settings Provider
/// 
/// ✅ MIGRATED TO BACKEND-DRIVEN ARCHITECTURE
/// - Configuration loaded from Django Admin panel
/// - Auto-refresh every 15 minutes
/// - No client-side settings management
/// - Read-only from Flutter app perspective
/// 
/// BACKEND MANAGEMENT:
/// - Settings controlled via Django Admin only
/// - Flutter app displays current backend configuration
/// - Changes require Django Admin panel access
/// - No API key exposed to client
/// 
/// LIFECYCLE:
/// 1. Provider initializes → loads settings from backend
/// 2. Settings cached in memory for 15 minutes
/// 3. Auto-refresh timer fetches fresh configuration
/// 4. On app restart, settings reload from backend
/// 
/// USAGE:
/// ```dart
/// final settings = ref.watch(hereMapsSettingsProvider);
/// 
/// settings.when(
///   data: (config) {
///     if (config.enabled) {
///       // Use HERE Maps geocoding
///     }
///   },
///   loading: () => CircularProgressIndicator(),
///   error: (err, stack) => Text('Failed to load config'),
/// );
/// ```
class HereMapsSettingsNotifier extends StateNotifier<AsyncValue<HereMapsSettings>> {
  final HereMapsService _hereMapsService;
  Timer? _refreshTimer;
  
  // Auto-refresh interval (matches backend cache duration)
  static const _refreshInterval = Duration(minutes: 15);

  HereMapsSettingsNotifier(this._hereMapsService) : super(const AsyncValue.loading()) {
    // Load settings immediately on initialization
    _loadSettings();
  }

  /// Load settings from backend
  /// 
  /// Called automatically:
  /// - On provider initialization
  /// - Every 15 minutes (auto-refresh)
  /// - When manually refreshed via refreshSettings()
  Future<void> _loadSettings() async {
    try {
      state = const AsyncValue.loading();
      
      // Fetch configuration from backend
      final settings = await _hereMapsService.loadConfiguration();
      
      state = AsyncValue.data(settings);
      
      // Start auto-refresh timer
      _startAutoRefresh();
      
    } catch (e, stack) {
      // On error, use default settings as fallback
      state = AsyncValue.error(e, stack);
      
      // Still start auto-refresh to retry later
      _startAutoRefresh();
    }
  }

  /// Start periodic auto-refresh timer
  /// 
  /// Ensures configuration stays synchronized with backend changes.
  /// Backend administrators can update settings via Django Admin,
  /// and Flutter app will pick up changes within 15 minutes.
  void _startAutoRefresh() {
    // Cancel existing timer if any
    _refreshTimer?.cancel();
    
    // Schedule periodic refresh
    _refreshTimer = Timer.periodic(_refreshInterval, (_) {
      _loadSettings();
    });
  }

  /// Manually refresh settings from backend
  /// 
  /// Useful when:
  /// - User pulls to refresh
  /// - Testing configuration changes
  /// - Need immediate update after backend changes
  /// 
  /// Example:
  /// ```dart
  /// await ref.read(hereMapsSettingsProvider.notifier).refreshSettings();
  /// ```
  Future<void> refreshSettings() async {
    await _loadSettings();
  }

  /// Check if HERE Maps is currently enabled
  /// 
  /// Convenience method to check global enable/disable status
  /// without needing to unwrap AsyncValue.
  /// 
  /// Returns:
  /// - true if settings loaded and enabled=true
  /// - false if loading, error, or disabled
  bool isEnabled() {
    return state.when(
      data: (settings) => settings.enabled,
      loading: () => false,
      error: (_, __) => false,
    );
  }

  /// Get current settings or default
  /// 
  /// Convenience method to safely get settings.
  /// Returns default settings if still loading or error occurred.
  HereMapsSettings getSettingsOrDefault() {
    return state.when(
      data: (settings) => settings,
      loading: () => HereMapsSettings.defaultSettings(),
      error: (_, __) => HereMapsSettings.defaultSettings(),
    );
  }

  @override
  void dispose() {
    // Clean up timer when provider disposed
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider for HERE Maps settings
/// 
/// Auto-loads configuration from backend and refreshes every 15 minutes.
/// 
/// Example usage:
/// ```dart
/// // Watch for changes
/// final settingsAsync = ref.watch(hereMapsSettingsProvider);
/// 
/// settingsAsync.when(
///   data: (settings) => Text('Enabled: ${settings.enabled}'),
///   loading: () => CircularProgressIndicator(),
///   error: (e, _) => Text('Error: $e'),
/// );
/// 
/// // Get current value or default
/// final settings = ref.read(hereMapsSettingsProvider.notifier).getSettingsOrDefault();
/// 
/// // Manually refresh
/// await ref.read(hereMapsSettingsProvider.notifier).refreshSettings();
/// ```
final hereMapsSettingsProvider =
    StateNotifierProvider<HereMapsSettingsNotifier, AsyncValue<HereMapsSettings>>((ref) {
  final hereMapsService = ref.watch(hereMapsServiceProvider);
  return HereMapsSettingsNotifier(hereMapsService);
});
