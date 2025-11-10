import '../models/event_model.dart';

final List<EventModel> sampleEvents = [
  // Monthly Meeting
  EventModel(
    id: 'evt_001',
    title: 'Monthly Club Meeting - November',
    description: 'Our regular monthly meeting to discuss upcoming trips, club activities, and member updates. All members are encouraged to attend.',
    startDate: DateTime.now().add(const Duration(days: 5)),
    endDate: DateTime.now().add(const Duration(days: 5, hours: 2)),
    location: 'AD4x4 Clubhouse, Al Ain',
    type: 'meeting',
    attendees: 28,
    maxAttendees: 50,
    organizer: 'Hani Al-Mansouri',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/meeting1/800/600',
    tags: ['meeting', 'monthly', 'members-only'],
    isRsvpRequired: true,
    isRsvped: false,
    meetingPoint: 'AD4x4 Clubhouse, Al Ain',
    agenda: '''
• Welcome and introductions
• Review of last month's activities
• Upcoming trips and events
• Club announcements
• Safety updates
• Open discussion
• Q&A session
''',
  ),

  // BBQ Social Event
  EventModel(
    id: 'evt_002',
    title: 'Desert BBQ & Campfire Night',
    description: 'Join us for a relaxing evening in the desert with BBQ, campfire, and great company. Bring your family and friends!',
    startDate: DateTime.now().add(const Duration(days: 12)),
    endDate: DateTime.now().add(const Duration(days: 13)),
    location: 'Fossil Rock, Sharjah',
    type: 'social',
    attendees: 42,
    maxAttendees: 60,
    organizer: 'Ahmad Al-Balushi',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/bbq1/800/600',
    tags: ['social', 'bbq', 'camping', 'family-friendly'],
    isRsvpRequired: true,
    isRsvped: true,
    meetingPoint: 'Fossil Rock parking area',
    additionalInfo: {
      'bring': ['Own BBQ equipment', 'Food and drinks', 'Camping chair', 'Warm clothing'],
      'provided': ['Campfire setup', 'Music', 'Group activities'],
    },
  ),

  // Training Workshop
  EventModel(
    id: 'evt_003',
    title: 'Off-Road Driving Workshop',
    description: 'Learn essential off-road driving techniques from experienced instructors. Perfect for beginners and intermediate drivers.',
    startDate: DateTime.now().add(const Duration(days: 18)),
    endDate: DateTime.now().add(const Duration(days: 18, hours: 6)),
    location: 'Al Ain Desert Training Area',
    type: 'training',
    attendees: 15,
    maxAttendees: 20,
    organizer: 'Mohammed Al-Shamsi',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/training1/800/600',
    tags: ['training', 'workshop', 'off-road', 'skills'],
    isRsvpRequired: true,
    isRsvped: false,
    meetingPoint: 'Al Ain Desert Training Area entrance',
    agenda: '''
• Introduction to off-road driving
• Vehicle preparation and inspection
• Tire pressure adjustment
• Sand driving techniques
• Recovery procedures
• Practical exercises
• Q&A and certification
''',
    additionalInfo: {
      'requirements': ['Valid driver license', 'Own 4x4 vehicle', 'Basic tools'],
      'includes': ['Professional instruction', 'Training materials', 'Lunch', 'Certificate'],
      'cost': 'AED 300 per person',
    },
  ),

  // Competition Event
  EventModel(
    id: 'evt_004',
    title: 'Annual Hill Climb Challenge',
    description: 'Test your driving skills in our annual hill climb competition. Prizes for top performers in different categories!',
    startDate: DateTime.now().add(const Duration(days: 25)),
    endDate: DateTime.now().add(const Duration(days: 25, hours: 8)),
    location: 'Big Red, Dubai',
    type: 'competition',
    attendees: 35,
    maxAttendees: 40,
    organizer: 'Khalid Al-Mazrouei',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/competition1/800/600',
    tags: ['competition', 'challenge', 'prizes', 'spectators-welcome'],
    isRsvpRequired: true,
    isRsvped: false,
    meetingPoint: 'Big Red main parking area',
    additionalInfo: {
      'categories': ['Stock vehicles', 'Modified vehicles', 'Expert class'],
      'prizes': ['1st place: AED 2000', '2nd place: AED 1000', '3rd place: AED 500'],
      'entry_fee': 'AED 100 per vehicle',
      'rules': 'Must be club member, valid insurance required, safety equipment mandatory',
    },
  ),

  // Social Gathering
  EventModel(
    id: 'evt_005',
    title: 'Coffee Morning Meetup',
    description: 'Casual morning coffee meetup to discuss vehicles, share stories, and plan future adventures.',
    startDate: DateTime.now().add(const Duration(days: 3)),
    endDate: DateTime.now().add(const Duration(days: 3, hours: 2)),
    location: 'Starbucks, Yas Mall Abu Dhabi',
    type: 'social',
    attendees: 18,
    maxAttendees: null,
    organizer: 'Saif Al-Qassimi',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/coffee1/800/600',
    tags: ['social', 'casual', 'coffee', 'networking'],
    isRsvpRequired: false,
    isRsvped: false,
    meetingPoint: 'Starbucks ground floor, Yas Mall',
  ),

  // Past Event
  EventModel(
    id: 'evt_006',
    title: 'Empty Quarter Expedition 2024',
    description: 'Multi-day expedition through the Empty Quarter desert. An unforgettable adventure!',
    startDate: DateTime.now().subtract(const Duration(days: 15)),
    endDate: DateTime.now().subtract(const Duration(days: 12)),
    location: 'Rub al Khali (Empty Quarter)',
    type: 'social',
    attendees: 22,
    maxAttendees: 25,
    organizer: 'Hani Al-Mansouri',
    status: 'completed',
    imageUrl: 'https://picsum.photos/seed/expedition1/800/600',
    tags: ['expedition', 'multi-day', 'camping', 'adventure'],
    isRsvpRequired: true,
    isRsvped: true,
    meetingPoint: 'Liwa Oasis',
  ),

  // Annual General Meeting
  EventModel(
    id: 'evt_007',
    title: 'Annual General Meeting 2024',
    description: 'Annual general meeting to review the year, elect board members, and plan for 2025.',
    startDate: DateTime.now().add(const Duration(days: 45)),
    endDate: DateTime.now().add(const Duration(days: 45, hours: 4)),
    location: 'AD4x4 Clubhouse, Al Ain',
    type: 'meeting',
    attendees: 12,
    maxAttendees: 100,
    organizer: 'Board of Directors',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/agm1/800/600',
    tags: ['meeting', 'annual', 'voting', 'important'],
    isRsvpRequired: true,
    isRsvped: false,
    meetingPoint: 'AD4x4 Clubhouse main hall',
    agenda: '''
• Welcome address by President
• Year in review - achievements and highlights
• Financial report
• Membership update
• Board elections
• Proposed amendments to club rules
• 2025 calendar planning
• Open forum
''',
    additionalInfo: {
      'voting_rights': 'Full members only',
      'quorum': 'Minimum 30 members required',
    },
  ),

  // Maintenance Workshop
  EventModel(
    id: 'evt_008',
    title: 'Vehicle Maintenance Workshop',
    description: 'Hands-on workshop covering basic vehicle maintenance and preparation for desert driving.',
    startDate: DateTime.now().add(const Duration(days: 8)),
    endDate: DateTime.now().add(const Duration(days: 8, hours: 4)),
    location: 'AutoPro Service Center, Al Ain',
    type: 'training',
    attendees: 10,
    maxAttendees: 15,
    organizer: 'Ahmad Al-Balushi',
    status: 'upcoming',
    imageUrl: 'https://picsum.photos/seed/maintenance1/800/600',
    tags: ['training', 'maintenance', 'workshop', 'technical'],
    isRsvpRequired: true,
    isRsvped: false,
    meetingPoint: 'AutoPro Service Center reception',
    agenda: '''
• Basic vehicle inspection checklist
• Fluid checks and changes
• Tire maintenance and rotation
• Recovery equipment overview
• Pre-trip preparation
• Common issues and solutions
• Hands-on practice
''',
    additionalInfo: {
      'bring': ['Your vehicle', 'Notebook', 'Questions'],
      'includes': ['Expert instruction', 'Refreshments', 'Maintenance checklist'],
      'cost': 'Free for members',
    },
  ),
];
