import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'core/config/brand_tokens.dart';
import 'core/storage/local_storage.dart';
import 'dart:developer' as developer;

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive local storage
  try {
    await LocalStorage.init();
    developer.log('✅ Local storage initialized', name: 'Main');
  } catch (e) {
    developer.log('❌ Local storage initialization failed: $e', name: 'Main');
  }
  
  // AuthProviderV2 handles authentication initialization automatically
  // when the provider is first accessed by the router.
  
  // Load brand tokens from assets
  final brandTokens = await BrandTokens.load();
  
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
      child: AD4x4App(brandTokens: brandTokens),
    ),
  );
}
