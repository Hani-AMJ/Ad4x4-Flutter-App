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
import '../../features/gallery/presentation/screens/photo_upload_screen.dart';
// Full-screen photo viewer is opened with Navigator.push, not GoRouter
// import '../../features/gallery/presentation/screens/full_screen_photo_viewer.dart';
import '../../features/gallery/presentation/screens/favorites_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/logbook/presentation/screens/logbook_timeline_screen.dart';
import '../../features/logbook/presentation/screens/skills_matrix_screen.dart';
import '../../features/logbook/presentation/screens/trip_history_with_logbook_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/members/presentation/screens/members_list_screen.dart';
import '../../features/members/presentation/screens/member_details_screen.dart';
import '../../features/vehicles/presentation/screens/vehicles_list_screen.dart';
import '../../features/vehicles/presentation/screens/add_vehicle_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/search/presentation/screens/global_search_screen.dart';
import '../../features/debug/auth_debug_screen.dart';
import '../../features/debug/permission_debug_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_dashboard_home_screen.dart';
import '../../features/admin/presentation/screens/admin_trips_pending_screen.dart';
import '../../features/admin/presentation/screens/admin_trips_all_screen.dart';
import '../../features/admin/presentation/screens/admin_trips_wizard_screen.dart';
import '../../features/admin/presentation/screens/admin_trip_edit_screen.dart';
import '../../features/admin/presentation/screens/admin_trip_registrants_screen.dart';
import '../../features/admin/presentation/screens/admin_members_list_screen.dart';
import '../../features/admin/presentation/screens/admin_member_details_screen.dart';
import '../../features/admin/presentation/screens/admin_member_edit_screen.dart';
import '../../features/admin/presentation/screens/admin_meeting_points_screen.dart';
import '../../features/admin/presentation/screens/admin_meeting_point_form_screen.dart';
import '../../features/admin/presentation/screens/admin_upgrade_requests_screen.dart';
import '../../features/admin/presentation/screens/admin_upgrade_request_details_screen.dart';
import '../../features/admin/presentation/screens/admin_create_upgrade_request_screen.dart';
import '../../features/admin/presentation/screens/admin_logbook_entries_screen.dart';
import '../../features/admin/presentation/screens/admin_create_logbook_entry_screen.dart';
import '../../features/admin/presentation/screens/admin_sign_off_skills_screen.dart';
import '../../features/admin/presentation/screens/admin_trip_reports_screen.dart';
// Phase 3B - Enhanced Trip Management Screens
import '../../features/admin/presentation/screens/admin_trip_media_screen.dart';
import '../../features/admin/presentation/screens/admin_comments_moderation_screen.dart';
import '../../features/admin/presentation/screens/admin_registration_analytics_screen.dart';
import '../../features/admin/presentation/screens/admin_bulk_registrations_screen.dart';
import '../../features/admin/presentation/screens/admin_waitlist_management_screen.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';

/// 🔄 V2: Clean Riverpod-based Router with Simplified Auth Guards
final goRouterProvider = Provider<GoRouter>((ref) {
  // Listen to auth state changes (V2 - Clean implementation)
  final authStateNotifier = _AuthStateNotifierV2(ref);
  
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    refreshListenable: authStateNotifier,
    redirect: (context, state) {
      final authState = authStateNotifier.currentAuthState;
      final isAuthenticated = authState?.isAuthenticated ?? false;
      final isLoading = authState?.isLoading ?? false;
      final currentLocation = state.matchedLocation;
      
      // Check if current page is auth page, splash page, or debug page
      final isAuthPage = currentLocation == '/login' || 
                        currentLocation == '/register' ||
                        currentLocation == '/forgot-password';
      
      final isSplashPage = currentLocation == '/splash';
      
      // Debug pages are always accessible (no auth required)
      final isDebugPage = currentLocation.startsWith('/debug');
      
      print('🔀 [Router] $currentLocation | Auth: $isAuthenticated | Loading: $isLoading');
      
      // Wait for auth to finish loading
      if (isLoading) {
        print('⏳ [Router] Loading auth state...');
        return null;
      }
      
      // Allow splash page without authentication (will handle its own navigation)
      if (isSplashPage) {
        print('🌟 [Router] Splash page - allowing access');
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
      // Splash Screen Route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
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
          final tripId = int.parse(state.pathParameters['id']!);
          return AdminTripEditScreen(tripId: tripId);
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
      GoRoute(
        path: '/gallery/upload/:galleryId',
        name: 'upload-photos',
        builder: (context, state) {
          final galleryId = int.parse(state.pathParameters['galleryId']!);
          final galleryTitle = state.uri.queryParameters['galleryTitle'] ?? 'Gallery';
          return PhotoUploadScreen(
            galleryId: galleryId,
            galleryTitle: galleryTitle,
          );
        },
      ),
      GoRoute(
        path: '/gallery/favorites',
        name: 'favorites',
        builder: (context, state) => const FavoritesScreen(),
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

      // Logbook Routes
      GoRoute(
        path: '/logbook',
        name: 'logbook',
        builder: (context, state) => const LogbookTimelineScreen(),
      ),
      GoRoute(
        path: '/logbook/skills-matrix',
        name: 'skills-matrix',
        builder: (context, state) {
          final memberIdStr = state.uri.queryParameters['memberId'];
          final memberId = memberIdStr != null ? int.tryParse(memberIdStr) : null;
          return SkillsMatrixScreen(memberId: memberId);
        },
      ),
      GoRoute(
        path: '/logbook/trip-history',
        name: 'trip-history-logbook',
        builder: (context, state) {
          final memberIdStr = state.uri.queryParameters['memberId'];
          final memberId = memberIdStr != null ? int.tryParse(memberIdStr) : null;
          return TripHistoryWithLogbookScreen(memberId: memberId);
        },
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
      GoRoute(
        path: '/debug/permissions',
        name: 'permission-debug',
        builder: (context, state) => const PermissionDebugScreen(),
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

      // Admin Routes (Permission-gated)
      ShellRoute(
        builder: (context, state, child) {
          // Admin shell - wraps all admin routes with dashboard layout
          return AdminDashboardScreen(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin',
            name: 'admin',
            redirect: (context, state) {
              // Redirect /admin to /admin/dashboard (default admin page)
              return '/admin/dashboard';
            },
          ),
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminDashboardHomeScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/trips/pending',
            name: 'admin-trips-pending',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminTripsPendingScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/trips/all',
            name: 'admin-trips-all',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminTripsAllScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/trips/wizard',
            name: 'admin-trips-wizard',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminTripsWizardScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/trips/:id/registrants',
            name: 'admin-trip-registrants',
            pageBuilder: (context, state) {
              final tripId = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: AdminTripRegistrantsScreen(tripId: tripId),
              );
            },
          ),
          GoRoute(
            path: '/admin/members',
            name: 'admin-members',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminMembersListScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/members/:id',
            name: 'admin-member-details',
            pageBuilder: (context, state) {
              final memberId = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: AdminMemberDetailsScreen(memberId: memberId),
              );
            },
          ),
          GoRoute(
            path: '/admin/members/:id/edit',
            name: 'admin-member-edit',
            pageBuilder: (context, state) {
              final memberId = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: AdminMemberEditScreen(memberId: memberId),
              );
            },
          ),
          GoRoute(
            path: '/admin/meeting-points',
            name: 'admin-meeting-points',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminMeetingPointsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/meeting-points/create',
            name: 'admin-meeting-point-create',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminMeetingPointFormScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/meeting-points/:id/edit',
            name: 'admin-meeting-point-edit',
            pageBuilder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return NoTransitionPage(
                child: AdminMeetingPointFormScreen(meetingPointId: id),
              );
            },
          ),
          GoRoute(
            path: '/admin/upgrade-requests',
            name: 'admin-upgrade-requests',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminUpgradeRequestsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/upgrade-requests/create',
            name: 'admin-upgrade-request-create',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminCreateUpgradeRequestScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/upgrade-requests/:id',
            name: 'admin-upgrade-request-details',
            pageBuilder: (context, state) {
              final requestId = state.pathParameters['id']!;
              return NoTransitionPage(
                child: AdminUpgradeRequestDetailsScreen(requestId: requestId),
              );
            },
          ),
          // Marshal Panel Routes
          GoRoute(
            path: '/admin/logbook/entries',
            name: 'admin-logbook-entries',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminLogbookEntriesScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/logbook/create',
            name: 'admin-create-logbook-entry',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminCreateLogbookEntryScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/logbook/sign-off',
            name: 'admin-sign-off-skills',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminSignOffSkillsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/trip-reports',
            name: 'admin-trip-reports',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminTripReportsScreen(),
              );
            },
          ),
          // Phase 3B - Content Moderation Routes
          GoRoute(
            path: '/admin/trip-media',
            name: 'admin-trip-media',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminTripMediaScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/comments-moderation',
            name: 'admin-comments-moderation',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminCommentsModerationScreen(),
              );
            },
          ),
          // Phase 3B - Advanced Registration Management Routes
          GoRoute(
            path: '/admin/registration-analytics',
            name: 'admin-registration-analytics',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminRegistrationAnalyticsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/bulk-registrations',
            name: 'admin-bulk-registrations',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminBulkRegistrationsScreen(),
              );
            },
          ),
          GoRoute(
            path: '/admin/waitlist-management',
            name: 'admin-waitlist-management',
            pageBuilder: (context, state) {
              return NoTransitionPage(
                child: const AdminWaitlistManagementScreen(),
              );
            },
          ),
        ],
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
