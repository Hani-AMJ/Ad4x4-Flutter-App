// ✅ CLEAN ACCOUNT DELETION IMPLEMENTATION
// This is how the feature SHOULD be written from scratch

/// Clean, robust account deletion button handler
Future<void> _handleDeleteAccountRequest(BuildContext context) async {
  // Step 1: Show confirmation dialog
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Account'),
      content: const Text(
        'Are you sure you want to delete your account? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  
  // User cancelled
  if (confirmed != true) return;
  if (!context.mounted) return;
  
  // Step 2: Show loading (using ScaffoldMessenger instead of Dialog to avoid pop issues)
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(width: 16),
          Text('Processing deletion request...'),
        ],
      ),
      duration: Duration(hours: 1), // Will be dismissed manually
    ),
  );
  
  try {
    // Step 3: Make API request
    final result = await _repository.requestAccountDeletion();
    
    // ALWAYS log for debugging (production-safe)
    print('🔍 [DeleteAccount] Backend response: $result');
    
    if (!context.mounted) return;
    
    // Dismiss loading
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Step 4: Handle response
    final success = result['success'] == true;
    final message = result['message']?.toString() ?? '';
    final isAlreadyExists = message.contains('already') || 
                           message == 'deletion_request_already_exists';
    
    if (success || isAlreadyExists) {
      // Update local state (optional, with error suppression)
      try {
        await _deletionService?.setDeletionRequested();
      } catch (e) {
        print('⚠️ [DeleteAccount] Failed to update local state: $e');
        // Continue anyway - backend state is source of truth
      }
      
      // Refresh UI safely
      if (context.mounted) {
        // Use addPostFrameCallback to ensure setState happens at safe time
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }
      
      // Show success message
      if (context.mounted) {
        final snackBarMessage = isAlreadyExists
            ? 'A deletion request is already active. You can cancel it below.'
            : 'Account deletion requested. Your account will be deleted in 30 days.';
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(snackBarMessage),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } else {
      // Handle error
      final errorMessage = message.isNotEmpty ? message : 'Unknown error occurred';
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to request deletion: $errorMessage'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  } catch (e, stackTrace) {
    // Step 5: Handle unexpected errors
    print('❌ [DeleteAccount] Unexpected error: $e');
    print('   Stack trace: $stackTrace');
    
    if (!context.mounted) return;
    
    // Dismiss loading
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    
    // Show error to user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unexpected error: ${e.toString()}'),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}

/// KEY IMPROVEMENTS:
/// 1. ✅ Single try-catch block - no nested confusion
/// 2. ✅ Uses SnackBar for loading instead of Dialog - no Navigator.pop issues
/// 3. ✅ Always checks context.mounted before UI operations
/// 4. ✅ Uses addPostFrameCallback for setState - safe timing
/// 5. ✅ Separates "already exists" from "success" logically
/// 6. ✅ Suppresses local state errors gracefully - backend is source of truth
/// 7. ✅ Production-safe logging (print instead of debugPrint)
/// 8. ✅ Captures stack traces for debugging
/// 9. ✅ Dismisses loading before showing result
/// 10. ✅ No kDebugMode checks - works same in debug/release
