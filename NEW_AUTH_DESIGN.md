# 🔄 New Authentication System Design

## Goal
Build a **dead-simple, bulletproof** authentication system that:
1. Logs in reliably
2. **Logs out completely** (no auto-login)
3. Persists session across app restarts
4. Works on both web and mobile

## Architecture (Simplified)

### 1. Single Source of Truth: AuthService

```dart
class AuthService {
  // State
  String? _token;
  UserModel? _user;
  
  // Simple getters
  bool get isAuthenticated => _token != null && _user != null;
  UserModel? get currentUser => _user;
  
  // Login
  Future<bool> login(String username, String password) async {
    final response = await _api.login(username, password);
    _token = response['token'];
    _user = await _api.getProfile();
    await _saveToStorage();
    return true;
  }
  
  // Logout - AGGRESSIVE CLEARING
  Future<void> logout() async {
    _token = null;
    _user = null;
    await _clearAllStorage();
  }
  
  // Storage - ONE METHOD TO SAVE, ONE TO CLEAR
  Future<void> _saveToStorage() async {
    await _secureStorage.write(key: 'token', value: _token);
    // That's it. Simple.
  }
  
  Future<void> _clearAllStorage() async {
    // Nuclear option: Clear EVERYTHING
    await _secureStorage.deleteAll();
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await LocalStorage.clearAll();
    
    // Web platform: Clear browser storage
    if (kIsWeb) {
      // Use js package to call localStorage.clear()
      js.context.callMethod('eval', ['localStorage.clear()']);
      js.context.callMethod('eval', ['sessionStorage.clear()']);
    }
  }
  
  // Initialize - Try to restore session
  Future<void> initialize() async {
    final token = await _secureStorage.read(key: 'token');
    if (token != null) {
      _token = token;
      try {
        _user = await _api.getProfile();
      } catch (e) {
        // Token invalid, clear it
        await logout();
      }
    }
  }
}
```

### 2. Simple Riverpod Provider

```dart
class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthService _auth;
  
  AuthNotifier(this._auth) : super(const AsyncValue.loading()) {
    _init();
  }
  
  Future<void> _init() async {
    await _auth.initialize();
    state = AsyncValue.data(_auth.currentUser);
  }
  
  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      await _auth.login(username, password);
      state = AsyncValue.data(_auth.currentUser);
      return true;
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      return false;
    }
  }
  
  Future<void> logout() async {
    await _auth.logout();
    state = const AsyncValue.data(null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
  return AuthNotifier(AuthService());
});
```

### 3. Simple Router Redirect

```dart
redirect: (context, state) {
  final authState = ref.read(authProvider);
  final isLoggedIn = authState.value != null;
  final isLoginPage = state.matchedLocation == '/login';
  
  if (!isLoggedIn && !isLoginPage) {
    return '/login';
  }
  if (isLoggedIn && isLoginPage) {
    return '/';
  }
  return null;
}
```

## Key Simplifications

1. **No _hasInitialized flag** - Just check if _token exists
2. **No complex state copying** - Simple null checks
3. **No partial storage clearing** - Clear EVERYTHING on logout
4. **No browser storage detection** - Use JavaScript directly to clear
5. **Single responsibility** - AuthService does auth, nothing else

## Storage Strategy

### On Login:
- Save token to flutter_secure_storage ONLY
- That's it.

### On Logout:
- Clear secure storage completely (deleteAll)
- Clear SharedPreferences completely (clear)
- Clear Hive completely (clearAll)
- Clear browser localStorage (web only)
- Clear browser sessionStorage (web only)

**Philosophy:** On logout, DESTROY EVERYTHING. No selective clearing.

## Testing Strategy

1. Login → Check token saved
2. Logout → Check ALL storage empty
3. Refresh page → Should show login screen
4. Login again → Should work
5. Restart app → Should stay logged in
6. Logout → Restart → Should show login

## Risk Mitigation

### Backup Current Code
```bash
cp -r lib/core/services lib/core/services.backup
cp -r lib/core/providers lib/core/providers.backup
cp lib/core/router/app_router.dart lib/core/router/app_router.dart.backup
```

### Rollback Plan
If new auth breaks:
1. Stop development
2. Copy backup files back
3. Restart server
4. Continue debugging old approach

### Testing Checklist
- [ ] Login works (web)
- [ ] Login works (APK)
- [ ] Logout works (web)
- [ ] Logout works (APK)
- [ ] Session persists after refresh (web)
- [ ] Session persists after app restart (APK)
- [ ] No auto-login after logout (web)
- [ ] No auto-login after logout (APK)
- [ ] Multiple login/logout cycles work

## Implementation Plan

1. **Backup current files** (5 minutes)
2. **Rewrite AuthService** (15 minutes)
3. **Rewrite AuthProvider** (10 minutes)
4. **Update Router** (10 minutes)
5. **Update Login Screen** (5 minutes)
6. **Update Settings Screen** (5 minutes)
7. **Test thoroughly** (30 minutes)

**Total: ~1.5 hours** to completely rebuild auth system.

Compare to: Hours already spent debugging... ✅ Fresh start is faster!
