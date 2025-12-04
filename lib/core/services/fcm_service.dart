import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Top-level function for background message handling
/// 
/// This MUST be a top-level function (not a class method) for Firebase to call it
/// when the app is in the background or terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    debugPrint('🔔 [FCM Background] Message: ${message.messageId}');
    debugPrint('   Title: ${message.notification?.title}');
    debugPrint('   Body: ${message.notification?.body}');
    debugPrint('   Data: ${message.data}');
  }
}

/// FCM Service for Push Notifications
/// 
/// Handles Firebase Cloud Messaging for push notifications:
/// - Requesting notification permissions
/// - Getting and registering FCM tokens
/// - Handling foreground, background, and terminated notifications
/// - Managing notification taps
/// 
/// **SETUP REQUIREMENTS**:
/// 1. Firebase Core must be initialized
/// 2. Firebase Messaging must be enabled in pubspec.yaml
/// 3. Platform-specific setup:
///    - **Android**: Nothing else needed (google-services.json handles it)
///    - **iOS**: 
///      - Add Push Notification capability in Xcode
///      - Add Background Modes -> Remote notifications
///      - Request APNS certificate from Apple
///      - Upload APNS key to Firebase Console
/// 
/// **USAGE**:
/// ```dart
/// // In main.dart, before runApp():
/// await FCMService.initialize(
///   onMessageTap: (RemoteMessage message) {
///     // Handle notification tap - navigate to relevant screen
///     final tripId = message.data['tripId'];
///     if (tripId != null) {
///       navigatorKey.currentState?.pushNamed('/trips/$tripId');
///     }
///   },
/// );
/// 
/// // Get FCM token to register with backend:
/// final token = await FCMService().getToken();
/// if (token != null) {
///   await apiRepository.registerFCMDevice(token: token, deviceType: 'android');
/// }
/// ```
class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Singleton pattern
  static final FCMService _instance = FCMService._internal();
  factory FCMService() => _instance;
  FCMService._internal();
  
  // Notification tap callback
  static void Function(RemoteMessage)? _onMessageTap;
  
  /// Initialize FCM Service
  /// 
  /// **MUST be called in main.dart before runApp():**
  /// ```dart
  /// await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  /// await FCMService.initialize(
  ///   onMessageTap: (message) {
  ///     // Handle notification tap
  ///   },
  /// );
  /// ```
  static Future<void> initialize({
    void Function(RemoteMessage)? onMessageTap,
  }) async {
    _onMessageTap = onMessageTap;
    
    // Set up background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    
    // Initialize local notifications for Android
    if (Platform.isAndroid) {
      await _instance._initializeLocalNotifications();
    }
    
    // Request permissions
    await _instance.requestPermission();
    
    // Set up foreground notification presentation options
    await _instance._setupForegroundNotifications();
    
    // Set up message handlers
    await _instance._setupMessageHandlers();
    
    if (kDebugMode) {
      debugPrint('✅ [FCM] Service initialized');
    }
  }
  
  /// Initialize local notifications (for Android)
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap from local notification
        if (details.payload != null && _onMessageTap != null) {
          // Parse payload and create RemoteMessage
          // For now, we'll log it
          if (kDebugMode) {
            debugPrint('🔔 [FCM] Local notification tapped: ${details.payload}');
          }
        }
      },
    );
    
    // Create notification channel for Android
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'ad4x4_default_channel', // id
        'AD4x4 Notifications', // name
        description: 'Default notification channel for AD4x4 app',
        importance: Importance.high,
        playSound: true,
      );
      
      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }
  
  /// Request notification permissions
  /// 
  /// **Returns**: NotificationSettings with permission status
  Future<NotificationSettings> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );
      
      if (kDebugMode) {
        debugPrint('📱 [FCM] Permission status: ${settings.authorizationStatus}');
      }
      
      return settings;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FCM] Error requesting permissions: $e');
      }
      rethrow;
    }
  }
  
  /// Get FCM token
  /// 
  /// This token must be sent to your backend and registered at:
  /// POST /api/device/fcm/
  /// 
  /// **Returns**: FCM token string or null if unavailable
  Future<String?> getToken() async {
    try {
      final token = await _messaging.getToken();
      
      if (kDebugMode) {
        if (token != null) {
          debugPrint('✅ [FCM] Token: ${token.substring(0, 20)}...');
        } else {
          debugPrint('⚠️ [FCM] Token is null');
        }
      }
      
      return token;
      
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FCM] Error getting token: $e');
      }
      return null;
    }
  }
  
  /// Listen for token refresh
  /// 
  /// FCM tokens can change. Use this stream to detect changes and update your backend:
  /// ```dart
  /// FCMService().onTokenRefresh.listen((newToken) async {
  ///   await apiRepository.updateFCMToken(newToken);
  /// });
  /// ```
  Stream<String> get onTokenRefresh => _messaging.onTokenRefresh;
  
  /// Setup foreground notification presentation
  Future<void> _setupForegroundNotifications() async {
    // For iOS: Set foreground notification presentation options
    if (Platform.isIOS) {
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
    }
  }
  
  /// Setup message handlers
  Future<void> _setupMessageHandlers() async {
    // Foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('🔔 [FCM Foreground] Message: ${message.messageId}');
        debugPrint('   Title: ${message.notification?.title}');
        debugPrint('   Body: ${message.notification?.body}');
        debugPrint('   Data: ${message.data}');
      }
      
      // Show local notification for Android when app is in foreground
      if (Platform.isAndroid) {
        _showLocalNotification(message);
      }
    });
    
    // Background notification tap (app was in background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        debugPrint('🔔 [FCM] Notification tapped (background): ${message.messageId}');
      }
      
      if (_onMessageTap != null) {
        _onMessageTap!(message);
      }
    });
    
    // Check if app was opened from terminated state via notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      if (kDebugMode) {
        debugPrint('🔔 [FCM] App opened from terminated state: ${initialMessage.messageId}');
      }
      
      if (_onMessageTap != null) {
        _onMessageTap!(initialMessage);
      }
    }
  }
  
  /// Show local notification (for Android foreground)
  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;
    
    const androidDetails = AndroidNotificationDetails(
      'ad4x4_default_channel',
      'AD4x4 Notifications',
      channelDescription: 'Default notification channel for AD4x4 app',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
      payload: message.data.toString(),
    );
  }
  
  /// Subscribe to a topic
  /// 
  /// **Topics** allow broadcasting messages to multiple devices.
  /// Example topics: 'all_users', 'trip_updates', 'level_300_plus'
  /// 
  /// ```dart
  /// await FCMService().subscribeToTopic('trip_updates');
  /// ```
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
      if (kDebugMode) {
        debugPrint('✅ [FCM] Subscribed to topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FCM] Error subscribing to topic: $e');
      }
    }
  }
  
  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
      if (kDebugMode) {
        debugPrint('✅ [FCM] Unsubscribed from topic: $topic');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FCM] Error unsubscribing from topic: $e');
      }
    }
  }
  
  /// Delete FCM token
  /// 
  /// Call this when user logs out to prevent receiving notifications
  Future<void> deleteToken() async {
    try {
      await _messaging.deleteToken();
      if (kDebugMode) {
        debugPrint('✅ [FCM] Token deleted');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ [FCM] Error deleting token: $e');
      }
    }
  }
  
  /// Check notification permission status
  Future<bool> isPermissionGranted() async {
    final settings = await _messaging.getNotificationSettings();
    return settings.authorizationStatus == AuthorizationStatus.authorized ||
           settings.authorizationStatus == AuthorizationStatus.provisional;
  }
}
