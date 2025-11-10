import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/auth_provider_v2.dart';

/// Debug screen to check authentication state (V2 - Clean Auth)
class AuthDebugScreen extends ConsumerStatefulWidget {
  const AuthDebugScreen({super.key});

  @override
  ConsumerState<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends ConsumerState<AuthDebugScreen> {
  String _debugInfo = 'Loading...';

  @override
  void initState() {
    super.initState();
    _loadDebugInfo();
  }

  Future<void> _loadDebugInfo() async {
    final buffer = StringBuffer();
    
    try {
      // Platform info
      buffer.writeln('=== PLATFORM INFO ===');
      buffer.writeln('Platform: ${kIsWeb ? "WEB" : "MOBILE"}');
      buffer.writeln('Storage: SharedPreferences (localStorage on web)');
      buffer.writeln('');
      
      // Check AuthProvider V2 state
      final authState = ref.read(authProviderV2);
      buffer.writeln('=== AUTH PROVIDER V2 STATE ===');
      buffer.writeln('isAuthenticated: ${authState.isAuthenticated}');
      buffer.writeln('isLoading: ${authState.isLoading}');
      buffer.writeln('error: ${authState.error ?? "NULL"}');
      buffer.writeln('currentUser: ${authState.user?.username ?? "NULL"}');
      if (authState.user != null) {
        buffer.writeln('user ID: ${authState.user!.id}');
        buffer.writeln('user email: ${authState.user!.email}');
        buffer.writeln('user level: ${authState.user!.level?.displayName ?? "N/A"}');
      }
      buffer.writeln('');

      // Check SharedPreferences (actual storage)
      buffer.writeln('=== SHARED PREFERENCES (localStorage) ===');
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      buffer.writeln('Total keys: ${keys.length}');
      buffer.writeln('Keys: ${keys.join(", ")}');
      
      // Show auth-related values
      final authToken = prefs.getString('auth_token');
      final userId = prefs.getString('user_id');
      final username = prefs.getString('username');
      buffer.writeln('');
      buffer.writeln('Auth-related keys:');
      buffer.writeln('  auth_token: ${authToken != null ? "EXISTS (${authToken.length} chars)" : "NULL"}');
      if (authToken != null && authToken.length > 50) {
        buffer.writeln('  token (first 50): ${authToken.substring(0, 50)}...');
      }
      buffer.writeln('  user_id: ${userId ?? "NULL"}');
      buffer.writeln('  username: ${username ?? "NULL"}');
      buffer.writeln('');

      // Diagnosis
      buffer.writeln('=== 🔍 DIAGNOSIS ===');
      final inMemory = authState.isAuthenticated;
      final inStorage = authToken != null;
      
      if (inMemory && inStorage) {
        buffer.writeln('✅ Everything looks good!');
        buffer.writeln('   Token in storage: YES');
        buffer.writeln('   Authenticated: YES');
        buffer.writeln('   State synchronized: YES');
      } else if (inStorage && !inMemory) {
        buffer.writeln('⚠️ TOKEN IN STORAGE BUT NOT AUTHENTICATED');
        buffer.writeln('   This might be an invalid/expired token');
        buffer.writeln('   AuthV2 initialization should handle this');
      } else if (inMemory && !inStorage) {
        buffer.writeln('❌ UNEXPECTED STATE!');
        buffer.writeln('   Authenticated but no token in storage');
        buffer.writeln('   This should not happen with V2');
      } else {
        buffer.writeln('✅ Not authenticated (as expected)');
        buffer.writeln('   No token in storage');
        buffer.writeln('   Not authenticated in provider');
      }
      
    } catch (e) {
      buffer.writeln('❌ ERROR: $e');
    }

    setState(() {
      _debugInfo = buffer.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auth Debug (V2)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDebugInfo,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  _debugInfo,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _debugInfo));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Debug info copied to clipboard')),
                      );
                    },
                    child: const Text('Copy to Clipboard'),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () async {
                      final prefs = await SharedPreferences.getInstance();
                      await prefs.clear();
                      await ref.read(authProviderV2.notifier).logout();
                      _loadDebugInfo();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Storage cleared and logged out')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: const Text('Clear All Storage & Logout'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
