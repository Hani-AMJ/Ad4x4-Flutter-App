import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import '../providers/trips_provider.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/status_helpers.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/trip_export_service.dart';
import '../../../../shared/widgets/admin/trip_admin_ribbon.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/repository_providers.dart';

/// Optimistic registration state provider
/// Tracks local registration changes immediately without waiting for API
class OptimisticRegistrationState {
  final Map<int, bool> registeredTrips;  // tripId -> isRegistered
  final Map<int, bool> waitlistedTrips;  // tripId -> isWaitlisted

  const OptimisticRegistrationState({
    this.registeredTrips = const {},
    this.waitlistedTrips = const {},
  });

  OptimisticRegistrationState copyWith({
    Map<int, bool>? registeredTrips,
    Map<int, bool>? waitlistedTrips,
  }) {
    return OptimisticRegistrationState(
      registeredTrips: registeredTrips ?? this.registeredTrips,
      waitlistedTrips: waitlistedTrips ?? this.waitlistedTrips,
    );
  }
}

class OptimisticRegistrationNotifier extends StateNotifier<OptimisticRegistrationState> {
  OptimisticRegistrationNotifier() : super(const OptimisticRegistrationState());

  void setRegistered(int tripId, bool isRegistered) {
    state = state.copyWith(
      registeredTrips: {...state.registeredTrips, tripId: isRegistered},
      waitlistedTrips: {...state.waitlistedTrips, tripId: false},  // Clear waitlist
    );
  }

  void setWaitlisted(int tripId, bool isWaitlisted) {
    state = state.copyWith(
      waitlistedTrips: {...state.waitlistedTrips, tripId: isWaitlisted},
      registeredTrips: {...state.registeredTrips, tripId: false},  // Clear registration
    );
  }

  void clear(int tripId) {
    final newRegistered = Map<int, bool>.from(state.registeredTrips)..remove(tripId);
    final newWaitlisted = Map<int, bool>.from(state.waitlistedTrips)..remove(tripId);
    state = state.copyWith(
      registeredTrips: newRegistered,
      waitlistedTrips: newWaitlisted,
    );
  }
}

final optimisticRegistrationProvider = StateNotifierProvider<OptimisticRegistrationNotifier, OptimisticRegistrationState>((ref) {
  return OptimisticRegistrationNotifier();
});

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
                              imageUrl: trip.imageUrl!,
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
                    approvalStatus: trip.approvalStatus, // Pass status string directly
                    onApprove: () => _handleApproveTrip(context, ref, trip),
                    onDecline: () => _handleDeclineTrip(context, ref, trip),
                    onEdit: () => _handleEditTrip(context, ref, trip),
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
                          LevelDisplayHelper.buildCompactBadge(trip.level),
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

                    // Gallery Section (if trip has associated gallery)
                    if (trip.galleryId != null)
                      _buildGallerySection(context, trip, colors),

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
          
          // ✅ PHASE 1: Enhanced error handling with 404 detection
          // Check if this is a 404 error (trip deleted or not found)
          final apiException = error is ApiException ? error : null;
          final is404 = apiException?.isNotFound ?? 
                        error.toString().contains('404') ||
                        error.toString().toLowerCase().contains('not found');
          
          if (is404) {
            // ✅ PHASE 2: Remove deleted trip from cache
            WidgetsBinding.instance.addPostFrameCallback((_) {
              try {
                ref.read(tripsProvider.notifier).removeTripFromCache(
                  int.parse(tripId),
                );
              } catch (e) {
                print('⚠️ Failed to remove trip from cache: $e');
              }
            });
            
            // ✅ Show trip deleted/not available message
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.delete_outline,
                      size: 80,
                      color: colors.onSurface.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Trip No Longer Available',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'This trip has been deleted or is no longer accessible.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'It may have been cancelled by the organizer or removed by an administrator.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.5),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () {
                        // ✅ Auto-navigate back to trips list
                        context.go('/trips');
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Trips'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
          
          // ✅ Other errors - show retry option with enhanced messaging
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
                    apiException?.userFriendlyMessage ?? error.toString(),
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (apiException?.actionGuidance != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      apiException!.actionGuidance,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurface.withValues(alpha: 0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: badgeColor),
          const SizedBox(width: 4),
          Text(
            status,
            style: TextStyle(
              color: badgeColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
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
              // Section Header
              Row(
                children: [
                  Icon(Icons.groups, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Trip Leadership',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Trip Lead
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
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        trip.lead.displayName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green, width: 1),
                      ),
                      child: const Text(
                        'TRIP LEAD',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
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
              
              // Deputy Marshals (if any)
              if (trip.deputyLeads != null && (trip.deputyLeads as List).isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Deputy Marshals (${(trip.deputyLeads as List).length})',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                ...(trip.deputyLeads as List).map((deputy) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.withValues(alpha: 0.2),
                          child: Text(
                            deputy.firstName?.isNotEmpty == true
                                ? deputy.firstName![0].toUpperCase()
                                : deputy.username[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                deputy.displayName,
                                style: const TextStyle(fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue, width: 1),
                              ),
                              child: const Text(
                                'DEPUTY',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            if (deputy.level != null)
                              Text('Level: ${deputy.level}${deputy.tripCount != null ? ' • ${deputy.tripCount} trips' : ''}'),
                            if (deputy.carBrand != null && deputy.carModel != null)
                              Text('Vehicle: ${deputy.carBrand} ${deputy.carModel}'),
                          ],
                        ),
                        trailing: deputy.phone != null
                            ? IconButton(
                                icon: const Icon(Icons.phone),
                                onPressed: () => _launchPhone(deputy.phone!),
                              )
                            : null,
                      ),
                    )),
              ],
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

  Widget _buildGallerySection(BuildContext context, dynamic trip, ColorScheme colors) {
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
                  Icon(Icons.photo_library, color: colors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Trip Gallery',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'View and share photos from this trip',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    context.push('/gallery/album/${trip.galleryId}');
                  },
                  icon: const Icon(Icons.photo_library),
                  label: const Text('View Trip Gallery'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
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

    // ✅ Use optimistic state for immediate UI updates
    final optimisticState = ref.watch(optimisticRegistrationProvider);
    
    // Check if we have local optimistic updates for this trip
    final hasOptimisticRegistered = optimisticState.registeredTrips.containsKey(trip.id);
    final hasOptimisticWaitlisted = optimisticState.waitlistedTrips.containsKey(trip.id);
    
    // Use optimistic state if available, otherwise fall back to API state
    final isRegistered = hasOptimisticRegistered 
        ? (optimisticState.registeredTrips[trip.id] ?? false)
        : (trip.isRegistered ?? false);
    final isOnWaitlist = hasOptimisticWaitlisted
        ? (optimisticState.waitlistedTrips[trip.id] ?? false)
        : (trip.isWaitlisted ?? false);
    
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
                _handleShareTrip(context, trip);
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
    if (isRegistered) return 'Cancel Registration';  // Show action to unregister
    if (isOnWaitlist) return 'Leave Waitlist';  // Show action to leave waitlist
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
          'Cancel Registration',
          'Are you sure you want to cancel your registration for this trip?',
        );
        if (!confirmed) return;

        // ✅ Optimistically update UI immediately
        ref.read(optimisticRegistrationProvider.notifier).setRegistered(trip.id, false);

        await ref.read(tripActionsProvider.notifier).unregister(trip.id);
        
        // Refresh trip details to update UI state
        ref.invalidate(tripDetailProvider(trip.id));
        // Also refresh trips list to update counts
        await ref.read(tripsProvider.notifier).refresh();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Registration cancelled successfully'),
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

        // ✅ Optimistically update UI immediately
        ref.read(optimisticRegistrationProvider.notifier).setWaitlisted(trip.id, false);

        await ref.read(tripActionsProvider.notifier).unregister(trip.id);
        
        // Refresh trip details to update UI state
        ref.invalidate(tripDetailProvider(trip.id));
        // Also refresh trips list to update counts
        await ref.read(tripsProvider.notifier).refresh();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Left waitlist successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (isFull && hasWaitlist) {
        // Join waitlist
        // ✅ Optimistically update UI immediately
        ref.read(optimisticRegistrationProvider.notifier).setWaitlisted(trip.id, true);

        await ref.read(tripActionsProvider.notifier).joinWaitlist(trip.id);
        
        // Refresh trip details to update UI state
        ref.invalidate(tripDetailProvider(trip.id));
        // Also refresh trips list to update counts
        await ref.read(tripsProvider.notifier).refresh();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Joined waitlist successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (!isFull) {
        // Register for trip
        // TODO: Add vehicle capacity dialog if needed
        
        // ✅ Optimistically update UI immediately
        ref.read(optimisticRegistrationProvider.notifier).setRegistered(trip.id, true);

        await ref.read(tripActionsProvider.notifier).register(trip.id);
        
        // Refresh trip details to update UI state
        ref.invalidate(tripDetailProvider(trip.id));
        // Also refresh trips list to update counts
        await ref.read(tripsProvider.notifier).refresh();
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Successfully registered for trip!'),
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
    // Permission actions: 'approve_trip', 'edit_trips'
    if (currentUser.hasPermission('approve_trip') || 
        currentUser.hasPermission('edit_trips')) {
      return true;
    }
    
    return false;
  }

  /// Convert string approval status to enum
  /// Convert backend approval status code to enum
  /// ✅ FIXED: Backend returns "A", "P", "D" (single letters), not full words
  /// ✅ REMOVED: _getTripApprovalStatus() method
  /// TripAdminRibbon now accepts String status codes directly (A, P, D)
  /// No enum conversion needed - passes trip.approvalStatus directly

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
  Future<void> _handleEditTrip(BuildContext context, WidgetRef ref, dynamic trip) async {
    // Navigate to admin trip edit screen and await result
    final result = await context.push<bool>('/trips/${trip.id}/edit');
    
    // If edit was successful, invalidate the cache to reload fresh data
    if (result == true) {
      ref.invalidate(tripDetailProvider(trip.id));
    }
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
    // Show check-in dialog with registrants list
    showDialog(
      context: context,
      builder: (context) => _CheckinDialog(trip: trip, ref: ref),
    );
  }

  /// Handle export registrants action
  void _handleExportRegistrants(BuildContext context, dynamic trip) async {
    // Show export format selection dialog
    final format = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Registrants'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('CSV (Excel Compatible)'),
              subtitle: const Text('Comma-separated values'),
              onTap: () => Navigator.pop(context, 'csv'),
            ),
            ListTile(
              leading: const Icon(Icons.grid_on),
              title: const Text('Excel (XLSX)'),
              subtitle: const Text('Microsoft Excel format'),
              onTap: () => Navigator.pop(context, 'xlsx'),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('PDF'),
              subtitle: const Text('Portable Document Format'),
              onTap: () => Navigator.pop(context, 'pdf'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    
    if (format == null || !context.mounted) return;
    
    try {
      switch (format) {
        case 'csv':
          final csvData = TripExportService.exportToCSV(trip);
          final csvBytes = utf8.encode(csvData);
          await TripExportService.downloadFile(
            csvBytes, 
            'trip_${trip.id}_registrants.csv',
            'text/csv',
          );
          break;
        case 'xlsx':
          final xlsxBytes = await TripExportService.exportToExcel(trip);
          await TripExportService.downloadFile(
            xlsxBytes, 
            'trip_${trip.id}_registrants.xlsx',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          );
          break;
        case 'pdf':
          await TripExportService.exportToPDF(trip);
          break;
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Exported ${trip.registered.length} registrants as $format'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Handle bind gallery action (navigate to gallery if exists)
  void _handleBindGallery(BuildContext context, dynamic trip) {
    if (trip.galleryId != null) {
      // Navigate to existing gallery
      context.push('/gallery/album/${trip.galleryId}');
    } else {
      // Show message that gallery will be auto-created when trip is published
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gallery will be automatically created when trip is published'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle share trip
  void _handleShareTrip(BuildContext context, dynamic trip) {
    final shareText = '''
🚙 ${trip.title}

📅 ${DateFormat('MMM d, y').format(DateTime.parse(trip.date))}
📍 ${trip.location ?? 'Location TBD'}
👥 ${trip.registered?.length ?? 0} members registered

Join us for this exciting off-road adventure with AD4x4 Club!

View details: https://ap.ad4x4.com/trips/${trip.id}
''';

    Share.share(
      shareText,
      subject: 'AD4x4 Trip: ${trip.title}',
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
}  // End of TripDetailsScreen class

/// Stateful dialog for check-in management
class _CheckinDialog extends StatefulWidget {
  final dynamic trip;
  final WidgetRef ref;

  const _CheckinDialog({required this.trip, required this.ref});

  @override
  State<_CheckinDialog> createState() => _CheckinDialogState();
}

class _CheckinDialogState extends State<_CheckinDialog> {
  // Track check-in status changes locally
  final Map<int, String> _statusChanges = {};
  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Check-In: ${widget.trip.title}'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: widget.trip.registered.length,
                itemBuilder: (context, index) {
                  final registration = widget.trip.registered[index];
                  final currentStatus = _statusChanges[registration.member.id] ?? registration.status;
                  final isCheckedIn = currentStatus == 'checked_in' || currentStatus == 'checked_out';
                  
                  return CheckboxListTile(
                    title: Text(registration.member.displayName),
                    subtitle: Text(registration.member.username),
                    value: isCheckedIn,
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _statusChanges[registration.member.id] = 'checked_in';
                        } else {
                          _statusChanges[registration.member.id] = 'registered';
                        }
                      });
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveCheckInChanges,
          child: const Text('Save'),
        ),
      ],
    );
  }

  /// Save all check-in status changes
  Future<void> _saveCheckInChanges() async {
    if (_statusChanges.isEmpty) {
      Navigator.pop(context);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final repository = widget.ref.read(mainApiRepositoryProvider);
      int successCount = 0;
      int errorCount = 0;

      // Process each status change
      for (final entry in _statusChanges.entries) {
        final memberId = entry.key;
        final newStatus = entry.value;
        
        // Find original status
        final registration = widget.trip.registered.firstWhere(
          (r) => r.member.id == memberId,
          orElse: () => null,
        );
        
        if (registration == null) continue;
        final oldStatus = registration.status;

        try {
          // Only call API if status actually changed
          if (oldStatus != newStatus) {
            if (newStatus == 'checked_in' || newStatus == 'checked_out') {
              // Check in member
              await repository.checkinMember(widget.trip.id, memberId);
              successCount++;
            } else if (newStatus == 'registered') {
              // Check out member (back to registered)
              await repository.checkoutMember(widget.trip.id, memberId);
              successCount++;
            }
          }
        } catch (e) {
          print('Error updating check-in status for member $memberId: $e');
          errorCount++;
        }
      }

      if (mounted) {
        Navigator.pop(context);
        
        // Show result feedback
        if (errorCount == 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully updated check-in status for $successCount member(s)'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated $successCount member(s), $errorCount failed'),
              backgroundColor: Colors.orange,
            ),
          );
        }

        // Refresh trip details to show updated status
        widget.ref.read(tripsProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save check-in changes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}  // End of _CheckinDialogState class
