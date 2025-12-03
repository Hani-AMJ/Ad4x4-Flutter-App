import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/event_model.dart';
import '../../../../shared/widgets/widgets.dart';
import 'package:intl/intl.dart';

class EventDetailsScreen extends StatefulWidget {
  final EventModel event;

  const EventDetailsScreen({
    super.key,
    required this.event,
  });

  @override
  State<EventDetailsScreen> createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> {
  late EventModel _event;
  bool _isLoading = false;
  bool _isRsvped = false;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _isRsvped = _event.isRsvped;
  }

  Future<void> _handleRSVP() async {
    if (!_event.isRsvpRequired) return;

    setState(() => _isLoading = true);

    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isRsvped = !_isRsvped;
        _event = _event.copyWith(
          isRsvped: _isRsvped,
          attendees: _isRsvped ? _event.attendees + 1 : _event.attendees - 1,
        );
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isRsvped
                ? 'Successfully RSVP\'d to ${_event.title}!'
                : 'RSVP cancelled for ${_event.title}',
          ),
          backgroundColor: _isRsvped ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  String _getEventTypeIcon(String type) {
    switch (type) {
      case 'meeting':
        return '📋';
      case 'social':
        return '🎉';
      case 'training':
        return '🎓';
      case 'competition':
        return '🏆';
      default:
        return '📅';
    }
  }

  Color _getEventTypeColor(String type, ColorScheme colors) {
    switch (type) {
      case 'meeting':
        return Colors.blue;
      case 'social':
        return Colors.purple;
      case 'training':
        return Colors.green;
      case 'competition':
        return Colors.orange;
      default:
        return colors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final dateFormat = DateFormat('EEEE, MMMM dd, yyyy');
    final timeFormat = DateFormat('h:mm a');

    return Scaffold(
      backgroundColor: colors.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            backgroundColor: colors.surface,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _event.imageUrl != null
                  ? Image.network(
                      _event.imageUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: colors.surface,
                      child: Icon(
                        Icons.event,
                        size: 80,
                        color: colors.onSurface.withValues(alpha: 0.3),
                      ),
                    ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _getEventTypeColor(_event.type, colors).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getEventTypeIcon(_event.type),
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _event.type.toUpperCase(),
                              style: TextStyle(
                                color: _getEventTypeColor(_event.type, colors),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        _event.title,
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info Cards
                      _InfoCard(
                        icon: Icons.calendar_today,
                        title: 'Date',
                        value: dateFormat.format(_event.startDate),
                        colors: colors,
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.access_time,
                        title: 'Time',
                        value: '${timeFormat.format(_event.startDate)} - ${timeFormat.format(_event.endDate)}',
                        colors: colors,
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        icon: Icons.location_on,
                        title: 'Location',
                        value: _event.location,
                        colors: colors,
                      ),
                      const SizedBox(height: 12),

                      if (_event.meetingPoint != null) ...[
                        _InfoCard(
                          icon: Icons.place,
                          title: 'Meeting Point',
                          value: _event.meetingPoint!,
                          colors: colors,
                        ),
                        const SizedBox(height: 12),
                      ],

                      _InfoCard(
                        icon: Icons.person,
                        title: 'Organizer',
                        value: _event.organizer,
                        colors: colors,
                      ),
                      const SizedBox(height: 24),

                      // Description
                      Text(
                        'About',
                        style: TextStyle(
                          color: colors.onSurface,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _event.description,
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.8),
                          fontSize: 15,
                          height: 1.5,
                        ),
                      ),

                      // Agenda
                      if (_event.agenda != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Agenda',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.onSurface.withValues(alpha: 0.1),
                            ),
                          ),
                          child: Text(
                            _event.agenda!,
                            style: TextStyle(
                              color: colors.onSurface.withValues(alpha: 0.8),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],

                      // Additional Info
                      if (_event.additionalInfo != null) ...[
                        const SizedBox(height: 24),
                        Text(
                          'Additional Information',
                          style: TextStyle(
                            color: colors.onSurface,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ..._event.additionalInfo!.entries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: colors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: colors.onSurface.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.replaceAll('_', ' ').toUpperCase(),
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  if (entry.value is List)
                                    ...(entry.value as List).map((item) {
                                      return Padding(
                                        padding: const EdgeInsets.only(bottom: 4),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.check_circle,
                                              size: 16,
                                              color: colors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                item.toString(),
                                                style: TextStyle(
                                                  color: colors.onSurface.withValues(alpha: 0.8),
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    })
                                  else
                                    Text(
                                      entry.value.toString(),
                                      style: TextStyle(
                                        color: colors.onSurface.withValues(alpha: 0.8),
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],

                      // Attendees Count
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.primary.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.people,
                              color: colors.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _event.maxAttendees != null
                                  ? '${_event.attendees} / ${_event.maxAttendees} attending'
                                  : '${_event.attendees} attending',
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // RSVP Button
                      if (_event.status == 'upcoming' && _event.isRsvpRequired)
                        PrimaryButton(
                          text: _isRsvped ? 'Cancel RSVP' : 'RSVP to Event',
                          onPressed: _handleRSVP,
                          isLoading: _isLoading,
                          icon: _isRsvped ? Icons.cancel : Icons.check_circle,
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final ColorScheme colors;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: colors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
