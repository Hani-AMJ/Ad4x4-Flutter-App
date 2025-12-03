import 'package:csv/csv.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as excel;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/trip_model.dart';

/// Service for exporting trip registrants data
/// Supports CSV, Excel (XLSX), and PDF formats
class TripExportService {
  /// Export registrants to CSV format
  static String exportToCSV(Trip trip) {
    final List<List<dynamic>> rows = [];
    
    // Header row
    rows.add([
      'Name',
      'Username',
      'Member ID',
      'Phone',
      'Email',
      'Vehicle',
      'Registration Date',
      'Status',
      'Has Vehicle',
      'Vehicle Capacity',
      'Check-in Status',
    ]);
    
    // Data rows
    for (final registration in trip.registered) {
      final member = registration.member;
      rows.add([
        member.displayName,
        member.username,
        member.id,
        member.phone ?? 'N/A',
        member.email ?? 'N/A',
        '${member.carBrand ?? ''} ${member.carModel ?? ''}'.trim().isEmpty 
            ? 'N/A' 
            : '${member.carBrand ?? ''} ${member.carModel ?? ''}'.trim(),
        DateFormat('yyyy-MM-dd HH:mm').format(registration.registrationDate),
        registration.status ?? 'confirmed',
        registration.hasVehicle ?? false,
        registration.vehicleCapacity ?? 'N/A',
        (registration.status == 'checked_in' || registration.status == 'checked_out') ? 'Checked In' : 'Not Checked In',
      ]);
    }
    
    return const ListToCsvConverter().convert(rows);
  }
  
  /// Export registrants to Excel format
  static Future<List<int>> exportToExcel(Trip trip) async {
    // Create a new Excel document
    final excel.Workbook workbook = excel.Workbook();
    final excel.Worksheet sheet = workbook.worksheets[0];
    
    // Set sheet name
    sheet.name = 'Registrants';
    
    // Apply header style
    final excel.Style headerStyle = workbook.styles.add('HeaderStyle');
    headerStyle.bold = true;
    headerStyle.backColor = '#4CAF50';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.hAlign = excel.HAlignType.center;
    headerStyle.vAlign = excel.VAlignType.center;
    
    // Write header
    sheet.getRangeByIndex(1, 1).setText('Name');
    sheet.getRangeByIndex(1, 2).setText('Username');
    sheet.getRangeByIndex(1, 3).setText('Member ID');
    sheet.getRangeByIndex(1, 4).setText('Phone');
    sheet.getRangeByIndex(1, 5).setText('Email');
    sheet.getRangeByIndex(1, 6).setText('Vehicle');
    sheet.getRangeByIndex(1, 7).setText('Registration Date');
    sheet.getRangeByIndex(1, 8).setText('Status');
    sheet.getRangeByIndex(1, 9).setText('Has Vehicle');
    sheet.getRangeByIndex(1, 10).setText('Vehicle Capacity');
    sheet.getRangeByIndex(1, 11).setText('Check-in Status');
    
    // Apply header style
    for (int col = 1; col <= 11; col++) {
      sheet.getRangeByIndex(1, col).cellStyle = headerStyle;
    }
    
    // Write data
    int rowIndex = 2;
    for (final registration in trip.registered) {
      final member = registration.member;
      
      sheet.getRangeByIndex(rowIndex, 1).setText(member.displayName);
      sheet.getRangeByIndex(rowIndex, 2).setText(member.username);
      sheet.getRangeByIndex(rowIndex, 3).setNumber(member.id.toDouble());
      sheet.getRangeByIndex(rowIndex, 4).setText(member.phone ?? 'N/A');
      sheet.getRangeByIndex(rowIndex, 5).setText(member.email ?? 'N/A');
      
      final vehicle = '${member.carBrand ?? ''} ${member.carModel ?? ''}'.trim();
      sheet.getRangeByIndex(rowIndex, 6).setText(vehicle.isEmpty ? 'N/A' : vehicle);
      
      sheet.getRangeByIndex(rowIndex, 7).setText(
        DateFormat('yyyy-MM-dd HH:mm').format(registration.registrationDate)
      );
      sheet.getRangeByIndex(rowIndex, 8).setText(registration.status ?? 'confirmed');
      sheet.getRangeByIndex(rowIndex, 9).setText(registration.hasVehicle ?? false ? 'Yes' : 'No');
      sheet.getRangeByIndex(rowIndex, 10).setText(registration.vehicleCapacity?.toString() ?? 'N/A');
      sheet.getRangeByIndex(rowIndex, 11).setText(
        (registration.status == 'checked_in' || registration.status == 'checked_out') ? 'Checked In' : 'Not Checked In'
      );
      
      rowIndex++;
    }
    
    // Auto-fit columns
    for (int col = 1; col <= 11; col++) {
      sheet.autoFitColumn(col);
    }
    
    // Save workbook
    final List<int> bytes = workbook.saveAsStream();
    workbook.dispose();
    
    return bytes;
  }
  
  /// Export registrants to PDF format
  static Future<Uint8List> exportToPDF(Trip trip) async {
    final pdf = pw.Document();
    
    // Create table data
    final List<List<String>> tableData = [];
    
    // Header
    tableData.add([
      'Name',
      'Phone',
      'Vehicle',
      'Reg. Date',
      'Status',
      'Check-in',
    ]);
    
    // Data rows
    for (final registration in trip.registered) {
      final member = registration.member;
      tableData.add([
        member.displayName,
        member.phone ?? 'N/A',
        '${member.carBrand ?? ''} ${member.carModel ?? ''}'.trim().isEmpty 
            ? 'N/A' 
            : '${member.carBrand ?? ''} ${member.carModel ?? ''}'.trim(),
        DateFormat('MMM dd, yyyy').format(registration.registrationDate),
        registration.status ?? 'confirmed',
        (registration.status == 'checked_in' || registration.status == 'checked_out') ? '✓' : '✗',
      ]);
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          // Title
          pw.Header(
            level: 0,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Trip Registrants',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  trip.title,
                  style: const pw.TextStyle(fontSize: 16),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Date: ${DateFormat('MMMM dd, yyyy').format(trip.startTime)}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Total Registrants: ${trip.registered.length}',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Divider(thickness: 2),
              ],
            ),
          ),
          
          pw.SizedBox(height: 20),
          
          // Table
          pw.Table.fromTextArray(
            headers: tableData.first,
            data: tableData.skip(1).toList(),
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.grey300,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellHeight: 25,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerLeft,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
              5: pw.Alignment.center,
            },
          ),
          
          pw.SizedBox(height: 20),
          
          // Footer with generation info
          pw.Text(
            'Generated on: ${DateFormat('MMMM dd, yyyy \'at\' hh:mm a').format(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
        ],
      ),
    );
    
    return pdf.save();
  }
  
  /// Download file for web platform
  static Future<void> downloadFile(
    List<int> bytes,
    String filename,
    String mimeType,
  ) async {
    if (kIsWeb) {
      // For web platform, use printing package's save method
      // which handles file download automatically
      if (mimeType == 'application/pdf') {
        await Printing.layoutPdf(
          onLayout: (format) async => Uint8List.fromList(bytes),
        );
      } else {
        // For CSV and Excel, we'll use the HTML download method
        // This is handled in the UI layer using the web package
        // The bytes are passed back to the UI
      }
    } else {
      // For mobile platforms, we would use path_provider and file system
      // Not implemented for this phase as we're focusing on web
      throw UnimplementedError('Mobile platform export not implemented');
    }
  }
}
