import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/widgets.dart';

class VehiclesListScreen extends StatelessWidget {
  const VehiclesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    // TODO: Fetch actual vehicle data
    final vehicles = [
      {
        'id': '1',
        'make': 'Toyota',
        'model': 'Land Cruiser',
        'year': '2023',
        'plateNumber': 'AD 12345',
      },
      {
        'id': '2',
        'make': 'Nissan',
        'model': 'Patrol',
        'year': '2022',
        'plateNumber': 'AD 67890',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vehicles'),
      ),
      body: vehicles.isEmpty
          ? EmptyState(
              icon: Icons.garage,
              title: 'No Vehicles',
              message: 'Add your first vehicle to get started',
              actionText: 'Add Vehicle',
              onAction: () => context.push('/vehicles/add'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = vehicles[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: colors.primary.withValues(alpha: 0.2),
                        child: Icon(Icons.directions_car, color: colors.primary),
                      ),
                      title: Text('${vehicle['make']} ${vehicle['model']}'),
                      subtitle: Text('${vehicle['year']} • ${vehicle['plateNumber']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {
                          _showVehicleOptions(context, vehicle);
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/vehicles/add'),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Add Vehicle'),
      ),
    );
  }

  void _showVehicleOptions(BuildContext context, Map<String, dynamic> vehicle) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Vehicle'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Edit coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Vehicle', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, vehicle);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, Map<String, dynamic> vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Vehicle'),
        content: Text('Are you sure you want to delete ${vehicle['make']} ${vehicle['model']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vehicle deleted')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
