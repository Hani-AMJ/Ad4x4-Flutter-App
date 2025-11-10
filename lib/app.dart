import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/config/brand_tokens.dart';
import 'core/router/app_router.dart';
import 'shared/theme/app_theme.dart';

/// Root application widget
class AD4x4App extends ConsumerWidget {
  final BrandTokens brandTokens;

  const AD4x4App({
    super.key,
    required this.brandTokens,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'AD4x4 Mobile',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.light(brandTokens.light),
      darkTheme: AppTheme.dark(brandTokens.dark),
      themeMode: ThemeMode.dark, // Dark mode first (brand identity)
      
      // Router Configuration
      routerConfig: router,
    );
  }
}
