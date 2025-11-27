import 'dart:typed_data';

/// Mobile stub - web utilities not needed on mobile
class CertificateWebUtils {
  /// Open PDF in new browser tab (stub for mobile)
  static void openPdfInNewTab(Uint8List pdfData) {
    throw UnsupportedError('openPdfInNewTab is only supported on web platform');
  }

  /// Download PDF file in browser (stub for mobile)
  static void downloadPdf(Uint8List pdfData, String filename) {
    throw UnsupportedError('downloadPdf is only supported on web platform');
  }
}
