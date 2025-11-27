import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/certificate_model.dart';
import '../../../../data/repositories/main_api_repository.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../data/models/logbook_model.dart';
import '../../services/certificate_service.dart';

/// Certificate Provider
/// 
/// Manages skill verification certificates with generation and filtering
class CertificatesNotifier extends StateNotifier<AsyncValue<List<SkillCertificate>>> {
  final MainApiRepository _repository;
  final int memberId;
  final CertificateService _certificateService = CertificateService();
  CertificateFilter _filter = const CertificateFilter();

  CertificatesNotifier(this._repository, this.memberId) : super(const AsyncValue.loading()) {
    _loadCertificates();
  }

  CertificateFilter get filter => _filter;

  /// Load all certificates for member
  Future<void> _loadCertificates() async {
    state = const AsyncValue.loading();

    try {
      // Fetch skill references (verified skills) for the member
      final response = await _repository.getMemberLogbookSkills(
        memberId: memberId,
        page: 1,
        pageSize: 200,
      );
      
      final List<LogbookSkillReference> skillRefs = [];
      final data = response['results'] ?? response['data'] ?? response;

      if (data is List) {
        for (var item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              skillRefs.add(LogbookSkillReference.fromJson(item));
            } catch (e) {
              if (kDebugMode) {
                debugPrint('Failed to parse skill reference: $e');
              }
            }
          }
        }
      }

      // Generate certificates from skill references
      final certificates = await _generateCertificatesFromSkillReferences(skillRefs);

      state = AsyncValue.data(certificates);
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Error loading certificates: $e');
      }
      state = AsyncValue.error(e, stack);
    }
  }

  /// Generate certificates from skill references (verified skills)
  Future<List<SkillCertificate>> _generateCertificatesFromSkillReferences(
    List<LogbookSkillReference> skillRefs,
  ) async {
    if (skillRefs.isEmpty) return [];

    // Group skills by verification date (monthly certificates)
    final skillsByMonth = <String, List<CertifiedSkill>>{};
    
    for (var skillRef in skillRefs) {
      final monthKey = '${skillRef.verifiedAt.year}-${skillRef.verifiedAt.month.toString().padLeft(2, '0')}';
      
      final certifiedSkill = CertifiedSkill(
        skill: skillRef.logbookSkill,
        verifiedDate: skillRef.verifiedAt,
        verifiedBy: skillRef.verifiedBy,
        tripName: skillRef.trip?.title,
        tripId: skillRef.trip?.id,
        notes: skillRef.comment,
      );

      skillsByMonth.putIfAbsent(monthKey, () => []).add(certifiedSkill);
    }

    // Create certificates for each month
    final certificates = <SkillCertificate>[];
    final uuid = const Uuid();

    // Get member info from first skill reference
    final memberInfo = skillRefs.isNotEmpty 
        ? skillRefs.first.member 
        : MemberBasicInfo(
            id: memberId,
            firstName: 'Member',
            lastName: '#$memberId',
            level: null,
          );

    for (var entry in skillsByMonth.entries) {
      final skills = entry.value;
      if (skills.isEmpty) continue;

      // Calculate statistics
      final stats = _calculateStats(skills);
      
      // Use first day of month as issue date
      final parts = entry.key.split('-');
      final year = int.parse(parts[0]);
      final month = int.parse(parts[1]);
      final issueDate = DateTime(year, month, 1);

      certificates.add(SkillCertificate(
        certificateId: uuid.v4().substring(0, 8).toUpperCase(),
        member: memberInfo,
        skills: skills,
        issueDate: issueDate,
        clubName: 'Abu Dhabi Off-Road Club',
        clubLogo: 'https://ap.ad4x4.com/static/images/club-logo.png', // Club logo from backend
        stats: stats,
      ));
    }

    // Sort certificates by issue date (newest first)
    certificates.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return certificates;
  }

  /// Calculate certificate statistics
  /// UPDATED: Now uses dynamic level names instead of hard-coded numeric levels
  CertificateStats _calculateStats(List<CertifiedSkill> skills) {
    final levelCounts = <String, int>{}; // Changed to String keys for level names
    final signOffs = <int>{};
    final categories = <String>{};

    for (var skill in skills) {
      final levelName = skill.skill.level.name; // Use level name instead of numeric
      levelCounts[levelName] = (levelCounts[levelName] ?? 0) + 1;
      signOffs.add(skill.verifiedBy.id);
      
      // Derive category from skill name
      final category = _deriveSkillCategory(skill.skill.name);
      if (category != null) {
        categories.add(category);
      }
    }

    return CertificateStats(
      totalSkills: skills.length,
      skillsByLevel: levelCounts, // Dynamic level mapping
      uniqueSignOffs: signOffs.length,
      categories: categories.toList(),
    );
  }

  /// Derive skill category from skill name
  /// Smart categorization based on skill name keywords
  String? _deriveSkillCategory(String skillName) {
    final name = skillName.toLowerCase();
    
    // Driving skills
    if (name.contains('dune') || name.contains('sand') || name.contains('desert')) {
      return 'Dune Driving';
    }
    if (name.contains('rock') || name.contains('boulder') || name.contains('mountain')) {
      return 'Rock Crawling';
    }
    if (name.contains('mud') || name.contains('water') || name.contains('crossing')) {
      return 'Water/Mud Driving';
    }
    
    // Technical skills
    if (name.contains('recovery') || name.contains('winch') || name.contains('snatch')) {
      return 'Vehicle Recovery';
    }
    if (name.contains('maintenance') || name.contains('repair') || name.contains('mechanic')) {
      return 'Vehicle Maintenance';
    }
    if (name.contains('tire') || name.contains('tyre') || name.contains('deflation')) {
      return 'Tire Management';
    }
    
    // Navigation & Communication
    if (name.contains('navigation') || name.contains('gps') || name.contains('map')) {
      return 'Navigation';
    }
    if (name.contains('communication') || name.contains('radio') || name.contains('cb')) {
      return 'Communication';
    }
    
    // Safety & Leadership
    if (name.contains('safety') || name.contains('first aid') || name.contains('emergency')) {
      return 'Safety';
    }
    if (name.contains('convoy') || name.contains('marshal') || name.contains('leader')) {
      return 'Leadership';
    }
    if (name.contains('trip planning') || name.contains('route')) {
      return 'Trip Planning';
    }
    
    // Environmental
    if (name.contains('environment') || name.contains('tread lightly') || name.contains('eco')) {
      return 'Environmental';
    }
    
    // Default to general if no specific category matches
    return 'General Skills';
  }

  /// Update filter and apply
  Future<void> updateFilter(CertificateFilter newFilter) async {
    _filter = newFilter;
    await _applyFilter();
  }

  /// Reset filter
  Future<void> resetFilter() async {
    _filter = const CertificateFilter();
    await _loadCertificates();
  }

  /// Apply current filter to certificates
  Future<void> _applyFilter() async {
    state.whenData((allCertificates) {
      var filtered = List<SkillCertificate>.from(allCertificates);

      // Time range filter
      final startDate = _filter.timeRange.startDate;
      if (startDate != null) {
        filtered = filtered.where((cert) => cert.issueDate.isAfter(startDate)).toList();
      }

      // Recent filter
      if (_filter.onlyRecent) {
        filtered = filtered.where((cert) => cert.isRecent).toList();
      }

      // Level filter
      if (_filter.selectedLevelIds.isNotEmpty) {
        filtered = filtered.where((cert) {
          return cert.skills.any((skill) {
            return _filter.selectedLevelIds.contains(
              skill.skill.level.numericLevel,
            );
          });
        }).toList();
      }

      // Category filter - use derived categories
      if (_filter.selectedCategories.isNotEmpty) {
        filtered = filtered.where((cert) {
          // Check if certificate has skills in selected categories
          return cert.skills.any((skill) {
            final category = _deriveSkillCategory(skill.skill.name);
            return category != null && _filter.selectedCategories.contains(category);
          });
        }).toList();
      }

      state = AsyncValue.data(filtered);
    });
  }

  /// Refresh certificates
  Future<void> refresh() async {
    await _loadCertificates();
  }

  /// Generate certificate PDF (the slow part - PDF generation)
  Future<Uint8List> generateCertificatePDF(SkillCertificate certificate) async {
    return _certificateService.generateCertificatePDF(certificate);
  }

  /// Show preview with pre-generated PDF (fast - just display)
  Future<void> showPreview(SkillCertificate certificate, Uint8List pdfData) async {
    await _certificateService.showPreview(certificate, pdfData);
  }

  /// Show share sheet with pre-generated PDF (fast - just display)
  Future<void> showShare(SkillCertificate certificate, Uint8List pdfData) async {
    await _certificateService.showShare(certificate, pdfData);
  }

  /// Show print dialog with pre-generated PDF (fast - just display)
  Future<void> showPrint(SkillCertificate certificate, Uint8List pdfData) async {
    await _certificateService.showPrint(certificate, pdfData);
  }

  /// Generate certificate PDF (legacy method)
  Future<Uint8List> generatePDF(SkillCertificate certificate) async {
    return _certificateService.generateCertificatePDF(certificate);
  }

  /// Preview certificate (legacy method - slow, combines generation + display)
  Future<void> previewCertificate(SkillCertificate certificate) async {
    await _certificateService.previewCertificate(certificate);
  }

  /// Share certificate (legacy method - slow, combines generation + display)
  Future<void> shareCertificate(SkillCertificate certificate) async {
    await _certificateService.shareCertificate(certificate);
  }

  /// Print certificate (legacy method - slow, combines generation + display)
  Future<void> printCertificate(SkillCertificate certificate) async {
    await _certificateService.printCertificate(certificate);
  }
}

/// Provider for certificates
final certificatesProvider = StateNotifierProvider.family
    .autoDispose<CertificatesNotifier, AsyncValue<List<SkillCertificate>>, int>(
  (ref, memberId) {
    final repository = ref.watch(mainApiRepositoryProvider);
    return CertificatesNotifier(repository, memberId);
  },
);

/// Provider for filtered certificates count
final filteredCertificatesCountProvider = Provider.family.autoDispose<int, int>((ref, memberId) {
  final certificatesAsync = ref.watch(certificatesProvider(memberId));
  return certificatesAsync.maybeWhen(
    data: (certificates) => certificates.length,
    orElse: () => 0,
  );
});
