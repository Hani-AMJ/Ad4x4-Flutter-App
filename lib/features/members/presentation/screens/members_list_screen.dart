import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/widgets.dart';

class MembersListScreen extends StatefulWidget {
  const MembersListScreen({super.key});

  @override
  State<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends State<MembersListScreen> {
  final List<Map<String, dynamic>> _members = [
    {
      'id': '1',
      'name': 'Hani Al-Mansouri',
      'role': 'Marshal',
      'trips': 24,
      'avatar': null,
    },
    {
      'id': '2',
      'name': 'Ahmad Al-Mansoori',
      'role': 'Explorer',
      'trips': 18,
      'avatar': null,
    },
    {
      'id': '3',
      'name': 'Mohammed Al-Zaabi',
      'role': 'Advanced',
      'trips': 15,
      'avatar': null,
    },
    {
      'id': '4',
      'name': 'Khalid Al-Dhaheri',
      'role': 'Intermediate',
      'trips': 12,
      'avatar': null,
    },
    {
      'id': '5',
      'name': 'Saif Al-Ketbi',
      'role': 'Newbie',
      'trips': 5,
      'avatar': null,
    },
  ];

  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Search coming soon!')),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator(message: 'Loading members...')
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _members.length,
              itemBuilder: (context, index) {
                final member = _members[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: InfoCard(
                    icon: Icons.person,
                    title: member['name'],
                    subtitle: '${member['role']} • ${member['trips']} trips',
                    onTap: () => context.push('/members/${member['id']}'),
                  ),
                );
              },
            ),
    );
  }
}
