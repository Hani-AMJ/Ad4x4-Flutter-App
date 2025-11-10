import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Providers
import '../providers/auth_provider_v2.dart'; // NEW - Clean Riverpod auth

// Models
import '../../data/models/event_model.dart';

// Screens (to be created)
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/trips/presentation/screens/trips_list_screen.dart';
import '../../features/trips/presentation/screens/trip_details_screen.dart';
import '../../features/trips/presentation/screens/create_trip_screen.dart';
import '../../features/trips/presentation/screens/trip_chat_screen.dart';
import '../../features/trips/presentation/screens/trip_requests_screen.dart';
import '../../features/trips/presentation/screens/manage_registrants_screen.dart';
import '../../features/events/presentation/screens/events_list_screen.dart';
import '../../features/events/presentation/screens/event_details_screen.dart';
import '../../features/gallery/presentation/screens/gallery_screen.dart';
import '../../features/gallery/presentation/screens/album_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/members/presentation/screens/members_list_screen.dart';
import '../../features/members/presentation/screens/member_details_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_list_screen.dart';
import '../../features/vehicles/presentation/screens/add_vehicle_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/debug/auth_debug_screen.dart';

import 'dart:developer' as developer;

/// 🔄 V2: Clean Riverpod-based Router with Simplified Auth Guards
final goRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes (V2 - Clean implementation)
  final authStateNotifier = _AuthStateNotifierV2(ref);
  
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = authStateNotifier.currentAuthState;
      final isAuthenticated = authState?.isAuthenticated ?? false;
      final isLoading = authState?.isLoading ?? false;
      final currentLocation = state.matchedLocation;
      
      // Check if current page is auth page or debug page
      final isAuthPage = currentLocation == '/login' || 
                        currentLocation == '/register' ||
                        currentLocation == '/forgot-password';
      
      // Debug pages are always accessible (no auth required)
      final isDebugPage = currentLocation.startsWith('/debug');
      
      print('🔀 [Router] $currentLocation | Auth: $isAuthenticated | Loading: $isLoading');
      
      // Wait for auth to finish loading
      if (isLoading) {
        print('⏳ [Router] Loading auth state...');
        return null;
      }
      
      // Allow access to debug pages without authentication
      if (isDebugPage) {
        print('🔧 [Router] Debug page - allowing access');
        return null;
      }
      
      // Simple redirect logic
      if (isAuthenticated && isAuthPage) {
        print('↪️ [Router] Authenticated, redirect to home');
        return '/';
      }
      
      if (!isAuthenticated && !isAuthPage) {
        print('↪️ [Router] Not authenticated, redirect to login');
        return '/login';
      }
      
      return null;
    },
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),

      // Main App Routes (Protected)
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),

      // Trip Routes
      GoRoute(
        path: '/trips',
        name: 'trips',
        builder: (context, state) => const TripsListScreen(),
      ),
      GoRoute(
        path: '/trips/create',
        name: 'create-trip',
        builder: (context, state) => const CreateTripScreen(),
      ),
      GoRoute(
        path: '/trips/:id',
        name: 'trip-details',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return TripDetailsScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/edit',
        name: 'edit-trip',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          return CreateTripScreen(tripId: tripId);
        },
      ),
      GoRoute(
        path: '/trips/:id/registrants',
        name: 'manage-registrants',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          final tripTitle = state.uri.queryParameters['title'] ?? 'Trip';
          return ManageRegistrantsScreen(tripId: tripId, tripTitle: tripTitle);
        },
      ),
      GoRoute(
        path: '/trips/:id/chat',
        name: 'trip-chat',
        builder: (context, state) {
          final tripId = state.pathParameters['id']!;
          final tripTitle = state.uri.queryParameters['title'] ?? 'Trip Chat';
          return TripChatScreen(tripId: tripId, tripTitle: tripTitle);
        },
      ),
      GoRoute(
        path: '/trip-requests',
        name: 'trip-requests',
        builder: (context, state) => const TripRequestsScreen(),
      ),

      // Event Routes
      GoRoute(
        path: '/events',
        name: 'events',
        builder: (context, state) => const EventsListScreen(),
      ),
      GoRoute(
        path: '/events/:id',
        name: 'event-details',
        builder: (context, state) {
          final event = state.extra as EventModel?;
          // TODO: If event is null, fetch from API using eventId
          return EventDetailsScreen(event: event!);
        },
      ),

      // Gallery Routes
      GoRoute(
        path: '/gallery',
        name: 'gallery',
        builder: (context, state) => const GalleryScreen(),
      ),
      GoRoute(
        path: '/gallery/album/:albumId',
        name: 'album',
        builder: (context, state) {
          final albumId = state.pathParameters['albumId']!;
          return AlbumScreen(albumId: albumId);
        },
      ),

      // Member Routes
      GoRoute(
        path: '/members',
        name: 'members',
        builder: (context, state) => const MembersListScreen(),
      ),
      GoRoute(
        path: '/members/:id',
        name: 'member-details',
        builder: (context, state) {
          final memberId = state.pathParameters['id']!;
          return MemberDetailsScreen(memberId: memberId);
        },
      ),

      // Profile Routes
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/profile/edit',
        name: 'edit-profile',
        builder: (context, state) => const EditProfileScreen(),
      ),

      // Vehicle Routes
      GoRoute(
        path: '/vehicles',
        name: 'vehicles',
        builder: (context, state) => const VehiclesListScreen(),
      ),
      GoRoute(
        path: '/vehicles/add',
        name: 'add-vehicle',
        builder: (context, state) => const AddVehicleScreen(),
      ),

      // Settings Routes
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Debug Routes (for development)
      GoRoute(
        path: '/debug/auth',
        name: 'auth-debug',
        builder: (context, state) => const AuthDebugScreen(),
      ),

      // Notifications
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),

      // Search Route
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const GlobalSearchScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(state.uri.toString()),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

/// Auth state change notifier for GoRouter refresh (V2 - Clean implementation)
class _AuthStateNotifierV2 extends ChangeNotifier {
  _AuthStateNotifierV2(this._ref) {
    // Get initial auth state from V2 provider
    currentAuthState = _ref.read(authProviderV2);
    print('🔧 [RouterNotifier] Created with auth state: ${currentAuthState?.isAuthenticated}');
    
    // Listen to auth changes from V2 provider
    _ref.listen<AuthStateV2>(
      authProviderV2,
      (previous, next) {
        print('🔔 [RouterNotifier] Auth changed: ${previous?.isAuthenticated} → ${next.isAuthenticated}');
        currentAuthState = next;
        notifyListeners(); // Tell GoRouter to re-evaluate redirects
      },
    );
  }

  final Ref _ref;
  AuthStateV2? currentAuthState;
}
