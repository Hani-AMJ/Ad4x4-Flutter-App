import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/brand_tokens.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';
import 'features/trips/presentation/providers/trips_provider.dart';

/// Root application widget
/// 
/// ✅ PHASE 3: Enhanced with app lifecycle monitoring for smart data refresh
class AD4x4App extends ConsumerStatefulWidget {
  final BrandTokens brandTokens;

  const AD4x4App({
    super.key,
    required this.brandTokens,
  });

  @override
  ConsumerState<AD4x4App> createState() => _AD4x4AppState();
}

class _AD4x4AppState extends ConsumerState<AD4x4App> 
    with WidgetsBindingObserver {
  
  @override
  void initState() {
    super.initState();
    // ✅ Register app lifecycle observer
    WidgetsBinding.instance.addObserver(this);
    
    if (kDebugMode) {
      print('🔄 [AppLifecycle] Observer registered');
    }
  }
  
  @override
  void dispose() {
    // ✅ Unregister app lifecycle observer
    WidgetsBinding.instance.removeObserver(this);
    
    if (kDebugMode) {
      print('🔄 [AppLifecycle] Observer unregistered');
    }
    
    super.dispose();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (kDebugMode) {
      print('🔄 [AppLifecycle] State changed: $state');
    }
    
    // ✅ PHASE 3: Refresh data when app resumes from background
    if (state == AppLifecycleState.resumed) {
      _handleAppResumed();
    }
  }
  
  /// Handle app resume - smart refresh if data is stale
  /// 
  /// ✅ PHASE 3: Only refresh if data is older than 5 minutes
  void _handleAppResumed() {
    if (kDebugMode) {
      print('🔄 [AppLifecycle] App resumed from background');
    }
    
    try {
      final tripsState = ref.read(tripsProvider);
      
      // Check if data is stale (> 5 minutes old)
      if (tripsState.isStale) {
        if (kDebugMode) {
          print('🔄 [AppLifecycle] Data is stale - refreshing trips');
          if (tripsState.lastRefreshTime != null) {
            final age = DateTime.now().difference(tripsState.lastRefreshTime!);
            print('   Data age: ${age.inMinutes} minutes');
          }
        }
        
        // Trigger refresh
        ref.read(tripsProvider.notifier).refresh();
      } else {
        if (kDebugMode) {
          print('✅ [AppLifecycle] Data is fresh - no refresh needed');
          if (tripsState.lastRefreshTime != null) {
            final age = DateTime.now().difference(tripsState.lastRefreshTime!);
            print('   Data age: ${age.inMinutes} minutes');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AppLifecycle] Error during resume refresh: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'AD4x4 Mobile',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.light(widget.brandTokens.light),
      darkTheme: AppTheme.dark(widget.brandTokens.dark),
      themeMode: ThemeMode.dark, // Dark mode first (brand identity)
      
      // Router Configuration
      routerConfig: router,
    );
  }
}
