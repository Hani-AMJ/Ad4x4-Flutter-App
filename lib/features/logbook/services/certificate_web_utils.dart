import 'dart:html' as html;
import 'dart:typed_data';

/// Web-specific utilities for certificate PDF handling
class CertificateWebUtils {
  /// Open PDF in new browser tab
  static void openPdfInNewTab(Uint8List pdfData) {
    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.window.open(url, '_blank');
    html.Url.revokeObjectUrl(url);
  }

  /// Download PDF file in browser
  static void downloadPdf(Uint8List pdfData, String filename) {
    final blob = html.Blob([pdfData], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..click();
    html.Url.revokeObjectUrl(url);
  }
}
