import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import '../../../trips/presentation/widgets/skills_matrix_widget.dart';
import '../../../trips/presentation/widgets/member_logbook_history_widget.dart';
import '../../../trips/presentation/widgets/logbook_progress_chart_widget.dart';

/// Member Logbook Screen
/// 
/// Displays a member's complete logbook with:
/// - Skills matrix showing progression
/// - Logbook history with all entries
class MemberLogbookScreen extends ConsumerStatefulWidget {
  final int memberId;
  final String memberName;

  const MemberLogbookScreen({
    super.key,
    required this.memberId,
    required this.memberName,
  });

  @override
  ConsumerState<MemberLogbookScreen> createState() => _MemberLogbookScreenState();
}

class _MemberLogbookScreenState extends ConsumerState<MemberLogbookScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  bool _isLoadingSkills = false;
  List<Map<String, dynamic>> _allSkills = [];
  List<LogbookEntry> _logbookEntries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoadingSkills = true;
      _error = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load all skills for matrix
      final skillsResponse = await repository.getLogbookSkills(pageSize: 100);
      final skillsResults = skillsResponse['results'] as List;
      
      // Load member's logbook entries
      final entriesResponse = await repository.getLogbookEntries(
        memberId: widget.memberId,
        pageSize: 100,
      );
      final entriesResults = entriesResponse['results'] as List;
      final entries = entriesResults
          .map((json) {
            try {
              return LogbookEntry.fromJson(json as Map<String, dynamic>);
            } catch (e) {
              if (kDebugMode) {
                debugPrint('⚠️ Failed to parse logbook entry: $e');
              }
              return null;
            }
          })
          .whereType<LogbookEntry>()
          .toList();
      
      setState(() {
        _allSkills = skillsResults.cast<Map<String, dynamic>>();
        _logbookEntries = entries;
        _isLoadingSkills = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load logbook data: $e';
        _isLoadingSkills = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Logbook'),
            Text(
              widget.memberName,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colors.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_on),
              text: 'Skills Matrix',
            ),
            Tab(
              icon: Icon(Icons.history),
              text: 'History',
            ),
            Tab(
              icon: Icon(Icons.show_chart),
              text: 'Progress',
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(theme, colors),
    );
  }

  Widget _buildBody(ThemeData theme, ColorScheme colors) {
    if (_isLoadingSkills) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colors.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.error,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return TabBarView(
      controller: _tabController,
      children: [
        // Skills Matrix Tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SkillsMatrixWidget(
            logbookEntries: _logbookEntries,
            allSkills: _allSkills,
            colors: colors,
          ),
        ),
        
        // History Tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: MemberLogbookHistoryWidget(
            memberId: widget.memberId,
            memberName: widget.memberName,
            colors: colors,
          ),
        ),
        
        // Progress Tab
        SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: LogbookProgressChartWidget(
            logbookEntries: _logbookEntries,
            colors: colors,
          ),
        ),
      ],
    );
  }
}
