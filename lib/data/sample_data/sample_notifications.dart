import '../models/notification_model.dart';

final List<NotificationModel> sampleNotifications = [
  // New trip notification (unread)
  NotificationModel(
    id: 1,
    title: 'New Trip: Desert Safari Adventure',
    body: 'Hani Al-Mansouri posted a new trip to Liwa Dunes. Join now!',
    type: 'NEW_TRIP',
    timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    relatedObjectId: 6307,
    relatedObjectType: 'Trip',
    isRead: false,
    imageUrl: 'https://picsum.photos/seed/trip1/400/300',
    actionType: 'view_trip',
    actionId: 'trip_001',
  ),

  // Event RSVP reminder (unread)
  NotificationModel(
    id: 2,
    title: 'Event Tomorrow: Monthly Meeting',
    body: 'Don\'t forget! Monthly Club Meeting starts at 7:00 PM tomorrow.',
    type: 'NEW_EVENT',
    timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    isRead: false,
    imageUrl: 'https://picsum.photos/seed/meeting1/400/300',
    actionType: 'view_event',
    actionId: 'evt_001',
  ),

  // Member joined trip (read)
  NotificationModel(
    id: 3,
    title: 'Trip Update: New Member Joined',
    body: 'Ahmad Al-Balushi joined your trip "Empty Quarter Expedition"',
    type: 'TRIP_UPDATE',
    timestamp: DateTime.now().subtract(const Duration(hours: 8)),
    relatedObjectId: 6303,
    relatedObjectType: 'Trip',
    isRead: true,
    actionType: 'view_trip',
    actionId: 'trip_003',
  ),

  // Photo liked (unread)
  NotificationModel(
    id: 4,
    title: 'Photo Liked',
    body: 'Mohammed Al-Shamsi liked your photo in "Desert Safari 2024"',
    type: 'SOCIAL',
    timestamp: DateTime.now().subtract(const Duration(hours: 12)),
    isRead: false,
    imageUrl: 'https://picsum.photos/seed/photo1/400/300',
    actionType: 'view_album',
    actionId: 'album_001',
  ),

  // Trip reminder (read)
  NotificationModel(
    id: 5,
    title: 'Trip Starting Soon!',
    body: 'Your trip "Sunset Dune Bash" starts in 2 days. Prepare your vehicle!',
    type: 'TRIP_UPDATE',
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    relatedObjectId: 6302,
    relatedObjectType: 'Trip',
    isRead: true,
    actionType: 'view_trip',
    actionId: 'trip_002',
  ),

  // New member (read)
  NotificationModel(
    id: 6,
    title: 'New Member Joined',
    body: 'Welcome Saif Al-Qassimi to AD4x4 Club!',
    type: 'MEMBER_APPROVED',
    timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 8)),
    relatedObjectId: 10005,
    relatedObjectType: 'Member',
    isRead: true,
    actionType: 'view_profile',
    actionId: 'user_005',
  ),

  // Event completed (read)
  NotificationModel(
    id: 7,
    title: 'Event Completed',
    body: 'Hope you enjoyed "Off-Road Driving Workshop"! Share your feedback.',
    type: 'EVENT_UPDATE',
    timestamp: DateTime.now().subtract(const Duration(days: 2)),
    isRead: true,
    actionType: 'view_event',
    actionId: 'evt_003',
  ),

  // Achievement unlocked (unread)
  NotificationModel(
    id: 8,
    title: '🏆 Achievement Unlocked!',
    body: 'You\'ve completed 10 trips! Keep exploring the desert.',
    type: 'SYSTEM',
    timestamp: DateTime.now().subtract(const Duration(days: 2, hours: 5)),
    isRead: false,
  ),

  // Vehicle inspection reminder (read)
  NotificationModel(
    id: 9,
    title: 'Vehicle Inspection Reminder',
    body: 'It\'s been 6 months since your last inspection. Time for a check-up!',
    type: 'ALERT',
    timestamp: DateTime.now().subtract(const Duration(days: 3)),
    isRead: true,
  ),

  // Trip cancelled (read)
  NotificationModel(
    id: 10,
    title: 'Trip Cancelled',
    body: 'Unfortunately, "Night Desert Run" has been cancelled due to weather.',
    type: 'TRIP_CANCELLED',
    timestamp: DateTime.now().subtract(const Duration(days: 3, hours: 12)),
    relatedObjectId: 6307,
    relatedObjectType: 'Trip',
    isRead: true,
    actionType: 'view_trip',
    actionId: 'trip_007',
  ),

  // Gallery album created (read)
  NotificationModel(
    id: 11,
    title: 'New Album Created',
    body: 'Khalid Al-Mazrouei created album "Big Red Adventures"',
    type: 'SOCIAL',
    timestamp: DateTime.now().subtract(const Duration(days: 4)),
    isRead: true,
    imageUrl: 'https://picsum.photos/seed/album2/400/300',
    actionType: 'view_album',
    actionId: 'album_003',
  ),

  // System maintenance (read)
  NotificationModel(
    id: 12,
    title: 'System Update',
    body: 'App has been updated to v2.1.0. Check out new features!',
    type: 'SYSTEM',
    timestamp: DateTime.now().subtract(const Duration(days: 5)),
    isRead: true,
  ),

  // Member birthday (read)
  NotificationModel(
    id: 13,
    title: '🎂 Birthday Today!',
    body: 'Wish Ahmad Al-Balushi a happy birthday!',
    type: 'SOCIAL',
    timestamp: DateTime.now().subtract(const Duration(days: 6)),
    relatedObjectId: 10002,
    relatedObjectType: 'Member',
    isRead: true,
    actionType: 'view_profile',
    actionId: 'user_002',
  ),

  // Event registration opened (read)
  NotificationModel(
    id: 14,
    title: 'Event Registration Open',
    body: 'Registration for "Annual Hill Climb Challenge" is now open!',
    type: 'NEW_EVENT',
    timestamp: DateTime.now().subtract(const Duration(days: 7)),
    isRead: true,
    imageUrl: 'https://picsum.photos/seed/competition1/400/300',
    actionType: 'view_event',
    actionId: 'evt_004',
  ),

  // Welcome notification (read)
  NotificationModel(
    id: 15,
    title: 'Welcome to AD4x4!',
    body: 'Thanks for joining the region\'s largest off-road community. Start exploring!',
    type: 'SYSTEM',
    timestamp: DateTime.now().subtract(const Duration(days: 30)),
    isRead: true,
  ),
];
