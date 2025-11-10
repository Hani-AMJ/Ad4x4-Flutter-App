import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    final response = await http.get(
      Uri.parse('https://abudhabi-offroadclub.com/api/trips/6283'),
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      print('=== TRIP 6283 API RESPONSE ===');
      print(JsonEncoder.withIndent('  ').convert(data));
      
      // Check for null fields
      print('\n=== NULL FIELDS CHECK ===');
      void checkNulls(dynamic obj, String prefix) {
        if (obj is Map) {
          obj.forEach((key, value) {
            if (value == null) {
              print('$prefix$key: NULL');
            } else if (value is Map || value is List) {
              checkNulls(value, '$prefix$key.');
            }
          });
        } else if (obj is List) {
          for (var i = 0; i < obj.length; i++) {
            checkNulls(obj[i], '$prefix[$i].');
          }
        }
      }
      checkNulls(data, '');
      
    } else {
      print('Error: ${response.statusCode}');
      print(response.body);
    }
  } catch (e) {
    print('Exception: $e');
  }
}
