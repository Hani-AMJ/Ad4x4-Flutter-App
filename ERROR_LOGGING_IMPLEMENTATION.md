## 📋 Error Logging System Implementation Guide

### Overview
This document describes the implementation of an **in-app error logging system** for AD4x4 Mobile App. This system captures all errors that occur during app usage and displays them in an accessible "Error Logs" screen, allowing you to debug issues without needing console access on Android/iOS devices.

---

## ✅ Files Created

### 1. Error Logging Service
**File:** `lib/core/services/error_log_service.dart`

**Purpose:** Core service that captures, stores, and manages error logs

**Features:**
- Automatic error capture
- Persistent storage (up to 100 errors)
- Error categorization (flutter_error, exception, network, custom)
- Export functionality
- Clear all logs

### 2. Error Logs Viewer Screen
**File:** `lib/features/settings/presentation/screens/error_logs_screen.dart`

**Purpose:** User interface for viewing and managing error logs

**Features:**
- List view of all errors
- Detailed error view with stack traces
- Filter by error type
- Copy error details
- Export logs for sharing
- Clear all logs
- Refresh on pull-down

---

## 🔧 Implementation Steps

### Step 1: Update main.dart

Add global error handlers and initialize the error logging service.

**File to modify:** `lib/main.dart`

**Add these imports at the top:**
```dart
import 'package:flutter/foundation.dart';
import 'core/services/error_log_service.dart';
```

**Add this code in the `main()` function, right after `WidgetsFlutterBinding.ensureInitialized();`:**

```dart
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ NEW: Initialize Error Logging Service
  final errorLogService = ErrorLogService();
  await errorLogService.init();
  
  // ✅ NEW: Set up global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    // Log to our service
    errorLogService.logError(
      message: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      type: 'flutter_error',
      context: details.context?.toString(),
    );
    
    // Also log to console in debug mode
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  
  // ✅ NEW: Catch errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogService.logError(
      message: error.toString(),
      stackTrace: stack.toString(),
      type: 'exception',
    );
    return true; // Handled
  };
  
  // ... rest of your existing main() code ...
}
```

**Full modified section example:**
```dart
void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ NEW: Initialize Error Logging Service
  final errorLogService = ErrorLogService();
  await errorLogService.init();
  
  // ✅ NEW: Set up global Flutter error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    errorLogService.logError(
      message: details.exception.toString(),
      stackTrace: details.stack?.toString(),
      type: 'flutter_error',
      context: details.context?.toString(),
    );
    
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  };
  
  // ✅ NEW: Catch errors outside Flutter framework
  PlatformDispatcher.instance.onError = (error, stack) {
    errorLogService.logError(
      message: error.toString(),
      stackTrace: stack.toString(),
      type: 'exception',
    );
    return true;
  };
  
  // Initialize Hive local storage
  try {
    await LocalStorage.init();
    developer.log('✅ Local storage initialized', name: 'Main');
  } catch (e) {
    developer.log('❌ Local storage initialization failed: $e', name: 'Main');
  }
  
  // ... rest of existing code continues ...
}
```

---

### Step 2: Add Route to Router

Add the error logs screen route to your app router.

**File to modify:** `lib/core/router/app_router.dart`

**Add import:**
```dart
import '../../features/settings/presentation/screens/error_logs_screen.dart';
```

**Add route in the routes list:**
```dart
GoRoute(
  path: '/settings/error-logs',
  builder: (context, state) => const ErrorLogsScreen(),
),
```

**Example placement (add after other settings routes):**
```dart
// Settings Routes
GoRoute(
  path: '/settings',
  builder: (context, state) => const SettingsScreen(),
),
GoRoute(
  path: '/settings/notifications',
  builder: (context, state) => const NotificationSettingsScreen(),
),
// ✅ NEW: Error Logs Route
GoRoute(
  path: '/settings/error-logs',
  builder: (context, state) => const ErrorLogsScreen(),
),
```

---

### Step 3: Add Menu Item in Settings Screen

Add "Error Logs" option in the Settings screen.

**File to modify:** `lib/features/settings/presentation/screens/settings_screen.dart`

**Add import at the top:**
```dart
import '../../../../core/services/error_log_service.dart';
```

**Add state variable to track error count:**
```dart
class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // ... existing variables ...
  
  // ✅ NEW: Error log count
  int _errorLogCount = 0;
  
  // ... rest of code ...
}
```

**Add method to load error count:**
```dart
Future<void> _loadErrorLogCount() async {
  final count = await ErrorLogService().getErrorCount();
  if (mounted) {
    setState(() => _errorLogCount = count);
  }
}
```

**Call this method in initState:**
```dart
@override
void initState() {
  super.initState();
  _initializeDeletionService();
  _loadNotificationSettings();
  _loadErrorLogCount(); // ✅ NEW
}
```

**Add the menu tile in the build method (add after "Delete Account" section):**
```dart
// ✅ NEW: Developer/Debug Section
_SectionHeader(title: 'Developer'),

_SettingsTile(
  icon: Icons.bug_report_outlined,
  title: 'Error Logs',
  subtitle: _errorLogCount > 0 
      ? '$_errorLogCount error${_errorLogCount == 1 ? '' : 's'} logged'
      : 'No errors logged',
  trailing: _errorLogCount > 0
      ? Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$_errorLogCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      : null,
  onTap: () async {
    await context.push('/settings/error-logs');
    // Refresh count when returning
    _loadErrorLogCount();
  },
),
```

---

### Step 4: Wrap Network Calls with Error Logging

Optionally enhance network error logging in your API client.

**File to modify:** `lib/core/network/api_client.dart`

**Add import:**
```dart
import '../services/error_log_service.dart';
```

**In the `_handleError` method, add logging:**
```dart
ApiException _handleError(DioException e) {
  // ✅ NEW: Log network errors
  ErrorLogService().logError(
    message: e.message ?? 'Network error',
    stackTrace: e.stackTrace?.toString(),
    type: 'network',
    context: e.requestOptions.path,
  );
  
  // ... rest of existing error handling code ...
}
```

---

## 🎯 Manual Error Logging (Optional)

You can manually log custom errors anywhere in your app:

```dart
import 'package:your_app/core/services/error_log_service.dart';

// Log a custom error
ErrorLogService().logError(
  message: 'Something went wrong in feature X',
  type: 'custom',
  context: 'FeatureXScreen',
);

// Log with stack trace
try {
  // Your code
} catch (e, stackTrace) {
  ErrorLogService().logError(
    message: e.toString(),
    stackTrace: stackTrace.toString(),
    type: 'exception',
    context: 'MyFeature',
  );
}
```

---

## 📱 User Experience

### Accessing Error Logs

1. **Open Settings** from navigation menu
2. **Scroll down** to "Developer" section
3. **Tap "Error Logs"**
   - Shows badge with error count if errors exist
   - Badge disappears when logs are cleared

### Error Logs Screen Features

**List View:**
- All errors sorted by timestamp (newest first)
- Color-coded by type (red for Flutter errors, orange for exceptions, etc.)
- Shows error message preview and timestamp
- Shows context (screen/feature) if available

**Filter Options:**
- All Errors
- Flutter Errors
- Exceptions
- Network Errors
- Custom Errors

**Actions:**
- **Tap error** → View full details with stack trace
- **Copy button** → Copy error details to clipboard
- **Share button** → Export all logs as text file
- **Delete button** → Clear all logs
- **Pull to refresh** → Reload logs

**Error Details Modal:**
- Full error message (selectable text)
- Complete stack trace (selectable text)
- Timestamp with date/time
- Error type and context
- Copy to clipboard button

---

## 🔍 Testing the Implementation

### Test 1: Trigger a Flutter Error
```dart
// In any screen, add a button that throws an error:
ElevatedButton(
  onPressed: () {
    throw FlutterError('Test Flutter Error');
  },
  child: const Text('Test Flutter Error'),
)
```

### Test 2: Trigger an Exception
```dart
ElevatedButton(
  onPressed: () {
    throw Exception('Test Exception');
  },
  child: const Text('Test Exception'),
)
```

### Test 3: Trigger a Network Error
- Turn off Wi-Fi/Data
- Try to login or load data
- Network errors should be logged

### Test 4: Manual Logging
```dart
ElevatedButton(
  onPressed: () {
    ErrorLogService().logError(
      message: 'This is a custom test error',
      type: 'custom',
      context: 'TestScreen',
    );
  },
  child: const Text('Log Custom Error'),
)
```

After triggering errors:
1. Go to Settings → Error Logs
2. Verify errors appear in the list
3. Tap an error to view details
4. Test copy, share, and clear functions

---

## 📊 Error Log Data Structure

Each error log contains:
- **timestamp**: ISO 8601 date/time
- **message**: Error description
- **stackTrace**: Full stack trace (if available)
- **type**: Category (flutter_error, exception, network, custom)
- **context**: Screen/feature name (if provided)

**Storage:**
- Stored in SharedPreferences
- Maximum 100 errors (oldest auto-deleted)
- Persists across app restarts
- User can manually clear anytime

---

## 🎨 UI Design

**Color Coding:**
- 🔴 **Flutter Errors**: Red
- 🟠 **Exceptions**: Orange
- 🔵 **Network Errors**: Blue
- 🟣 **Custom Errors**: Purple

**Icons:**
- Flutter Errors: `error_outline`
- Exceptions: `warning_amber_outlined`
- Network: `wifi_off_outlined`
- Custom: `bug_report_outlined`

---

## ✅ Benefits

1. **No Console Needed**: View errors directly on device
2. **Real-time Debugging**: See errors as they happen
3. **Share with Developers**: Export logs via email/messaging
4. **Production Debugging**: Catch issues in production builds
5. **Context Information**: Know exactly where errors occurred
6. **Persistent**: Errors saved even after app restart
7. **User-friendly**: Clean UI accessible from Settings

---

## 🚀 Next Steps After Implementation

1. **Build APK** with error logging enabled
2. **Install on test devices**
3. **Use the app normally**
4. **Check Settings → Error Logs** periodically
5. **Share logs** with development team for debugging

---

## 📝 Summary of Changes

**New Files (2):**
- `lib/core/services/error_log_service.dart`
- `lib/features/settings/presentation/screens/error_logs_screen.dart`

**Modified Files (3):**
- `lib/main.dart` - Add global error handlers
- `lib/core/router/app_router.dart` - Add error logs route
- `lib/features/settings/presentation/screens/settings_screen.dart` - Add menu item

**Total Lines Added:** ~600 lines
**Complexity:** Low-Medium
**Implementation Time:** ~30 minutes

---

## 🛠️ Troubleshooting

**Error logs not appearing?**
- Verify `ErrorLogService().init()` is called in main.dart
- Check Flutter error handlers are set up
- Ensure app has been rebuilt after changes

**Can't navigate to Error Logs screen?**
- Verify route is added to app_router.dart
- Check import statement is correct

**Badge not updating in Settings?**
- Call `_loadErrorLogCount()` when returning from Error Logs screen
- Use `setState()` after loading count

---

**Implementation Status:** ✅ Ready to Implement  
**Testing Status:** ⏳ Pending Implementation  
**Documentation:** ✅ Complete

This error logging system will significantly improve your ability to debug issues on production devices without needing console access!
