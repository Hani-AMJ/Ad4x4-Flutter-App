import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/services/logbook_enrichment_service.dart';
import '../../../../data/models/logbook_model.dart';
import 'dart:convert';

/// Admin Export Data Screen
/// 
/// Allows exporting logbook data to CSV format
/// Supports different export types: entries, members, marshals
class AdminExportDataScreen extends ConsumerStatefulWidget {
  const AdminExportDataScreen({super.key});

  @override
  ConsumerState<AdminExportDataScreen> createState() => 
      _AdminExportDataScreenState();
}

class _AdminExportDataScreenState 
    extends ConsumerState<AdminExportDataScreen> {
  bool _isExporting = false;
  String? _exportedData;
  String _exportType = 'entries';
  
  // Date filters
  DateTime? _filterStartDate;
  DateTime? _filterEndDate;

  Future<void> _exportData() async {
    setState(() {
      _isExporting = true;
      _exportedData = null;
    });

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      
      // Load data based on export type
      if (_exportType == 'entries') {
        await _exportLogbookEntries(repository);
      } else if (_exportType == 'members') {
        await _exportMemberSkills(repository);
      } else if (_exportType == 'marshals') {
        await _exportMarshalActivity(repository);
      }
      
      setState(() {
        _isExporting = false;
      });
      
      if (_exportedData != null) {
        _showExportDialog();
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportLogbookEntries(dynamic repository) async {
    final entriesResponse = await repository.getLogbookEntries(pageSize: 500);
    final entriesResults = entriesResponse['results'] as List;
    var entries = entriesResults
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
    
    // ✨ ENRICH ENTRIES for export
    print('🔄 Export Logbook Entries: Enriching ${entries.length} entries...');
    final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
    entries = await enrichmentService.enrichLogbookEntries(entries);
    print('✅ Export Logbook Entries: Enrichment complete!');
    
    // Apply date filters
    if (_filterStartDate != null) {
      entries = entries.where((e) => 
        e.createdAt.isAfter(_filterStartDate!) ||
        e.createdAt.isAtSameMomentAs(_filterStartDate!)
      ).toList();
    }
    
    if (_filterEndDate != null) {
      final endOfDay = DateTime(
        _filterEndDate!.year,
        _filterEndDate!.month,
        _filterEndDate!.day,
        23, 59, 59,
      );
      entries = entries.where((e) => 
        e.createdAt.isBefore(endOfDay) ||
        e.createdAt.isAtSameMomentAs(endOfDay)
      ).toList();
    }
    
    // Generate CSV
    final csv = StringBuffer();
    csv.writeln('Entry ID,Member Name,Trip ID,Trip Title,Marshal Name,Skills Verified,Comment,Date Created');
    
    for (final entry in entries) {
      final entryId = entry.id;
      final memberName = entry.member.displayName;
      final tripId = entry.trip?.id ?? '';
      final tripTitle = entry.trip?.title ?? 'N/A';
      final marshalName = entry.signedBy.displayName;
      final skillsCount = entry.skillsVerified.length;
      final skillsNames = entry.skillsVerified.map((s) => s.name).join('; ');
      final comment = entry.comment ?? '';
      final dateCreated = DateFormat('yyyy-MM-dd HH:mm').format(entry.createdAt);
      
      csv.writeln('$entryId,"$memberName",$tripId,"$tripTitle","$marshalName",$skillsCount,"$skillsNames","$comment",$dateCreated');
    }
    
    setState(() {
      _exportedData = csv.toString();
    });
  }

  Future<void> _exportMemberSkills(dynamic repository) async {
    final entriesResponse = await repository.getLogbookEntries(pageSize: 500);
    final entriesResults = entriesResponse['results'] as List;
    var entries = entriesResults
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
    
    // ✨ ENRICH ENTRIES for member export
    print('🔄 Export Member Skills: Enriching ${entries.length} entries...');
    final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
    entries = await enrichmentService.enrichLogbookEntries(entries);
    print('✅ Export Member Skills: Enrichment complete!');
    
    // Group by member
    final memberStats = <int, Map<String, dynamic>>{};
    for (final entry in entries) {
      final memberId = entry.member.id;
      if (!memberStats.containsKey(memberId)) {
        memberStats[memberId] = {
          'name': entry.member.displayName,
          'level': entry.member.level?.name ?? 'Unspecified',
          'entries': 0,
          'skills': <int>{},
        };
      }
      
      memberStats[memberId]!['entries'] = 
          (memberStats[memberId]!['entries'] as int) + 1;
      
      for (final skill in entry.skillsVerified) {
        (memberStats[memberId]!['skills'] as Set<int>).add(skill.id);
      }
    }
    
    // Generate CSV
    final csv = StringBuffer();
    csv.writeln('Member ID,Member Name,Level,Total Entries,Unique Skills Verified');
    
    for (final entry in memberStats.entries) {
      final memberId = entry.key;
      final stats = entry.value;
      final name = stats['name'];
      final level = stats['level'];
      final entriesCount = stats['entries'];
      final skillsCount = (stats['skills'] as Set<int>).length;
      
      csv.writeln('$memberId,"$name","$level",$entriesCount,$skillsCount');
    }
    
    setState(() {
      _exportedData = csv.toString();
    });
  }

  Future<void> _exportMarshalActivity(dynamic repository) async {
    final entriesResponse = await repository.getLogbookEntries(pageSize: 500);
    final entriesResults = entriesResponse['results'] as List;
    var entries = entriesResults
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
    
    // ✨ ENRICH ENTRIES for marshal export
    print('🔄 Export Marshal Activity: Enriching ${entries.length} entries...');
    final enrichmentService = ref.read(logbookEnrichmentServiceProvider);
    entries = await enrichmentService.enrichLogbookEntries(entries);
    print('✅ Export Marshal Activity: Enrichment complete!');
    
    // Apply date filters
    if (_filterStartDate != null) {
      entries = entries.where((e) => 
        e.createdAt.isAfter(_filterStartDate!) ||
        e.createdAt.isAtSameMomentAs(_filterStartDate!)
      ).toList();
    }
    
    if (_filterEndDate != null) {
      final endOfDay = DateTime(
        _filterEndDate!.year,
        _filterEndDate!.month,
        _filterEndDate!.day,
        23, 59, 59,
      );
      entries = entries.where((e) => 
        e.createdAt.isBefore(endOfDay) ||
        e.createdAt.isAtSameMomentAs(endOfDay)
      ).toList();
    }
    
    // Group by marshal
    final marshalStats = <int, Map<String, dynamic>>{};
    for (final entry in entries) {
      final marshalId = entry.signedBy.id;
      if (!marshalStats.containsKey(marshalId)) {
        marshalStats[marshalId] = {
          'name': entry.signedBy.displayName,
          'entries': 0,
          'members': <int>{},
          'skills': 0,
          'lastActivity': entry.createdAt,
        };
      }
      
      marshalStats[marshalId]!['entries'] = 
          (marshalStats[marshalId]!['entries'] as int) + 1;
      
      (marshalStats[marshalId]!['members'] as Set<int>).add(entry.member.id);
      
      marshalStats[marshalId]!['skills'] = 
          (marshalStats[marshalId]!['skills'] as int) + entry.skillsVerified.length;
      
      final currentLast = marshalStats[marshalId]!['lastActivity'] as DateTime;
      if (entry.createdAt.isAfter(currentLast)) {
        marshalStats[marshalId]!['lastActivity'] = entry.createdAt;
      }
    }
    
    // Generate CSV
    final csv = StringBuffer();
    csv.writeln('Marshal ID,Marshal Name,Total Sign-Offs,Unique Members,Total Skills Verified,Avg Skills per Entry,Last Activity');
    
    for (final entry in marshalStats.entries) {
      final marshalId = entry.key;
      final stats = entry.value;
      final name = stats['name'];
      final entriesCount = stats['entries'] as int;
      final membersCount = (stats['members'] as Set<int>).length;
      final skillsCount = stats['skills'] as int;
      final avgSkills = entriesCount > 0 ? (skillsCount / entriesCount).toStringAsFixed(1) : '0';
      final lastActivity = DateFormat('yyyy-MM-dd').format(stats['lastActivity'] as DateTime);
      
      csv.writeln('$marshalId,"$name",$entriesCount,$membersCount,$skillsCount,$avgSkills,$lastActivity');
    }
    
    setState(() {
      _exportedData = csv.toString();
    });
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Data'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Data exported successfully!'),
            const SizedBox(height: 16),
            const Text('Copy the CSV data below:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Container(
              height: 300,
              width: double.maxFinite,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  _exportedData!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Copy this data and paste into Excel or a text editor.',
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Data'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              color: colors.primaryContainer.withValues(alpha: 0.3),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.download, color: colors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Export Logbook Data',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Export logbook data to CSV format. Select export type and date range, then click Export.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Export type selection
            Text(
              'Export Type',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Card(
              child: Column(
                children: [
                  RadioListTile<String>(
                    value: 'entries',
                    groupValue: _exportType,
                    onChanged: (value) {
                      setState(() => _exportType = value!);
                    },
                    title: const Text('Logbook Entries'),
                    subtitle: const Text('All logbook entries with details'),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'members',
                    groupValue: _exportType,
                    onChanged: (value) {
                      setState(() => _exportType = value!);
                    },
                    title: const Text('Member Skills Summary'),
                    subtitle: const Text('Member skills statistics'),
                  ),
                  const Divider(height: 1),
                  RadioListTile<String>(
                    value: 'marshals',
                    groupValue: _exportType,
                    onChanged: (value) {
                      setState(() => _exportType = value!);
                    },
                    title: const Text('Marshal Activity'),
                    subtitle: const Text('Marshal sign-off statistics'),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Date filters
            if (_exportType == 'entries' || _exportType == 'marshals') ...[
              Text(
                'Date Range (Optional)',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _filterStartDate ?? DateTime.now(),
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _filterStartDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _filterStartDate != null
                            ? DateFormat('MMM d, y').format(_filterStartDate!)
                            : 'From Date',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: _filterEndDate ?? DateTime.now(),
                          firstDate: _filterStartDate ?? DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (date != null) {
                          setState(() => _filterEndDate = date);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _filterEndDate != null
                            ? DateFormat('MMM d, y').format(_filterEndDate!)
                            : 'To Date',
                      ),
                    ),
                  ),
                ],
              ),
              
              if (_filterStartDate != null || _filterEndDate != null) ...[
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _filterStartDate = null;
                      _filterEndDate = null;
                    });
                  },
                  child: const Text('Clear Date Filters'),
                ),
              ],
              
              const SizedBox(height: 24),
            ],
            
            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _exportData,
                icon: _isExporting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download),
                label: Text(_isExporting ? 'Exporting...' : 'Export to CSV'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
