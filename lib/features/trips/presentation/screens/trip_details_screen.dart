import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../providers/trips_provider.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/image_proxy.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../shared/widgets/admin/trip_admin_ribbon.dart';

/// Trip Details Screen - Complete implementation with beautiful UI
class TripDetailsScreen extends ConsumerWidget {
  final String tripId;

  const TripDetailsScreen({super.key, required this.tripId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripDetailAsync = ref.watch(tripDetailProvider(int.parse(tripId)));
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: tripDetailAsync.when(
        data: (trip) {
          return CustomScrollView(
            slivers: [
              // Hero Image App Bar
              SliverAppBar(
                expandedHeight: 250,
                pinned: true,
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  title: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      trip.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Background Image
                      trip.imageUrl != null
                          ? CachedNetworkImage(
                              imageUrl: ImageProxy.getProxiedUrl(trip.imageUrl),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: colors.primaryContainer,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colors.primary,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: colors.primaryContainer,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.terrain,
                                        size: 80,
                                        color: colors.primary.withValues(alpha: 0.5),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No Image',
                                        style: TextStyle(
                                          color: colors.onSurface.withValues(alpha: 0.5),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              color: colors.primaryContainer,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.terrain,
                                      size: 80,
                                      color: colors.primary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No Image',
                                      style: TextStyle(
                                        color: colors.onSurface.withValues(alpha: 0.5),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                      
                      // Gradient overlay for better title readability
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        height: 120,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Admin Ribbon (for marshals/board members)
              if (_canAdminTrip(ref, trip))
                SliverToBoxAdapter(
                  child: TripAdminRibbon(
                    tripId: tripId,
                    approvalStatus: _getTripApprovalStatus(trip.approvalStatus),
                    onApprove: () => _handleApproveTrip(context, ref, trip),
                    onDecline: () => _handleDeclineTrip(context, ref, trip),
                    onEdit: () => _handleEditTrip(context, trip),
                    onManageRegistrants: () => _handleManageRegistrants(context, trip),
                    onCheckin: () => _handleCheckin(context, ref, trip),
                    onExport: () => _handleExportRegistrants(context, trip),
                    onBindGallery: () => _handleBindGallery(context, trip),
                  ),
                ),

              // Content
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level Badge
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildLevelBadge(trip.level.displayName ?? trip.level.name, colors),
                          _buildStatusBadge(_getStatusText(trip), colors),
                        ],
                      ),
                    ),

                    // Key Information Cards
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              Icons.calendar_today,
                              'Dates',
                              _formatDateRange(trip.startTime, trip.endTime),
                              colors,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildInfoCard(
                              context,
                              Icons.people,
                              'Capacity',
                              '${trip.registeredCount}/${trip.capacity}',
                              colors,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Organizer Section
                    _buildOrganizerSection(context, trip, colors),

                    // Meeting Point Section (if exists)
                    if (trip.meetingPoint != null)
                      _buildMeetingPointSection(context, trip, colors),

                    // Important Dates
                    _buildImportantDatesSection(context, trip, colors),

                    // Description Section
                    _buildDescriptionSection(context, trip, colors),

                    // Registered Members
                    if (trip.registered.isNotEmpty)
                      _buildRegisteredMembersSection(context, trip, colors),

                    // Waitlist
                    if (trip.waitlistCount > 0)
                      _buildWaitlistSection(context, trip, colors),

                    // Bottom padding for action buttons
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          print('❌ Trip details error: $error');
          print('Stack trace: $stack');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: colors.error),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to Load Trip Details',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Go Back'),
                  ),
                ],
              ),
            ),
          );
        },
      ),

      // Action Buttons (Floating)
      bottomNavigationBar: tripDetailAsync.maybeWhen(
        data: (trip) => _buildActionButtons(context, ref, trip, colors),
        orElse: () => null,
      ),
    );
  }

  Widget _buildLevelBadge(String level, ColorScheme colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.trending_up, size: 16, color: colors.primary),
          const SizedBox(width: 4),
          Text(
            level,
            style: TextStyle(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status, ColorScheme colors) {
    final Color badgeColor;
    final IconData icon;

    if (status.contains('Upcoming')) {
      badgeColor = Colors.green;
      icon = Icons.schedule;
    } else if (status.contains('Ongoing')) {
      badgeColor = Colors.orange;
      icon = Icons.play_circle;
    } else if (status.contains('Completed')) {
      badgeColor = Colors.grey;
      icon = Icons.check_circle;
    } else {
      badgeColor = Colors.blue;
      icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    ColorScheme colors,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrganizerSection(BuildContext context, dynamic trip, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.person, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Trip Organizer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: colors.primary.withValues(alpha: 0.2),
                  child: Text(
                    trip.lead.firstName?.isNotEmpty == true
                        ? trip.lead.firstName![0].toUpperCase()
                        : trip.lead.username[0].toUpperCase(),
                    style: TextStyle(
                      color: colors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Text(
                  trip.lead.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (trip.lead.level != null)
                      Text('Level: ${trip.lead.level}${trip.lead.tripCount != null ? ' • ${trip.lead.tripCount} trips' : ''}'),
                    if (trip.lead.carBrand != null && trip.lead.carModel != null)
                      Text('Vehicle: ${trip.lead.carBrand} ${trip.lead.carModel}'),
                  ],
                ),
                trailing: trip.lead.phone != null
                    ? IconButton(
                        icon: const Icon(Icons.phone),
                        onPressed: () => _launchPhone(trip.lead.phone!),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingPointSection(BuildContext context, dynamic trip, ColorScheme colors) {
    final meetingPoint = trip.meetingPoint;
    if (meetingPoint == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Meeting Point',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                meetingPoint.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (meetingPoint.lat != null && meetingPoint.lon != null) ...[
                const SizedBox(height: 4),
                Text(
                  '📌 ${meetingPoint.lat}, ${meetingPoint.lon}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
              if (meetingPoint.link != null) ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _launchMaps(meetingPoint.link!),
                  icon: const Icon(Icons.map),
                  label: const Text('View on Google Maps'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImportantDatesSection(BuildContext context, dynamic trip, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.event, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Important Dates',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (trip.cutOff != null)
                _buildDateItem(
                  '⏰ Registration Cut-off',
                  DateFormat('MMM dd, yyyy at h:mm a').format(trip.cutOff!),
                  colors,
                ),
              _buildDateItem(
                '🚀 Trip Start',
                DateFormat('MMM dd, yyyy at h:mm a').format(trip.startTime),
                colors,
              ),
              _buildDateItem(
                '🏁 Trip End',
                DateFormat('MMM dd, yyyy at h:mm a').format(trip.endTime),
                colors,
                isLast: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateItem(String label, String date, ColorScheme colors, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colors.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionSection(BuildContext context, dynamic trip, ColorScheme colors) {
    final cleanDescription = TextUtils.stripHtmlTags(trip.description);
    
    if (cleanDescription.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.description, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'About This Trip',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                cleanDescription,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.6,
                  color: colors.onSurface.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegisteredMembersSection(BuildContext context, dynamic trip, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.people, color: colors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Registered Members (${trip.registered.length})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...trip.registered.map((reg) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: colors.primary.withValues(alpha: 0.2),
                      child: Text(
                        reg.member.firstName?.isNotEmpty == true
                            ? reg.member.firstName![0].toUpperCase()
                            : reg.member.username[0].toUpperCase(),
                        style: TextStyle(color: colors.primary, fontSize: 14),
                      ),
                    ),
                    title: Text(
                      reg.member.displayName,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: reg.member.level != null
                        ? Text(
                            reg.member.level!,
                            style: const TextStyle(fontSize: 12),
                          )
                        : null,
                    trailing: (reg.status == 'checked_in' || reg.status == 'checked_out')
                        ? const Icon(Icons.check_circle, color: Colors.green, size: 20)
                        : null,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWaitlistSection(BuildContext context, dynamic trip, ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.schedule, color: colors.secondary),
                  const SizedBox(width: 8),
                  Text(
                    'Waitlist (${trip.waitlistCount})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (trip.waitlist.isEmpty)
                Text(
                  'No one on waitlist yet',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                )
              else
                ...trip.waitlist.map((wait) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      leading: CircleAvatar(
                        radius: 18,
                        backgroundColor: colors.secondary.withValues(alpha: 0.2),
                        child: Text(
                          wait.member.firstName?.isNotEmpty == true
                              ? wait.member.firstName![0].toUpperCase()
                              : wait.member.username[0].toUpperCase(),
                          style: TextStyle(color: colors.secondary, fontSize: 14),
                        ),
                      ),
                      title: Text(
                        wait.member.displayName,
                        style: const TextStyle(fontSize: 14),
                      ),
                      trailing: Text(
                        'Position ${wait.position}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic trip,
    ColorScheme colors,
  ) {
    // Get current user ID
    final authState = ref.watch(authProviderV2);
    final currentUserId = authState.user?.id ?? 0;

    // Check user registration status
    final isRegistered = trip.registered.any((reg) => reg.member.id == currentUserId);
    final isOnWaitlist = trip.waitlist.any((wait) => wait.member.id == currentUserId);
    final isFull = trip.registeredCount >= trip.capacity;
    final hasWaitlist = trip.allowWaitlist;

    // Watch trip actions state for loading
    final tripActionsState = ref.watch(tripActionsProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: tripActionsState.isLoading
                  ? Center(
                      child: CircularProgressIndicator(color: colors.primary),
                    )
                  : ElevatedButton.icon(
                      onPressed: () => _handleRegistrationAction(
                        context,
                        ref,
                        trip,
                        isRegistered,
                        isOnWaitlist,
                        isFull,
                        hasWaitlist,
                      ),
                      icon: Icon(_getRegistrationIcon(isRegistered, isOnWaitlist, isFull)),
                      label: Text(_getRegistrationLabel(isRegistered, isOnWaitlist, isFull, hasWaitlist)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: _getRegistrationButtonColor(
                          colors,
                          isRegistered,
                          isOnWaitlist,
                          isFull,
                          hasWaitlist,
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            IconButton.outlined(
              onPressed: () {
                context.push('/trips/${trip.id}/chat?title=${Uri.encodeComponent(trip.title)}');
              },
              icon: const Icon(Icons.chat_bubble_outline),
              tooltip: 'Trip Chat',
            ),
            const SizedBox(width: 8),
            IconButton.outlined(
              onPressed: () {
                // TODO: Implement share functionality
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
              icon: const Icon(Icons.share),
              tooltip: 'Share Trip',
            ),
          ],
        ),
      ),
    );
  }

  IconData _getRegistrationIcon(bool isRegistered, bool isOnWaitlist, bool isFull) {
    if (isRegistered) return Icons.check_circle;
    if (isOnWaitlist) return Icons.schedule;
    if (isFull) return Icons.schedule;
    return Icons.person_add;
  }

  String _getRegistrationLabel(bool isRegistered, bool isOnWaitlist, bool isFull, bool hasWaitlist) {
    if (isRegistered) return 'Unregister';
    if (isOnWaitlist) return 'Leave Waitlist';
    if (isFull && hasWaitlist) return 'Join Waitlist';
    if (isFull) return 'Trip Full';
    return 'Register';
  }

  Color _getRegistrationButtonColor(
    ColorScheme colors,
    bool isRegistered,
    bool isOnWaitlist,
    bool isFull,
    bool hasWaitlist,
  ) {
    if (isRegistered) return colors.error;
    if (isOnWaitlist) return colors.tertiary;
    if (isFull && hasWaitlist) return colors.secondary;
    if (isFull) return colors.surfaceContainerHighest;
    return colors.primary;
  }

  Future<void> _handleRegistrationAction(
    BuildContext context,
    WidgetRef ref,
    dynamic trip,
    bool isRegistered,
    bool isOnWaitlist,
    bool isFull,
    bool hasWaitlist,
  ) async {
    try {
      if (isRegistered) {
        // Unregister from trip
        final confirmed = await _showConfirmDialog(
          context,
          'Unregister from Trip',
          'Are you sure you want to unregister from this trip?',
        );
        if (!confirmed) return;

        await ref.read(tripActionsProvider.notifier).unregister(trip.id);
        
        // Refresh trip details to update UI
        ref.invalidate(tripDetailProvider(trip.id));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully unregistered from trip'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (isOnWaitlist) {
        // Leave waitlist (unregister also removes from waitlist)
        final confirmed = await _showConfirmDialog(
          context,
          'Leave Waitlist',
          'Are you sure you want to leave the waitlist?',
        );
        if (!confirmed) return;

        await ref.read(tripActionsProvider.notifier).unregister(trip.id);
        
        // Refresh trip details to update UI
        ref.invalidate(tripDetailProvider(trip.id));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully left waitlist'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (isFull && hasWaitlist) {
        // Join waitlist
        await ref.read(tripActionsProvider.notifier).joinWaitlist(trip.id);
        
        // Refresh trip details to update UI
        ref.invalidate(tripDetailProvider(trip.id));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully joined waitlist!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (!isFull) {
        // Register for trip
        // TODO: Add vehicle capacity dialog if needed
        await ref.read(tripActionsProvider.notifier).register(trip.id);
        
        // Refresh trip details to update UI
        ref.invalidate(tripDetailProvider(trip.id));
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully registered for trip!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    String title,
    String message,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  String _getStatusText(dynamic trip) {
    final now = DateTime.now();
    if (now.isBefore(trip.startTime)) return 'Upcoming';
    if (now.isAfter(trip.endTime)) return 'Completed';
    return 'Ongoing';
  }

  String _formatDateRange(DateTime start, DateTime end) {
    final startFormat = DateFormat('MMM dd');
    final endFormat = DateFormat('MMM dd, yyyy');
    
    if (start.year == end.year && start.month == end.month && start.day == end.day) {
      return DateFormat('MMM dd, yyyy').format(start);
    }
    
    return '${startFormat.format(start)} - ${endFormat.format(end)}';
  }

  Future<void> _launchPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchMaps(String mapsLink) async {
    final uri = Uri.parse(mapsLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ==========================================================================
  // ADMIN HELPER METHODS
  // ==========================================================================

  /// Check if current user can admin this trip
  bool _canAdminTrip(WidgetRef ref, dynamic trip) {
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    
    if (currentUser == null) return false;
    
    // Check if user is the trip lead
    if (trip.lead.id == currentUser.id) return true;
    
    // Check if user is a deputy lead
    if (trip.deputyLeads.any((deputy) => deputy.id == currentUser.id)) return true;
    
    // Check if user has board/admin permissions
    // Permission actions: 'approve_trips', 'manage_trips', 'view_all_trips'
    if (currentUser.hasPermission('approve_trips') || 
        currentUser.hasPermission('manage_trips')) {
      return true;
    }
    
    return false;
  }

  /// Convert string approval status to enum
  TripApprovalStatus _getTripApprovalStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return TripApprovalStatus.approved;
      case 'declined':
        return TripApprovalStatus.declined;
      default:
        return TripApprovalStatus.pending;
    }
  }

  /// Handle approve trip action
  Future<void> _handleApproveTrip(BuildContext context, WidgetRef ref, dynamic trip) async {
    try {
      await ref.read(tripActionsProvider.notifier).approveTrip(trip.id);
      
      // Small delay to ensure backend has updated
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Refresh trip details and trips list
      ref.invalidate(tripDetailProvider(trip.id));
      ref.invalidate(tripsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip approved successfully! Status updated.'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to approve trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle decline trip action
  Future<void> _handleDeclineTrip(BuildContext context, WidgetRef ref, dynamic trip) async {
    final reason = await _showDeclineReasonDialog(context);
    if (reason == null) return; // User cancelled
    
    try {
      await ref.read(tripActionsProvider.notifier).declineTrip(trip.id, reason: reason);
      
      // Small delay to ensure backend has updated
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Refresh trip details and trips list
      ref.invalidate(tripDetailProvider(trip.id));
      ref.invalidate(tripsProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Trip declined. Status updated.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to decline trip: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle edit trip action
  void _handleEditTrip(BuildContext context, dynamic trip) {
    // TODO: Navigate to edit screen when implemented
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Trip edit screen coming soon!')),
    );
  }

  /// Handle manage registrants action
  void _handleManageRegistrants(BuildContext context, dynamic trip) {
    // Show bottom sheet with registrants list
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Text(
                  'Registered Members',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: trip.registered.length,
                    itemBuilder: (context, index) {
                      final registration = trip.registered[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(registration.member.firstName?.isNotEmpty == true
                              ? registration.member.firstName![0].toUpperCase()
                              : registration.member.username[0].toUpperCase()),
                        ),
                        title: Text(registration.member.displayName),
                        subtitle: Text(registration.status ?? 'Confirmed'),
                        trailing: IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () {
                            // TODO: Implement remove member
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Remove member coming soon!')),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Handle check-in action
  void _handleCheckin(BuildContext context, WidgetRef ref, dynamic trip) {
    // TODO: Navigate to check-in screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Check-in screen coming soon!')),
    );
  }

  /// Handle export registrants action
  void _handleExportRegistrants(BuildContext context, dynamic trip) {
    // TODO: Implement CSV export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export feature coming soon!')),
    );
  }

  /// Handle bind gallery action
  void _handleBindGallery(BuildContext context, dynamic trip) {
    // TODO: Implement gallery binding
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery binding coming soon!')),
    );
  }

  /// Show decline reason dialog
  Future<String?> _showDeclineReasonDialog(BuildContext context) async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Decline Trip'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Reason for declining (optional)',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('Decline'),
          ),
        ],
      ),
    );
  }
}
