import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider_v2.dart';
import 'gallery_auth_provider.dart';

/// 🔄 Gallery Auto-Authentication
/// 
/// Automatically syncs main API token with Gallery API
/// When user logs in to main app, we attempt to use the same token for Gallery API
/// This eliminates the need for separate Gallery login in most cases

/// Provider that watches main auth and auto-authenticates Gallery API
final galleryAutoAuthProvider = Provider<void>((ref) {
  // Watch main auth state (triggers rebuild on auth changes)
  ref.watch(authProviderV2);
  final galleryAuthNotifier = ref.read(galleryAuthProvider.notifier);
  
  // When main auth changes
  ref.listen<AuthStateV2>(authProviderV2, (previous, next) async {
    print('🔄 [GalleryAutoAuth] Main auth state changed');
    
    // User logged into main API
    if (next.isAuthenticated && !next.isLoading) {
      print('🔄 [GalleryAutoAuth] User logged in, syncing Gallery API token...');
      
      // Get main API token
      final mainToken = await getAuthToken();
      if (mainToken != null) {
        // Try to use main token with Gallery API
        final success = await galleryAuthNotifier.useMainApiToken(mainToken);
        if (success) {
          print('✅ [GalleryAutoAuth] Gallery API auto-authenticated with main token');
        } else {
          print('ℹ️ [GalleryAutoAuth] Gallery API token validation failed');
          print('ℹ️ [GalleryAutoAuth] Read-only operations will still work (Gallery API allows anonymous reads)');
          print('💡 [GalleryAutoAuth] Write operations (upload, like) will require separate Gallery login');
        }
      }
    }
    
    // User logged out of main API
    if (!next.isAuthenticated && previous?.isAuthenticated == true) {
      print('🔄 [GalleryAutoAuth] User logged out, clearing Gallery API session...');
      await galleryAuthNotifier.logout();
      print('✅ [GalleryAutoAuth] Gallery API session cleared');
    }
  });
  
  return;
});
