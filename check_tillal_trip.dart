import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  try {
    // Get trips list
    print('=== FETCHING TRIPS LIST ===');
    final listResponse = await http.get(
      Uri.parse('https://abudhabi-offroadclub.com/api/trips/'),
    );
    
    if (listResponse.statusCode == 200) {
      final listData = jsonDecode(listResponse.body);
      
      // Find Tillal V2 trip
      final tillalTrip = (listData as List).firstWhere(
        (trip) => trip['title'].toString().toLowerCase().contains('tillal'),
        orElse: () => null,
      );
      
      if (tillalTrip != null) {
        print('\n=== TILLAL V2 TRIP (LIST ENDPOINT) ===');
        print('ID: ${tillalTrip['id']}');
        print('Title: ${tillalTrip['title']}');
        print('imageUrl: ${tillalTrip['image_url']}');
        print('image: ${tillalTrip['image']}');
        
        final tripId = tillalTrip['id'];
        
        // Get trip detail
        print('\n=== FETCHING TRIP DETAIL ===');
        final detailResponse = await http.get(
          Uri.parse('https://abudhabi-offroadclub.com/api/trips/$tripId'),
        );
        
        if (detailResponse.statusCode == 200) {
          final detailData = jsonDecode(detailResponse.body);
          print('\n=== TILLAL V2 TRIP (DETAIL ENDPOINT) ===');
          print('ID: ${detailData['id']}');
          print('Title: ${detailData['title']}');
          print('imageUrl: ${detailData['image_url']}');
          print('image: ${detailData['image']}');
        }
      } else {
        print('Tillal V2 trip not found');
      }
    }
  } catch (e) {
    print('Error: $e');
  }
}
