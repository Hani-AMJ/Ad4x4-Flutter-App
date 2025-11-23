import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../data/models/certificate_model.dart';
import '../../../core/services/level_configuration_service.dart';

/// Certificate Service
/// 
/// Handles PDF certificate generation, preview, and sharing
class CertificateService {
  static const String _clubName = 'Abu Dhabi Off-Road Club';
  static const String _clubWebsite = 'www.ad4x4.com';
  
  /// Generate PDF certificate for verified skills
  Future<Uint8List> generateCertificatePDF(SkillCertificate certificate) async {
    final pdf = pw.Document();

    // Load fonts for better appearance
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header with club branding
              _buildHeader(certificate, fontBold, fontRegular),
              pw.SizedBox(height: 30),

              // Certificate title
              _buildTitle(certificate, fontBold),
              pw.SizedBox(height: 20),

              // Member information
              _buildMemberInfo(certificate, fontRegular, fontBold),
              pw.SizedBox(height: 30),

              // Skills table
              _buildSkillsTable(certificate, fontRegular, fontBold),
              pw.SizedBox(height: 30),

              // Statistics
              _buildStatistics(certificate, fontRegular, fontBold),
              
              pw.Spacer(),

              // Footer
              _buildFooter(certificate, fontRegular, fontItalic),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generate multi-page detailed certificate with all skills
  Future<Uint8List> generateDetailedCertificatePDF(SkillCertificate certificate) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    // First page: Overview
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(certificate, fontBold, fontRegular),
            pw.SizedBox(height: 30),
            _buildTitle(certificate, fontBold),
            pw.SizedBox(height: 20),
            _buildMemberInfo(certificate, fontRegular, fontBold),
            pw.SizedBox(height: 30),
            _buildStatistics(certificate, fontRegular, fontBold),
            pw.Spacer(),
            _buildFooter(certificate, fontRegular, fontItalic),
          ],
        ),
      ),
    );

    // Subsequent pages: Detailed skills
    _addDetailedSkillsPages(pdf, certificate, fontRegular, fontBold, fontItalic);

    return pdf.save();
  }

  /// Build certificate header
  pw.Widget _buildHeader(
    SkillCertificate certificate,
    pw.Font fontBold,
    pw.Font fontRegular,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                _clubName,
                style: pw.TextStyle(
                  font: fontBold,
                  fontSize: 20,
                  color: PdfColors.blue900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Skill Verification Certificate',
                style: pw.TextStyle(
                  font: fontRegular,
                  fontSize: 12,
                  color: PdfColors.blue700,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue200,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              certificate.certificateId,
              style: pw.TextStyle(
                font: fontBold,
                fontSize: 10,
                color: PdfColors.blue900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build certificate title
  pw.Widget _buildTitle(SkillCertificate certificate, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 16),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.blue300, width: 2),
        ),
      ),
      child: pw.Text(
        'CERTIFICATE OF ACHIEVEMENT',
        style: pw.TextStyle(
          font: fontBold,
          fontSize: 24,
          color: PdfColors.blue900,
          letterSpacing: 2,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  /// Build member information section
  pw.Widget _buildMemberInfo(
    SkillCertificate certificate,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'This certifies that',
            style: pw.TextStyle(font: fontRegular, fontSize: 14),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            certificate.member.displayName,
            style: pw.TextStyle(
              font: fontBold,
              fontSize: 22,
              color: PdfColors.blue900,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Member Level: ${certificate.member.level ?? "Member"}',
            style: pw.TextStyle(font: fontRegular, fontSize: 12, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'has successfully demonstrated proficiency in the following off-road driving skills:',
            style: pw.TextStyle(font: fontRegular, fontSize: 12),
          ),
        ],
      ),
    );
  }

  /// Build skills table (summary version)
  pw.Widget _buildSkillsTable(
    SkillCertificate certificate,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    // Group skills by level
    final skillsByLevel = <String, List<CertifiedSkill>>{};
    for (var skill in certificate.skills) {
      final level = skill.skill.level.name;
      skillsByLevel.putIfAbsent(level, () => []).add(skill);
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.blue100),
          children: [
            _buildTableCell('Skill', fontBold, isHeader: true),
            _buildTableCell('Level', fontBold, isHeader: true),
            _buildTableCell('Verified Date', fontBold, isHeader: true),
          ],
        ),
        // Data rows (limited to first 15 skills for summary)
        ...certificate.skills.take(15).map((skill) {
          return pw.TableRow(
            children: [
              _buildTableCell(skill.skill.name, fontRegular),
              _buildTableCell(skill.skill.level.name, fontRegular),
              _buildTableCell(
                DateFormat('MMM d, yyyy').format(skill.verifiedDate),
                fontRegular,
              ),
            ],
          );
        }),
        // Show more indicator if needed
        if (certificate.skills.length > 15)
          pw.TableRow(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                child: pw.Text(
                  '+ ${certificate.skills.length - 15} more skills',
                  style: pw.TextStyle(
                    font: fontBold,
                    fontSize: 10,
                    color: PdfColors.blue700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ),
              pw.Container(),
              pw.Container(),
            ],
          ),
      ],
    );
  }

  /// Build table cell
  pw.Widget _buildTableCell(String text, pw.Font font, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 11 : 10,
          color: isHeader ? PdfColors.blue900 : PdfColors.black,
        ),
      ),
    );
  }

  /// Build statistics section
  pw.Widget _buildStatistics(
    SkillCertificate certificate,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    final stats = certificate.stats;
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Certification Summary',
            style: pw.TextStyle(font: fontBold, fontSize: 14, color: PdfColors.blue900),
          ),
          pw.SizedBox(height: 12),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total Skills', '${stats.totalSkills}', fontRegular, fontBold),
              _buildStatItem('Primary Level', stats.primaryLevel, fontRegular, fontBold),
              _buildStatItem('Verified By', '${stats.uniqueSignOffs} Marshal${stats.uniqueSignOffs > 1 ? 's' : ''}', fontRegular, fontBold),
            ],
          ),
          pw.SizedBox(height: 8),
          // Dynamic level stats - automatically adapt to all levels
          pw.Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: pw.WrapAlignment.spaceAround,
            children: stats.skillsByLevel.entries.map((entry) {
              // Clean level name (remove numeric suffixes)
              final cleanName = entry.key.replaceAll(RegExp(r'-+\d+$'), '');
              // Proper case capitalize first letter
              final displayName = cleanName.split(' ').map((w) {
                if (w.isEmpty) return w;
                return w[0].toUpperCase() + w.substring(1).toLowerCase();
              }).join(' ');
              return _buildStatItem(displayName, '${entry.value}', fontRegular, fontBold);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build statistics item
  pw.Widget _buildStatItem(String label, String value, pw.Font fontRegular, pw.Font fontBold) {
    return pw.Column(
      children: [
        pw.Text(
          value,
          style: pw.TextStyle(font: fontBold, fontSize: 16, color: PdfColors.blue900),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          label,
          style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey700),
        ),
      ],
    );
  }

  /// Build footer
  pw.Widget _buildFooter(
    SkillCertificate certificate,
    pw.Font fontRegular,
    pw.Font fontItalic,
  ) {
    return pw.Column(
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey300),
            ),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Issue Date:',
                    style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
                  ),
                  pw.Text(
                    DateFormat('MMMM d, yyyy').format(certificate.issueDate),
                    style: pw.TextStyle(font: fontRegular, fontSize: 10),
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    _clubName,
                    style: pw.TextStyle(font: fontRegular, fontSize: 10),
                  ),
                  pw.Text(
                    _clubWebsite,
                    style: pw.TextStyle(font: fontItalic, fontSize: 9, color: PdfColors.blue700),
                  ),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'This certificate is issued by $_clubName and certifies that the member has been verified '
          'by qualified marshals during club activities. Skills verification is subject to club standards '
          'and may be reviewed periodically.',
          style: pw.TextStyle(font: fontItalic, fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    );
  }

  /// Add detailed skills pages
  void _addDetailedSkillsPages(
    pw.Document pdf,
    SkillCertificate certificate,
    pw.Font fontRegular,
    pw.Font fontBold,
    pw.Font fontItalic,
  ) {
    // Group skills by level
    final skillsByLevel = <String, List<CertifiedSkill>>{};
    for (var skill in certificate.skills) {
      final level = skill.skill.level.name;
      skillsByLevel.putIfAbsent(level, () => []).add(skill);
    }

    // Create a page for each level with skills
    for (var entry in skillsByLevel.entries) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${entry.key} Skills',
                style: pw.TextStyle(font: fontBold, fontSize: 18, color: PdfColors.blue900),
              ),
              pw.SizedBox(height: 16),
              ...entry.value.map((skill) => _buildDetailedSkillItem(skill, fontRegular, fontBold)),
            ],
          ),
        ),
      );
    }
  }

  /// Build detailed skill item
  pw.Widget _buildDetailedSkillItem(
    CertifiedSkill skill,
    pw.Font fontRegular,
    pw.Font fontBold,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 16),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            skill.skill.name,
            style: pw.TextStyle(font: fontBold, fontSize: 12),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            children: [
              pw.Text(
                'Verified by: ',
                style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                skill.verifiedBy.displayName,
                style: pw.TextStyle(font: fontBold, fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Row(
            children: [
              pw.Text(
                'Date: ',
                style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
              ),
              pw.Text(
                DateFormat('MMM d, yyyy').format(skill.verifiedDate),
                style: pw.TextStyle(font: fontRegular, fontSize: 10),
              ),
            ],
          ),
          if (skill.tripName != null) ...[
            pw.SizedBox(height: 4),
            pw.Row(
              children: [
                pw.Text(
                  'Trip: ',
                  style: pw.TextStyle(font: fontRegular, fontSize: 10, color: PdfColors.grey700),
                ),
                pw.Text(
                  skill.tripName!,
                  style: pw.TextStyle(font: fontRegular, fontSize: 10),
                ),
              ],
            ),
          ],
          if (skill.notes != null && skill.notes!.isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.Text(
              skill.notes!,
              style: pw.TextStyle(font: fontRegular, fontSize: 9, color: PdfColors.grey600),
            ),
          ],
        ],
      ),
    );
  }

  /// Preview certificate PDF
  Future<void> previewCertificate(SkillCertificate certificate) async {
    final pdfData = await generateCertificatePDF(certificate);
    await Printing.layoutPdf(
      onLayout: (format) async => pdfData,
      name: 'Certificate_${certificate.member.displayName}_${certificate.certificateId}.pdf',
    );
  }

  /// Share certificate PDF
  Future<void> shareCertificate(SkillCertificate certificate) async {
    final pdfData = await generateCertificatePDF(certificate);
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'Certificate_${certificate.member.displayName}_${certificate.certificateId}.pdf',
    );
  }

  /// Download/Print certificate
  Future<void> printCertificate(SkillCertificate certificate) async {
    await Printing.layoutPdf(
      onLayout: (format) async => await generateCertificatePDF(certificate),
      name: 'Certificate_${certificate.member.displayName}_${certificate.certificateId}.pdf',
    );
  }
}
