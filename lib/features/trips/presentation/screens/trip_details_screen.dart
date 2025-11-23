import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:dio/dio.dart';
import '../providers/trips_provider.dart';
import '../../../../core/utils/text_utils.dart';
import '../../../../core/utils/level_display_helper.dart';
import '../../../../core/utils/status_helpers.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/services/trip_export_service.dart';
import '../../../../shared/widgets/admin/trip_status_badge.dart';
import '../../../../core/providers/repository_providers.dart';
import '../widgets/trip_logbook_section.dart';
import '../../../../data/models/trip_model.dart';

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
                // Admin gear icon (top-right)
                actions: [
                  if (_canAdminTrip(ref, trip))
                    Padding(
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
                        child: PopupMenuButton<String>(
                          icon: const Icon(Icons.settings, color: Colors.white),
                          iconSize: 24,
                          padding: EdgeInsets.zero,
                          offset: const Offset(0, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                _handleEditTrip(context, ref, trip);
                                break;
                              case 'registrants':
                                _handleManageRegistrants(context, trip);
                                break;
                              case 'checkin':
                                _handleCheckin(context, ref, trip);
                                break;
                              case 'export':
                                _handleExportRegistrants(context, trip);
                                break;
                              case 'gallery':
                                _handleBindGallery(context, trip);
                                break;
                              case 'approve':
                                _handleApproveTrip(context, ref, trip);
                                break;
                              case 'decline':
                                _handleDeclineTrip(context, ref, trip);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            // Regular admin actions
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit, color: Colors.blue, size: 20),
                                  SizedBox(width: 12),
                                  Text('Edit Trip'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'registrants',
                              child: Row(
                                children: [
                                  Icon(Icons.people, color: Colors.blue, size: 20),
                                  SizedBox(width: 12),
                                  Text('Manage Registrants'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'checkin',
                              child: Row(
                                children: [
                                  Icon(Icons.how_to_reg, color: Colors.orange, size: 20),
                                  SizedBox(width: 12),
                                  Text('Check-in Attendees'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'export',
                              child: Row(
                                children: [
                                  Icon(Icons.download, color: Colors.purple, size: 20),
                                  SizedBox(width: 12),
                                  Text('Export Registrants'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'gallery',
                              child: Row(
                                children: [
                                  Icon(Icons.photo_library, color: Colors.teal, size: 20),
                                  SizedBox(width: 12),
                                  Text('Bind Gallery'),
                                ],
                              ),
                            ),
                            // Conditional approval actions (only for pending trips)
                            if (isPending(trip.approvalStatus)) ...[
                              const PopupMenuDivider(),
                              const PopupMenuItem(
                                value: 'approve',
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                                    SizedBox(width: 12),
                                    Text('Approve Trip', style: TextStyle(color: Colors.green)),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'decline',
                                child: Row(
                                  children: [
                                    Icon(Icons.cancel, color: Colors.red, size: 20),
                                    SizedBox(width: 12),
                                    Text('Decline Trip', style: TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            ]
                          ],
                        ),
                      ),
                    ),
                ],
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
                      
                      // Status Badge (bottom-right overlay) - for admins only
                      if (_canAdminTrip(ref, trip))
                        TripStatusBadge(
                          approvalStatus: trip.approvalStatus,
                          position: BadgePosition.bottomRight,
                        ),
                    ],
                  ),
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

                    // Key Information Cards - ✅ FIXED: Each card now has unique color
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
                              customColor: const Color(0xFF1976D2), // Blue for dates
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
                              customColor: const Color(0xFF388E3C), // Green for capacity
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Trip Leadership (Lead + Deputy Marshals)
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

                    // Trip Report Section (for completed trips)
                    _buildTripReportSection(context, ref, trip, colors),

                    // Logbook Section (for marshals and attendees)
                    TripLogbookSection(
                      trip: trip.toJson(),
                      colors: colors,
                    ),

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
    ColorScheme colors, {
    Color? customColor,  // ✅ FIXED: Add custom color parameter
  }) {
    // ✅ FIXED: Use custom color if provided, otherwise use primary
    final iconColor = customColor ?? colors.primary;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: colors.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
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
              _buildLeaderCard(
                context,
                trip.lead,
                colors,
                isLead: true,
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
                      padding: const EdgeInsets.only(top: 12),
                      child: _buildLeaderCard(
                        context,
                        deputy,
                        colors,
                        isLead: false,
                      ),
                    )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeaderCard(
    BuildContext context,
    dynamic leader,
    ColorScheme colors, {
    required bool isLead,
  }) {
    final badgeColor = isLead ? Colors.green : Colors.blue;
    final badgeText = isLead ? 'TRIP LEAD' : 'DEPUTY';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar
        CircleAvatar(
          radius: 24,
          backgroundColor: isLead 
              ? colors.primary.withValues(alpha: 0.2)
              : Colors.blue.withValues(alpha: 0.2),
          child: Text(
            leader.firstName?.isNotEmpty == true
                ? leader.firstName![0].toUpperCase()
                : leader.username[0].toUpperCase(),
            style: TextStyle(
              color: isLead ? colors.primary : Colors.blue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Info Section
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name
              Text(
                leader.displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              
              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: badgeColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: badgeColor, width: 1),
                ),
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              
              // Details
              if (leader.level != null)
                Text(
                  'Level: ${leader.level}${leader.tripCount != null ? ' • ${leader.tripCount} trips' : ''}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              if (leader.carBrand != null && leader.carModel != null) ...[
                const SizedBox(height: 2),
                Text(
                  'Vehicle: ${leader.carBrand} ${leader.carModel}',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
        
        // Contact Icon Buttons (Right Side)
        if (leader.phone != null) ...[
          const SizedBox(width: 8),
          Column(
            children: [
              // Call Icon Button
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade700.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.phone),
                  color: Colors.green.shade700,
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () => _launchPhone(leader.phone!),
                  tooltip: 'Call',
                ),
              ),
              const SizedBox(height: 8),
              // WhatsApp Icon Button
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.chat),
                  color: const Color(0xFF25D366),
                  iconSize: 20,
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                  onPressed: () => _launchWhatsApp(leader.phone!),
                  tooltip: 'WhatsApp',
                ),
              ),
            ],
          ),
        ],
      ],
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
                  Icon(Icons.location_on, color: const Color(0xFFD32F2F)),  // ✅ Red for Location
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
                  Icon(Icons.event, color: const Color(0xFF7B1FA2)),  // ✅ Purple for Dates
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
                  Icon(Icons.description, color: const Color(0xFF0288D1)),  // ✅ Light Blue for Description
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
                  Icon(Icons.photo_library, color: const Color(0xFFE91E63)),  // ✅ Pink for Gallery
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
                  Icon(Icons.people, color: const Color(0xFF00796B)),  // ✅ Teal for Participants
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

  /// TODO: TRIP REPORTS FEATURE - UNDER DEVELOPMENT
  /// This section is temporarily disabled until feature development is complete.
  /// Uncomment the code below to re-enable trip report section on trip details page.
  /*
  Widget _buildTripReportSection(
    BuildContext context,
    WidgetRef ref,
    dynamic trip,
    ColorScheme colors,
  ) {
    final authState = ref.watch(authProviderV2);
    final currentUser = authState.user;
    
    // Check if trip is completed (approved + ended)
    final now = DateTime.now();
    final isCompleted = trip.approvalStatus == 'A' && now.isAfter(trip.endTime);
    
    // Check if user has permission to create trip reports
    final canCreateReport = currentUser?.hasPermission('create_trip_report') ?? false;
    
    // Fetch existing trip reports
    final reportsAsync = ref.watch(tripReportsByTripProvider(trip.id));
    
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
                    'Trip Report',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Show report content or creation button
              reportsAsync.when(
                data: (reports) {
                  if (reports.isEmpty) {
                    // No reports yet
                    if (isCompleted && canCreateReport) {
                      // Show create button for eligible users
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No trip report has been created yet.',
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
                                // Navigate to admin trip reports screen with trip ID pre-selected
                                context.push('/admin/trip-reports?tripId=${trip.id}');
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Create Trip Report'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else if (!isCompleted) {
                      // Trip not completed yet
                      return Text(
                        'Trip report will be available after the trip is completed.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    } else {
                      // User doesn't have permission
                      return Text(
                        'No trip report available yet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.onSurface.withValues(alpha: 0.6),
                        ),
                      );
                    }
                  } else {
                    // Show existing report preview
                    final report = reports.first; // Show most recent report
                    final parsed = report.parseStructuredReport();
                    final mainReport = parsed['mainReport'] as String? ?? '';
                    final preview = mainReport.length > 150
                        ? '${mainReport.substring(0, 150)}...'
                        : mainReport;
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Marshal info
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundImage: report.createdBy.profilePicture != null
                                  ? NetworkImage(report.createdBy.profilePicture!)
                                  : null,
                              child: report.createdBy.profilePicture == null
                                  ? Text(
                                      '${report.createdBy.firstName[0]}${report.createdBy.lastName[0]}',
                                      style: const TextStyle(fontSize: 12),
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    report.createdBy.displayName,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    DateFormat('MMM d, yyyy').format(report.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: colors.onSurface.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Report preview
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.surfaceContainerHighest.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            preview,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              color: colors.onSurface.withValues(alpha: 0.8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // View full report button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              // Navigate to admin trip reports screen
                              context.push('/admin/trip-reports');
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('View Full Report'),
                          ),
                        ),
                      ],
                    );
                  }
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => Text(
                  'Failed to load trip reports',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  */
  
  /// Placeholder method while trip reports feature is under development
  Widget _buildTripReportSection(
    BuildContext context,
    WidgetRef ref,
    dynamic trip,
    ColorScheme colors,
  ) {
    // Return empty widget - trip reports feature is hidden
    return const SizedBox.shrink();
  }

  Widget _buildActionButtons(
    BuildContext context,
    WidgetRef ref,
    dynamic trip,
    ColorScheme colors,
  ) {
    // Get current user
    final authState = ref.watch(authProviderV2);
    final user = authState.user;
    final currentUserId = user?.id ?? 0;

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

    // ✅ NEW: Compute trip eligibility status
    final now = DateTime.now();
    final isCompleted = now.isAfter(trip.endTime);
    final isCancelled = isDeclined(trip.approvalStatus);
    final isPendingStatus = isPending(trip.approvalStatus);
    final isPastCutoff = trip.cutOff != null && now.isAfter(trip.cutOff!);
    
    // ✅ NEW: Check user level eligibility
    final userLevel = user?.level?.numericLevel ?? 0;
    final requiredLevel = trip.level.numericLevel ?? 0;
    final hasInsufficientLevel = userLevel < requiredLevel && user != null;
    
    // ✅ NEW: Check if current user is the trip lead
    final isLead = trip.lead.id == currentUserId;

    // Watch trip actions state for loading
    final tripActionsState = ref.watch(tripActionsProvider);
    
    // ✅ NEW: Show lead status message instead of register button
    if (isLead) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.primaryContainer,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.star, color: colors.primary, size: 24),
              const SizedBox(width: 12),
              Text(
                'You are the trip lead',
                style: TextStyle(
                  color: colors.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // ✅ NEW: Show status message for completed trips
    if (isCompleted) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.check_circle, color: colors.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Text(
                'This trip has ended',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // ✅ NEW: Show status for cancelled trips
    if (isCancelled) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.errorContainer,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.cancel, color: colors.error),
              const SizedBox(width: 12),
              Text(
                'This trip has been cancelled',
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // ✅ NEW: Show status for pending approval
    if (isPendingStatus) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pending, color: colors.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Text(
                'Pending approval',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // ✅ NEW: Show status for past cutoff (if not already registered)
    if (isPastCutoff && !isRegistered && !isOnWaitlist) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: colors.surfaceContainerHighest,
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.schedule, color: colors.onSurface.withValues(alpha: 0.5)),
              const SizedBox(width: 12),
              Text(
                'Registration closed',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ✅ NEW: Show warning if user has insufficient level
        if (hasInsufficientLevel && !isRegistered && !isOnWaitlist)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: colors.errorContainer,
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: colors.onErrorContainer, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your level (${user?.level?.name ?? "Unknown"}) does not meet the requirement (${trip.level.name})',
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        
        // Registration button row
        Container(
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
                          // ✅ Disable button if user has insufficient level and not already registered
                          onPressed: (hasInsufficientLevel && !isRegistered && !isOnWaitlist)
                              ? null
                              : () => _handleRegistrationAction(
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
        ),
      ],
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
    // Get user info at the start for use in validation and error messages
    final authState = ref.read(authProviderV2);
    final user = authState.user;
    final now = DateTime.now();
    
    try {
      // ✅ CLIENT-SIDE PRE-VALIDATION: Check before making API calls
      if (!isRegistered && !isOnWaitlist) {
        
        // Check if trip has ended
        if (now.isAfter(trip.endTime)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot register: This trip has already ended.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        
        // Check if trip is cancelled
        if (isDeclined(trip.approvalStatus)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Cannot register: This trip has been cancelled.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        
        // Check if past cutoff time
        if (trip.cutOff != null && now.isAfter(trip.cutOff!)) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration has closed. The cutoff time has passed.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 4),
              ),
            );
          }
          return;
        }
        
        // Check user level eligibility
        if (user != null) {
          final userLevel = user.level?.numericLevel ?? 0;
          final requiredLevel = trip.level.numericLevel ?? 0;
          
          if (userLevel < requiredLevel) {
            final userLevelName = user.level?.name ?? 'Unknown';
            final requiredLevelName = trip.level.name ?? 'Unknown';
            
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Your skill level ($userLevelName) does not meet the requirement for this $requiredLevelName trip.',
                  ),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            }
            return;
          }
        }
      }
      
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
      // ✅ IMPROVED ERROR HANDLING: Parse backend 422 responses
      String errorMessage = 'Registration failed. Please try again.';
      
      // Parse DioException for detailed error messages
      if (e is DioException && e.response?.statusCode == 422) {
        try {
          final errorData = e.response?.data;
          
          // Backend sends error in various formats, handle both
          if (errorData is Map) {
            // Try to extract error message from common fields
            String? backendMessage;
            
            if (errorData['message'] != null) {
              backendMessage = errorData['message'] as String;
            } else if (errorData['error'] != null) {
              backendMessage = errorData['error'] as String;
            } else if (errorData['detail'] != null) {
              backendMessage = errorData['detail'] as String;
            }
            
            // Map backend error codes to user-friendly messages
            if (backendMessage != null) {
              switch (backendMessage.toLowerCase()) {
                case 'level_insufficient':
                case 'insufficient level':
                case 'user level is insufficient':
                  final userLevelName = user?.level?.name ?? 'Unknown';
                  final requiredLevelName = trip.level.name ?? 'Unknown';
                  errorMessage = 'Your skill level ($userLevelName) does not qualify you for this $requiredLevelName trip.';
                  break;
                  
                case 'trip_cutoff_exceeded':
                case 'cutoff exceeded':
                case 'registration cutoff has passed':
                  errorMessage = 'Registration has closed. The cutoff time has passed.';
                  break;
                  
                case 'trip is full':
                case 'trip_full':
                  errorMessage = 'This trip is now full. You may join the waitlist if available.';
                  break;
                  
                case 'trip has ended':
                case 'trip_ended':
                  errorMessage = 'Cannot register for a trip that has already ended.';
                  break;
                  
                case 'trip is cancelled':
                case 'trip_cancelled':
                  errorMessage = 'This trip has been cancelled.';
                  break;
                  
                case 'already registered':
                case 'already_registered':
                  errorMessage = 'You are already registered for this trip.';
                  break;
                  
                default:
                  // Use backend message if it's user-friendly
                  if (backendMessage.length < 100) {
                    errorMessage = backendMessage;
                  } else {
                    errorMessage = 'Registration failed: ${backendMessage.substring(0, 97)}...';
                  }
              }
            }
          }
        } catch (_) {
          // If parsing fails, use generic message
          errorMessage = 'Registration validation failed. Please check trip requirements.';
        }
      } else if (e is DioException) {
        // Handle other HTTP errors
        switch (e.response?.statusCode) {
          case 400:
            errorMessage = 'Invalid registration request. Please check your information.';
            break;
          case 401:
            errorMessage = 'Please log in to register for trips.';
            break;
          case 403:
            errorMessage = 'You do not have permission to register for this trip.';
            break;
          case 404:
            errorMessage = 'Trip not found. It may have been deleted.';
            break;
          case 500:
            errorMessage = 'Server error. Please try again later.';
            break;
          default:
            errorMessage = 'Network error. Please check your connection.';
        }
      } else {
        // Generic error fallback
        errorMessage = 'Unexpected error: ${e.toString()}';
      }
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
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

  Future<void> _launchWhatsApp(String phone) async {
    // Remove any non-numeric characters except +
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Try WhatsApp URI (works on both Android and iOS)
    final uri = Uri.parse('https://wa.me/$cleanPhone');
    
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
  void initState() {
    super.initState();
    if (kDebugMode) {
      debugPrint('🔍 [CheckIn Dialog] Opened for trip ID: ${widget.trip.id}');
      debugPrint('   Total registered members: ${widget.trip.registered.length}');
      for (var reg in widget.trip.registered) {
        debugPrint('   - ${reg.member.displayName} (ID: ${reg.member.id}): status="${reg.status}"');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Check-In: ${widget.trip.title} [v8.4-FIXED]'),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isSaving
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: widget.trip.registered.length,
                itemBuilder: (context, index) {
                  final registration = widget.trip.registered[index];
                  // Get current status from backend (registration.status) or local changes
                  final currentStatus = _statusChanges[registration.member.id] ?? registration.status;
                  // Checkbox is checked if member is checked_in, checked_out, or confirmed
                  final isCheckedIn = currentStatus == 'checked_in' || 
                                     currentStatus == 'checked_out' || 
                                     currentStatus == 'confirmed';
                  
                  // 🔍 DEBUG: Log member status for troubleshooting
                  if (kDebugMode) {
                    debugPrint('🔍 [CheckIn] Member: ${registration.member.displayName} (ID: ${registration.member.id})');
                    debugPrint('   Backend Status: ${registration.status}');
                    debugPrint('   Current Status: $currentStatus');
                    debugPrint('   isCheckedIn: $isCheckedIn');
                  }
                  
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
        TripRegistration? registration;
        try {
          registration = widget.trip.registered.firstWhere(
            (r) => r.member.id == memberId,
          );
        } catch (e) {
          // Member not found in registered list
          continue;
        }
        
        if (registration == null) continue;
        final oldStatus = registration.status;

        try {
          // Only call API if status actually changed
          if (oldStatus != newStatus) {
            if (kDebugMode) {
              debugPrint('💾 [CheckIn Save] Member ID: $memberId');
              debugPrint('   Old Status: $oldStatus → New Status: $newStatus');
            }
            
            if (newStatus == 'checked_in' || newStatus == 'checked_out') {
              // Check in member
              if (kDebugMode) debugPrint('   ✅ Calling checkinMember API');
              await repository.checkinMember(widget.trip.id, memberId);
              successCount++;
            } else if (newStatus == 'registered') {
              // Check out member (back to registered)
              if (kDebugMode) debugPrint('   ❌ Calling checkoutMember API');
              await repository.checkoutMember(widget.trip.id, memberId);
              successCount++;
            }
          } else {
            if (kDebugMode) {
              debugPrint('⏭️ [CheckIn Save] Member ID: $memberId - No change (status: $oldStatus)');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            debugPrint('❌ [CheckIn Save] Error for member $memberId: $e');
          }
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
        // Also invalidate the specific trip detail to force reload
        widget.ref.invalidate(tripDetailProvider(widget.trip.id));
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
