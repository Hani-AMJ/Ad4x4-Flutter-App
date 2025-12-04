import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'dart:ui';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';
import 'core/config/brand_tokens.dart';
import 'core/config/api_config.dart';
import 'core/storage/local_storage.dart';
import 'core/services/gallery_config_service.dart';
import 'core/services/error_log_service.dart';
import 'data/models/gallery_config_model.dart';
import 'dart:developer' as developer;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  if (kDebugMode) {
    developer.log('🔥 Firebase initialized successfully', name: 'Firebase');
  }
  
  // ✅ Initialize Error Logging Service
  final errorLogService = ErrorLogService();
  await errorLogService.init();
  
  // ✅ Set up global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to our service
    errorLogService.logError(
      message: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      type: 'flutter_error',
      context: details.context?.toString(),
    );
    
    // Also log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  
  // ✅ Catch errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogService.logError(
      message: error.toString(),
      stackTrace: stack.toString(),
      type: 'exception',
    );
    return true; // Handled
  };
  
  // Initialize Hive local storage
  try {
    await LocalStorage.init();
    developer.log('✅ Local storage initialized', name: 'Main');
  } catch (e) {
    developer.log('❌ Local storage initialization failed: $e', name: 'Main');
    // Also log to error service
    errorLogService.logError(
      message: 'Local storage initialization failed: $e',
      type: 'exception',
      context: 'Main initialization',
    );
  }
  
  // AuthProviderV2 handles authentication initialization automatically
  // when the provider is first accessed by the router.
  
  // Load brand tokens from assets
  final brandTokens = await BrandTokens.load();
  
  // Load gallery configuration from backend
  // Falls back to defaults if backend not ready (graceful degradation)
  GalleryConfigModel galleryConfig;
  try {
    galleryConfig = await GalleryConfigService.loadConfiguration();
    ApiConfig.updateGalleryApiUrl(galleryConfig.apiUrl);
    developer.log('✅ Gallery configuration loaded successfully', name: 'Main');
  } catch (e) {
    galleryConfig = GalleryConfigModel.defaultConfig();
    developer.log('⚠️ Using default gallery config: $e', name: 'Main');
  }
  
  // Set system UI overlay style (status bar + navigation bar)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF1B1B1B), // Charcoal background
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  
  // Run app with Riverpod
  runApp(
    ProviderScope(
      overrides: [
        // Provide gallery configuration globally
        galleryConfigProvider.overrideWithValue(galleryConfig),
      ],
      child: AD4x4App(brandTokens: brandTokens),
    ),
  );
}
