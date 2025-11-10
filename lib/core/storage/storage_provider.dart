import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'local_storage.dart';

/// Provider for local storage service
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('LocalStorage must be initialized in main()');
});

/// Provider for user data from local storage
final currentUserProvider = StateProvider<Map<String, dynamic>?>((ref) {
  return LocalStorage.getUser();
});

/// Provider for auth token
final authTokenProvider = StateProvider<String?>((ref) {
  return LocalStorage.getAuthToken();
});

/// Provider for cached trips
final cachedTripsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return LocalStorage.getTrips();
});

/// Provider for cached events
final cachedEventsProvider = StateProvider<List<Map<String, dynamic>>>((ref) {
  return LocalStorage.getEvents();
});

/// Provider for notifications setting
final notificationsEnabledProvider = StateProvider<bool>((ref) {
  return LocalStorage.getNotificationsEnabled();
});

/// Provider for theme setting
final themeProvider = StateProvider<String>((ref) {
  return LocalStorage.getTheme();
});

/// Provider for language setting
final languageProvider = StateProvider<String>((ref) {
  return LocalStorage.getLanguage();
});
