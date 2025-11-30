import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/providers/auth_provider_v2.dart';

/// App Shell with persistent bottom navigation
/// 
/// This widget wraps the main app screens and provides
/// persistent bottom navigation across all routes.
class AppShell extends ConsumerStatefulWidget {
  final Widget child;
  final GoRouterState state;

  const AppShell({
    super.key,
    required this.child,
    required this.state,
  });

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _selectedIndex = 0;

  @override
  void didUpdateWidget(AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateSelectedIndex();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateSelectedIndex();
  }

  /// Update selected index based on current route
  void _updateSelectedIndex() {
    final location = widget.state.matchedLocation;
    
    if (location == '/' || location == '/home') {
      _selectedIndex = 0;
    } else if (location.startsWith('/trips')) {
      _selectedIndex = 1;
    } else if (location.startsWith('/gallery')) {
      _selectedIndex = 2;
    } else if (location.startsWith('/logbook')) {
      _selectedIndex = 3;
    } else if (location.startsWith('/profile')) {
      _selectedIndex = 4;
    }
    
    // Update state if changed
    if (mounted) {
      setState(() {});
    }
  }

  void _onDestinationSelected(int index) {
    if (index == _selectedIndex) return; // Already on this tab
    
    setState(() => _selectedIndex = index);
    
    switch (index) {
      case 0:
        context.go('/');
        break;
      case 1:
        context.go('/trips');
        break;
      case 2:
        context.go('/gallery');
        break;
      case 3:
        context.go('/logbook');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Trips',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library),
            label: 'Gallery',
          ),
          NavigationDestination(
            icon: Icon(Icons.book_outlined),
            selectedIcon: Icon(Icons.book),
            label: 'Logbook',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
