import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../data/models/member_level_stats.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../widgets/level_group_card.dart';

/// Members Landing Screen
/// 
/// Entry point for the Members section of the app.
/// Displays members grouped by level with statistics and search functionality.
/// 
/// Features:
/// - Search bar for finding members by name
/// - Level-grouped member cards showing member counts
/// - Dynamic level fetching from backend (not hardcoded)
/// - Tap on level card to view filtered member list
/// - Pull-to-refresh to update statistics
/// - Beautiful visual hierarchy with consistent colors
class MembersLandingScreen extends StatefulWidget {
  const MembersLandingScreen({super.key});

  @override
  State<MembersLandingScreen> createState() => _MembersLandingScreenState();
}

class _MembersLandingScreenState extends State<MembersLandingScreen> {
  final _repository = MainApiRepository();
  final _searchController = TextEditingController();
  
  List<MemberLevelStats> _levelStats = [];
  bool _isLoading = true;
  String? _error;
  int _totalMembers = 0;

  @override
  void initState() {
    super.initState();
    _loadLevelStatistics();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Load level statistics from API
  Future<void> _loadLevelStatistics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('📊 [MembersLanding] Loading level statistics...');
      
      final statsData = await _repository.getMemberLevelStatistics();
      final stats = statsData.map((data) => MemberLevelStats.fromJson(data)).toList();
      
      if (stats.isEmpty) {
        print('⚠️ [MembersLanding] No level statistics found');
        setState(() {
          _error = 'No members found. The database might be empty.';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _levelStats = stats;
        _totalMembers = stats.fold(0, (sum, stat) => sum + stat.memberCount);
        _isLoading = false;
      });
      
      print('✅ [MembersLanding] Loaded ${stats.length} level groups with $_totalMembers total members');
    } catch (e, stackTrace) {
      print('❌ [MembersLanding] Failed to load statistics: $e');
      print('❌ [MembersLanding] Stack trace: $stackTrace');
      
      // Provide more specific error message
      String errorMessage = 'Failed to load member statistics.';
      
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection')) {
        errorMessage = 'Connection error. Please check your internet connection and try again.';
      } else if (e.toString().contains('TimeoutException') || 
                 e.toString().contains('timeout')) {
        errorMessage = 'Request timeout. The server took too long to respond. Please try again.';
      } else if (e.toString().contains('401') || 
                 e.toString().contains('Unauthorized')) {
        errorMessage = 'Authentication error. Please log in and try again.';
      }
      
      setState(() {
        _error = errorMessage;
        _isLoading = false;
      });
    }
  }

  /// Navigate to filtered member list for a specific level
  void _navigateToLevelList(MemberLevelStats stats) {
    print('🔗 [MembersLanding] Navigating to level: ${stats.levelName}');
    context.push('/members/level/${stats.levelName}');
  }

  /// Navigate to search results
  void _navigateToSearch(String query) {
    if (query.trim().length >= 2) {
      print('🔍 [MembersLanding] Searching for: $query');
      context.push('/members/search?q=${Uri.encodeComponent(query.trim())}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least 2 characters to search'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Members'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar - Dark Theme Compatible
          Padding(
            padding: const EdgeInsets.all(16),
            child: Theme(
              data: Theme.of(context).copyWith(
                // Override textfield cursor and selection colors
                textSelectionTheme: TextSelectionThemeData(
                  cursorColor: Colors.blue[300],
                  selectionColor: Colors.blue.withValues(alpha: 0.3),
                  selectionHandleColor: Colors.blue[300],
                ),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                decoration: InputDecoration(
                  hintText: 'Search members by name...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 16,
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.blue[300]),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[400]),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey[700]!, width: 1.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[850],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                onChanged: (value) {
                  setState(() {}); // Update to show/hide clear button
                },
                onSubmitted: _navigateToSearch,
              ),
            ),
          ),
          
          // Statistics Header - Dark Theme Compatible
          if (!_isLoading && _error == null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              decoration: BoxDecoration(
                color: Colors.grey[850],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[700]!,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.people, color: Colors.grey[300], size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Total: $_totalMembers members',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[200],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: _loadLevelStatistics,
                    icon: Icon(Icons.refresh, color: Colors.grey[400], size: 20),
                    tooltip: 'Refresh',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          
          // Level Groups List
          Expanded(
            child: _isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading member statistics...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 64,
                                color: Colors.red[300],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadLevelStatistics,
                                icon: const Icon(Icons.refresh),
                                label: const Text('Retry'),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _levelStats.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey[400],
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No members found',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'There are no members in the system yet',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _loadLevelStatistics,
                            child: ListView.builder(
                              itemCount: _levelStats.length,
                              padding: const EdgeInsets.only(bottom: 16),
                              itemBuilder: (context, index) {
                                final stats = _levelStats[index];
                                return LevelGroupCard(
                                  stats: stats,
                                  onTap: () => _navigateToLevelList(stats),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}
