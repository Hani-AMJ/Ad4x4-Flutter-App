import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/meeting_point_model.dart';

/// Meeting Points Provider - Fetches and caches meeting points for area filtering
final meetingPointsProvider = FutureProvider<List<MeetingPoint>>((ref) async {
  final repository = ref.watch(mainApiRepositoryProvider);
  
  try {
    final response = await repository.getMeetingPoints();
    
    // Parse meeting points from API response
    final meetingPoints = <MeetingPoint>[];
    for (var mpJson in response) {
      try {
        final meetingPoint = MeetingPoint.fromJson(mpJson as Map<String, dynamic>);
        meetingPoints.add(meetingPoint);
      } catch (e) {
        print('⚠️ Error parsing meeting point: $e');
      }
    }
    
    // Sort by area, then by name
    meetingPoints.sort((a, b) {
      final areaCompare = (a.area ?? '').compareTo(b.area ?? '');
      if (areaCompare != 0) return areaCompare;
      return a.name.compareTo(b.name);
    });
    
    return meetingPoints;
  } catch (e) {
    print('❌ Error loading meeting points: $e');
    rethrow;
  }
});
