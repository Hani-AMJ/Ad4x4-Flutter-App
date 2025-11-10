/// Text Utilities
/// 
/// Helper functions for text manipulation and formatting
class TextUtils {
  /// Strip HTML tags and convert to plain text with line breaks
  /// 
  /// Handles:
  /// - Removes all HTML tags (<p>, <strong>, etc.)
  /// - Converts HTML entities (&nbsp;, &amp;, etc.)
  /// - Normalizes line breaks
  /// - Removes excessive whitespace
  /// - Handles null/empty input gracefully
  /// 
  /// Example:
  /// ```dart
  /// String html = '<p>Hello <strong>World</strong></p>';
  /// String plain = TextUtils.stripHtmlTags(html);
  /// // Result: 'Hello World'
  /// ```
  static String stripHtmlTags(String? htmlString) {
    // Handle null or empty input
    if (htmlString == null || htmlString.isEmpty) {
      return '';
    }

    try {
      String text = htmlString;

      // Remove HTML tags (including attributes)
      text = text.replaceAll(RegExp(r'<[^>]*>'), '');

      // Convert common HTML entities to characters
      final entities = {
        '&nbsp;': ' ',
        '&amp;': '&',
        '&lt;': '<',
        '&gt;': '>',
        '&quot;': '"',
        '&#39;': "'",
        '&#x27;': "'",
        '&apos;': "'",
        '&hellip;': '...',
        '&mdash;': '—',
        '&ndash;': '–',
        '&bull;': '•',
      };

      entities.forEach((entity, char) {
        text = text.replaceAll(entity, char);
      });

      // Normalize line breaks
      text = text
          .replaceAll(RegExp(r'\r\n'), '\n')      // Windows line breaks
          .replaceAll(RegExp(r'\r'), '\n')        // Old Mac line breaks
          .replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n'); // Remove excessive blank lines

      // Trim whitespace from start and end
      text = text.trim();

      return text;
    } catch (e) {
      // If any error occurs during stripping, return original or empty
      print('⚠️ Error stripping HTML: $e');
      return htmlString.replaceAll(RegExp(r'<[^>]*>'), '').trim();
    }
  }

  /// Truncate text to a specific length with ellipsis
  static String truncate(String text, int maxLength, {String ellipsis = '...'}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}$ellipsis';
  }

  /// Format phone number for display
  /// Example: "+971502260867" → "+971 50 226 0867"
  static String formatPhoneNumber(String? phone) {
    if (phone == null || phone.isEmpty) return '';
    
    try {
      // Remove all non-digit characters except +
      String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
      
      // UAE phone number format: +971 50 226 0867
      if (cleaned.startsWith('+971') && cleaned.length == 13) {
        return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 6)} ${cleaned.substring(6, 9)} ${cleaned.substring(9)}';
      }
      
      // Return original if not UAE format
      return phone;
    } catch (e) {
      return phone;
    }
  }

  /// Capitalize first letter of each word
  static String capitalizeWords(String? text) {
    if (text == null || text.isEmpty) return '';
    
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  /// Check if string contains HTML tags
  static bool containsHtml(String? text) {
    if (text == null || text.isEmpty) return false;
    return RegExp(r'<[^>]*>').hasMatch(text);
  }
}
