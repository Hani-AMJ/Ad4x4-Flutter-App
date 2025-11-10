import '../models/notification_model.dart';

final List<NotificationModel> sampleNotifications = [
  // New trip notification (unread)
  NotificationModel(
    id: 'notif_001',
    title: 'New Trip: Desert Safari Adventure',
    message: 'Hani Al-Mansouri posted a new trip to Liwa Dunes. Join now!',
    type: 'trip',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    isRead: false,
    imageUrl: 'https://picsum.photos/seed/trip1/400/300',
    actionType: 'view_trip',
    actionId: 'trip_001',
  ),

  // Event RSVP reminder (unread)
  NotificationModel(
    id: 'notif_002',
    title: 'Event Tomorrow: Monthly Meeting',
    message: 'Don\'t forget! Monthly Club Meeting starts at 7:00 PM tomorrow.',
    type: 'event',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    isRead: false,
    imageUrl: 'https://picsum.photos/seed/meeting1/400/300',
    actionType: 'view_event',
    actionId: 'evt_001',
  ),

  // Member joined trip (read)
  NotificationModel(
    id: 'notif_003',
    title: 'Trip Update: New Member Joined',
    message: 'Ahmad Al-Balushi joined your trip "Empty Quarter Expedition"',
    type: 'trip',
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    isRead: true,
    actionType: 'view_trip',
    actionId: 'trip_003',
  ),

  // Photo liked (unread)
  NotificationModel(
    id: 'notif_004',
    title: 'Photo Liked',
    message: 'Mohammed Al-Shamsi liked your photo in "Desert Safari 2024"',
    type: 'social',
    timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    isRead: false,
    imageUrl: 'https://picsum.photos/seed/photo1/400/300',
    actionType: 'view_album',
    actionId: 'album_001',
  ),

  // Trip reminder (read)
  NotificationModel(
    id: 'notif_005',
    title: 'Trip Starting Soon!',
    message: 'Your trip "Sunset Dune Bash" starts in 2 days. Prepare your vehicle!',
    type: 'trip',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
    actionType: 'view_trip',
    actionId: 'trip_002',
  ),

  // New member (read)
  NotificationModel(
    id: 'notif_006',
    title: 'New Member Joined',
    message: 'Welcome Saif Al-Qassimi to AD4x4 Club!',
    type: 'social',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    isRead: true,
    actionType: 'view_profile',
    actionId: 'user_005',
  ),

  // Event completed (read)
  NotificationModel(
    id: 'notif_007',
    title: 'Event Completed',
    message: 'Hope you enjoyed "Off-Road Driving Workshop"! Share your feedback.',
    type: 'event',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
    actionType: 'view_event',
    actionId: 'evt_003',
  ),

  // Achievement unlocked (unread)
  NotificationModel(
    id: 'notif_008',
    title: '🏆 Achievement Unlocked!',
    message: 'You\'ve completed 10 trips! Keep exploring the desert.',
    type: 'system',
    timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    isRead: false,
  ),

  // Vehicle inspection reminder (read)
  NotificationModel(
    id: 'notif_009',
    title: 'Vehicle Inspection Reminder',
    message: 'It\'s been 6 months since your last inspection. Time for a check-up!',
    type: 'alert',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),

  // Trip cancelled (read)
  NotificationModel(
    id: 'notif_010',
    title: 'Trip Cancelled',
    message: 'Unfortunately, "Night Desert Run" has been cancelled due to weather.',
    type: 'alert',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
    isRead: true,
    actionType: 'view_trip',
    actionId: 'trip_007',
  ),

  // Gallery album created (read)
  NotificationModel(
    id: 'notif_011',
    title: 'New Album Created',
    message: 'Khalid Al-Mazrouei created album "Big Red Adventures"',
    type: 'social',
    timestamp: DateTime.now().subtract(const Duration(days: 4)),
    isRead: true,
    imageUrl: 'https://picsum.photos/seed/album2/400/300',
    actionType: 'view_album',
    actionId: 'album_003',
  ),

  // System maintenance (read)
  NotificationModel(
    id: 'notif_012',
    title: 'System Update',
    message: 'App has been updated to v2.1.0. Check out new features!',
    type: 'system',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),

  // Member birthday (read)
  NotificationModel(
    id: 'notif_013',
    title: '🎂 Birthday Today!',
    message: 'Wish Ahmad Al-Balushi a happy birthday!',
    type: 'social',
    timestamp: DateTime.now().subtract(const Duration(days: 6)),
    isRead: true,
    actionType: 'view_profile',
    actionId: 'user_002',
  ),

  // Event registration opened (read)
  NotificationModel(
    id: 'notif_014',
    title: 'Event Registration Open',
    message: 'Registration for "Annual Hill Climb Challenge" is now open!',
    type: 'event',
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    isRead: true,
    imageUrl: 'https://picsum.photos/seed/competition1/400/300',
    actionType: 'view_event',
    actionId: 'evt_004',
  ),

  // Welcome notification (read)
  NotificationModel(
    id: 'notif_015',
    title: 'Welcome to AD4x4!',
    message: 'Thanks for joining the region\'s largest off-road community. Start exploring!',
    type: 'system',
    timestamp: DateTime.now().subtract(const Duration(days: 30)),
    isRead: true,
  ),
];
