import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/here_maps_service.dart';

/// Provider for Here Maps Service
final hereMapsServiceProvider = Provider<HereMapsService>((ref) {
  return HereMapsService();
});
