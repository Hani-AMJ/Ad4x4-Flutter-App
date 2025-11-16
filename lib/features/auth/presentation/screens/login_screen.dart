import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/providers/auth_provider_v2.dart'; // V2 - Clean implementation
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/animated_logo.dart';
import '../../../../core/network/api_client.dart'; // For ApiException

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // V2 - Clean auth implementation
      final loginFuture = ref.read(authProviderV2.notifier).login(
        login: _usernameController.text.trim(),
        password: _passwordController.text,
      );
      
      // Ensure minimum 800ms loading animation for better UX
      final delayFuture = Future.delayed(const Duration(milliseconds: 800));
      
      // Wait for both to complete
      final results = await Future.wait([loginFuture, delayFuture]);
      final success = results[0] as bool;

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        final user = ref.read(authProviderV2).user;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Welcome back, ${user?.displayName ?? "User"}!'),
              backgroundColor: Colors.green,
            ),
          );
          // Router will auto-redirect to home
        }
      } else {
        final error = ref.read(authProviderV2).error;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Login failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        
        // Check if this is a 503 Service Unavailable error
        String errorMessage;
        if (e is ApiException && e.statusCode == 503) {
          errorMessage = 'The server is under maintenance.';
        } else {
          errorMessage = 'An error occurred: $e';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // AD4X4 Club Logo with Pulsing Corona
                  const AnimatedLogo(
                    size: 140,
                  ),
                  const SizedBox(height: 16),

                  // Welcome Text
                  Text(
                    'Welcome Back',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to continue to AD4x4',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),

                  // Username/Email Field
                  CustomTextField(
                    label: 'Username or Email',
                    hint: 'Enter your username or email',
                    controller: _usernameController,
                    keyboardType: TextInputType.text,
                    prefixIcon: const Icon(Icons.person_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your username or email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  CustomTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passwordController,
                    obscureText: true,
                    prefixIcon: const Icon(Icons.lock_outlined),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push('/forgot-password'),
                      child: Text(
                        'Forgot Password?',
                        style: TextStyle(color: colors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  PrimaryButton(
                    text: 'Sign In',
                    onPressed: _handleLogin,
                    isLoading: _isLoading,
                    height: 56,
                  ),
                  const SizedBox(height: 24),

                  // Divider
                  Row(
                    children: [
                      Expanded(child: Divider(color: colors.outline)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'OR',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colors.onSurface.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: colors.outline)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  SecondaryButton(
                    text: 'Create Account',
                    onPressed: () => context.push('/register'),
                    height: 56,
                  ),
                  const SizedBox(height: 16),

                  // Terms Text
                  Text(
                    'By continuing, you agree to our Terms of Service and Privacy Policy',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onSurface.withValues(alpha: 0.5),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
