import 'package:flutter/material.dart';

/// Create Trip Screen - Under construction for Phase 3B
class CreateTripScreen extends StatelessWidget {
  final String? tripId;
  
  const CreateTripScreen({super.key, this.tripId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tripId == null ? 'Create Trip' : 'Edit Trip'),
      ),
      body: const Center(
        child: Text('Trip Creation - Under Development for Phase 3B'),
      ),
    );
  }
}
