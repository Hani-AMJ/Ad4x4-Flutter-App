/// Route names for type-safe navigation
class RouteNames {
  // Auth Routes
  static const String splash = 'splash';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgot-password';

  // Main Routes
  static const String home = 'home';
  
  // Trip Routes
  static const String trips = 'trips';
  static const String createTrip = 'create-trip';
  static const String tripDetails = 'trip-details';
  
  // Event Routes
  static const String events = 'events';
  static const String eventDetails = 'event-details';
  
  // Gallery Routes
  static const String gallery = 'gallery';
  static const String album = 'album';
  
  // Member Routes
  static const String members = 'members';
  static const String memberDetails = 'member-details';
  
  // Profile Routes
  static const String profile = 'profile';
  static const String editProfile = 'edit-profile';
  
  // Vehicle Routes
  static const String vehicles = 'vehicles';
  static const String addVehicle = 'add-vehicle';
  
  // Settings Routes
  static const String settings = 'settings';
  
  // Notifications
  static const String notifications = 'notifications';
}

/// Route paths for URL construction
class RoutePaths {
  // Auth Paths
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // Main Paths
  static const String home = '/';
  
  // Trip Paths
  static const String trips = '/trips';
  static const String createTrip = '/trips/create';
  static String tripDetails(String id) => '/trips/$id';
  
  // Event Paths
  static const String events = '/events';
  static String eventDetails(String id) => '/events/$id';
  
  // Gallery Paths
  static const String gallery = '/gallery';
  static String album(String albumId) => '/gallery/album/$albumId';
  
  // Member Paths
  static const String members = '/members';
  static String memberDetails(String id) => '/members/$id';
  
  // Profile Paths
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  
  // Vehicle Paths
  static const String vehicles = '/vehicles';
  static const String addVehicle = '/vehicles/add';
  
  // Settings Paths
  static const String settings = '/settings';
  
  // Notifications
  static const String notifications = '/notifications';
}
