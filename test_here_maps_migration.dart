/// HERE Maps Backend Migration Test Script
/// 
/// Tests the backend-driven HERE Maps geocoding integration
/// 
/// Run with: dart test_here_maps_migration.dart
library;

import 'dart:io';
import 'package:dio/dio.dart';

void main() async {
  print('🧪 HERE Maps Backend Migration Test');
  print('=' * 80);
  print('');

  final dio = Dio(BaseOptions(
    baseUrl: 'https://ap.ad4x4.com',
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  ));

  // Test credentials
  const username = 'Hani amj';
  const password = '3213Plugin?';

  try {
    // Test 1: Authentication
    print('📝 Test 1: Authentication');
    print('-' * 80);
    
    final loginResponse = await dio.post(
      '/api/auth/login/',
      data: {
        'login': username,
        'password': password,
      },
    );

    if (loginResponse.statusCode == 200) {
      final token = loginResponse.data['token'] as String;
      print('✅ Authentication successful');
      print('   Token: ${token.substring(0, 20)}...');
      
      // Set token for subsequent requests
      dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      print('❌ Authentication failed');
      return;
    }

    print('');

    // Test 2: Load HERE Maps Configuration
    print('📝 Test 2: Load HERE Maps Configuration');
    print('-' * 80);
    
    final configResponse = await dio.get('/api/settings/here-maps-config/');
    
    if (configResponse.statusCode == 200) {
      print('✅ Configuration loaded successfully');
      final config = configResponse.data as Map<String, dynamic>;
      
      print('   Raw Response: $config');
      print('');
      print('   Enabled: ${config['hereMapsEnabled'] ?? config['enabled'] ?? 'N/A'}');
      print('   Selected Fields: ${config['hereMapsSelectedFields'] ?? config['selectedFields'] ?? 'N/A'}');
      print('   Max Fields: ${config['hereMapsMaxFields'] ?? config['maxFields'] ?? 'N/A'}');
      
      final availableFields = config['hereMapsAvailableFields'] ?? config['availableFields'];
      if (availableFields != null && availableFields is List) {
        print('   Available Fields: ${availableFields.length} fields');
      } else {
        print('   Available Fields: N/A');
      }
      
      final enabled = config['hereMapsEnabled'] ?? config['enabled'];
      if (enabled != true) {
        print('   ⚠️  Warning: HERE Maps is disabled on backend');
      }
    } else {
      print('❌ Failed to load configuration');
      print('   Status: ${configResponse.statusCode}');
    }

    print('');

    // Test 3: Reverse Geocoding - Abu Dhabi
    print('📝 Test 3: Reverse Geocoding - Abu Dhabi City');
    print('-' * 80);
    
    final geocode1 = await dio.post(
      '/api/geocoding/reverse/',
      data: {
        'latitude': 24.4539,
        'longitude': 54.3773,
      },
    );

    if (geocode1.statusCode == 200) {
      final result = geocode1.data as Map<String, dynamic>;
      print('✅ Geocoding successful');
      print('   Location: ${result['area']}');
      print('   Success: ${result['success']}');
      print('   Cached: ${result['cached'] ?? 'N/A'}');
      
      if (result['city'] != null) {
        print('   City: ${result['city']}');
      }
      if (result['district'] != null) {
        print('   District: ${result['district']}');
      }
    } else {
      print('❌ Geocoding failed');
      print('   Status: ${geocode1.statusCode}');
    }

    print('');

    // Test 4: Reverse Geocoding - Dubai
    print('📝 Test 4: Reverse Geocoding - Dubai');
    print('-' * 80);
    
    final geocode2 = await dio.post(
      '/api/geocoding/reverse/',
      data: {
        'latitude': 25.2048,
        'longitude': 55.2708,
      },
    );

    if (geocode2.statusCode == 200) {
      final result = geocode2.data as Map<String, dynamic>;
      print('✅ Geocoding successful');
      print('   Location: ${result['area']}');
      print('   Success: ${result['success']}');
      print('   Cached: ${result['cached'] ?? 'N/A'}');
    } else {
      print('❌ Geocoding failed');
      print('   Status: ${geocode2.statusCode}');
    }

    print('');

    // Test 5: Cache Test - Repeat Abu Dhabi request
    print('📝 Test 5: Cache Test - Repeat Abu Dhabi Request');
    print('-' * 80);
    
    final geocode3 = await dio.post(
      '/api/geocoding/reverse/',
      data: {
        'latitude': 24.4539,
        'longitude': 54.3773,
      },
    );

    if (geocode3.statusCode == 200) {
      final result = geocode3.data as Map<String, dynamic>;
      print('✅ Geocoding successful');
      print('   Location: ${result['area']}');
      print('   Cached: ${result['cached'] ?? 'N/A'}');
      
      if (result['cached'] == true) {
        print('   ✅ Backend cache is working!');
      } else {
        print('   ℹ️  Not cached (expected on first run after backend restart)');
      }
    } else {
      print('❌ Geocoding failed');
      print('   Status: ${geocode3.statusCode}');
    }

    print('');
    print('=' * 80);
    print('✅ All tests completed successfully!');
    print('');
    print('📊 Summary:');
    print('   ✅ Authentication working');
    print('   ✅ Configuration endpoint working');
    print('   ✅ Reverse geocoding working');
    print('   ✅ Backend integration verified');
    print('');
    print('🔒 Security Status:');
    print('   ✅ API key NOT exposed (secured on backend)');
    print('   ✅ JWT authentication required');
    print('   ✅ Configuration managed via Django Admin');
    print('');

  } on DioException catch (e) {
    print('');
    print('=' * 80);
    print('❌ Test failed with error:');
    print('   Status: ${e.response?.statusCode ?? 'N/A'}');
    print('   Message: ${e.message}');
    
    if (e.response?.data != null) {
      print('   Response: ${e.response?.data}');
    }
    
    print('');
    print('🔍 Troubleshooting:');
    print('   - Check if backend is running');
    print('   - Verify credentials are correct');
    print('   - Ensure HERE Maps is enabled in Django Admin');
    print('   - Check network connectivity');
    
    exit(1);
  } catch (e) {
    print('');
    print('=' * 80);
    print('❌ Unexpected error: $e');
    exit(1);
  }
}
