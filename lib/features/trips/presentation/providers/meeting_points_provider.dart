import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/meeting_point_constants.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/meeting_point_model.dart';

/// Meeting Points Provider - Fetches and caches meeting points for area filtering
final meetingPointsProvider = FutureProvider<List<MeetingPoint>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getMeetingPoints();
    
    // Parse meeting points from API response
    final results = response['results'] as List<dynamic>? ?? [];
    final meetingPoints = <MeetingPoint>[];
    for (var mpJson in results) {
      try {
        final meetingPoint = MeetingPoint.fromJson(mpJson as Map<String, dynamic>);
        meetingPoints.add(meetingPoint);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Error parsing meeting point: $e');
        }
      }
    }
    
    // Sort by area, then by name (using shared utility)
    meetingPoints.sort((a, b) => MeetingPointUtils.compareByAreaThenName(
          a,
          b,
          getArea: (mp) => (mp as MeetingPoint).area,
          getName: (mp) => (mp as MeetingPoint).name,
        ));
    
    return meetingPoints;
  } catch (e) {
    if (kDebugMode) {
      debugPrint('Error loading meeting points: $e');
    }
    rethrow;
  }
});
