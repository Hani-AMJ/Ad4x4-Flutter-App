import 'package:hive_flutter/hive_flutter.dart';
import 'dart:developer' as developer;

/// Local storage service using Hive
class LocalStorage {
  static const String _userBox = 'user_box';
  static const String _tripsBox = 'trips_box';
  static const String _eventsBox = 'events_box';
  static const String _settingsBox = 'settings_box';
  static const String _cacheBox = 'cache_box';

  static Box<dynamic>? _user;
  static Box<dynamic>? _trips;
  static Box<dynamic>? _events;
  static Box<dynamic>? _settings;
  static Box<dynamic>? _cache;

  /// Initialize Hive and open all boxes
  static Future<void> init() async {
    try {
      await Hive.initFlutter();
      
      // Open all boxes
      _user = await Hive.openBox(_userBox);
      _trips = await Hive.openBox(_tripsBox);
      _events = await Hive.openBox(_eventsBox);
      _settings = await Hive.openBox(_settingsBox);
      _cache = await Hive.openBox(_cacheBox);

      developer.log('✅ Hive initialized successfully', name: 'LocalStorage');
    } catch (e) {
      developer.log('❌ Hive initialization failed: $e', name: 'LocalStorage');
      rethrow;
    }
  }

  // User Data Methods
  static Future<void> saveUser(Map<String, dynamic> userData) async {
    await _user?.put('current_user', userData);
  }

  static Map<String, dynamic>? getUser() {
    final data = _user?.get('current_user');
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  static Future<void> clearUser() async {
    await _user?.delete('current_user');
  }

  // Auth Token Methods
  static Future<void> saveAuthToken(String token) async {
    await _user?.put('auth_token', token);
  }

  static String? getAuthToken() {
    return _user?.get('auth_token') as String?;
  }

  static Future<void> saveRefreshToken(String token) async {
    await _user?.put('refresh_token', token);
  }

  static String? getRefreshToken() {
    return _user?.get('refresh_token') as String?;
  }

  static Future<void> clearAuthTokens() async {
    await _user?.delete('auth_token');
    await _user?.delete('refresh_token');
  }

  // Trips Methods
  static Future<void> saveTrips(List<Map<String, dynamic>> trips) async {
    await _trips?.put('all_trips', trips);
    await _cache?.put('trips_last_updated', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getTrips() {
    final data = _trips?.get('all_trips');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  static Future<void> saveTrip(String id, Map<String, dynamic> trip) async {
    await _trips?.put(id, trip);
  }

  static Map<String, dynamic>? getTrip(String id) {
    final data = _trips?.get(id);
    return data != null ? Map<String, dynamic>.from(data) : null;
  }

  // Events Methods
  static Future<void> saveEvents(List<Map<String, dynamic>> events) async {
    await _events?.put('all_events', events);
    await _cache?.put('events_last_updated', DateTime.now().toIso8601String());
  }

  static List<Map<String, dynamic>> getEvents() {
    final data = _events?.get('all_events');
    if (data == null) return [];
    return List<Map<String, dynamic>>.from(data);
  }

  // Settings Methods
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settings?.put(key, value);
  }

  static dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settings?.get(key, defaultValue: defaultValue);
  }

  static bool getNotificationsEnabled() {
    return _settings?.get('notifications_enabled', defaultValue: true) as bool;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    await _settings?.put('notifications_enabled', value);
  }

  static String getTheme() {
    return _settings?.get('theme', defaultValue: 'dark') as String;
  }

  static Future<void> setTheme(String theme) async {
    await _settings?.put('theme', theme);
  }

  static String getLanguage() {
    return _settings?.get('language', defaultValue: 'en') as String;
  }

  static Future<void> setLanguage(String language) async {
    await _settings?.put('language', language);
  }

  // Cache Methods
  static Future<void> cacheData(String key, dynamic data) async {
    await _cache?.put(key, data);
    await _cache?.put('${key}_timestamp', DateTime.now().toIso8601String());
  }

  static dynamic getCachedData(String key) {
    return _cache?.get(key);
  }

  static bool isCacheValid(String key, {Duration maxAge = const Duration(hours: 1)}) {
    final timestamp = _cache?.get('${key}_timestamp') as String?;
    if (timestamp == null) return false;

    final cachedTime = DateTime.parse(timestamp);
    final now = DateTime.now();
    return now.difference(cachedTime) < maxAge;
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _user?.clear();
    await _trips?.clear();
    await _events?.clear();
    await _cache?.clear();
    // Keep settings
  }

  // Clear cache only
  static Future<void> clearCache() async {
    await _cache?.clear();
  }

  // Close all boxes (call on app dispose)
  static Future<void> dispose() async {
    await _user?.close();
    await _trips?.close();
    await _events?.close();
    await _settings?.close();
    await _cache?.close();
  }
}
