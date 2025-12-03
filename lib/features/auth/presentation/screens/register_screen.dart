import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/gender_provider.dart';
import '../../../../core/providers/car_brand_provider.dart';
import '../../../../core/providers/emirate_provider.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/providers/validator_provider.dart';
import '../../../../core/utils/password_validator.dart';
import '../../../../shared/widgets/widgets.dart';
import '../../../../shared/widgets/animated_logo.dart';
import '../../../../shared/widgets/password_strength_indicator.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Account Info
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  // Personal Info
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _cityController = TextEditingController();
  final _nationalityController = TextEditingController();
  
  // Vehicle Info
  final _carBrandController = TextEditingController();
  final _carModelController = TextEditingController();
  final _carColorController = TextEditingController();
  final _carYearController = TextEditingController();
  
  // Emergency Contact
  final _iceNameController = TextEditingController();
  final _icePhoneController = TextEditingController();
  
  // State
  bool _isLoading = false;
  bool _agreedToTerms = false;
  String? _selectedGender;
  String? _selectedCity;
  String? _selectedNationality;
  DateTime? _selectedDob;
  File? _avatarImage;
  Uint8List? _avatarImageBytes; // For web platform
  String? _avatarUrl;
  bool _isUploadingAvatar = false;
  
  // Section expansion state
  bool _showVehicleInfo = false;
  bool _showEmergencyContact = false;
  
  // Services
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    // Account Info
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    
    // Personal Info
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _cityController.dispose();
    _nationalityController.dispose();
    
    // Vehicle Info
    _carBrandController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    _carYearController.dispose();
    
    // Emergency Contact
    _iceNameController.dispose();
    _icePhoneController.dispose();
    
    super.dispose();
  }

  Future<void> _pickAndCropAvatar() async {
    try {
      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // For web platform, use image picker without cropper (cropper doesn't work well on web)
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _avatarImageBytes = bytes;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Avatar selected! It will be uploaded when you complete registration.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // For mobile platforms, use cropper
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Avatar',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Avatar',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile == null) return;

      // Set the avatar image (will be uploaded during registration)
      setState(() {
        _avatarImage = File(croppedFile.path);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar selected! It will be uploaded when you complete registration.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _uploadAvatar() async {
    try {
      Uint8List bytes;
      
      // Get bytes from web or mobile
      if (kIsWeb) {
        if (_avatarImageBytes == null) return null;
        bytes = _avatarImageBytes!;
      } else {
        if (_avatarImage == null) return null;
        bytes = await _avatarImage!.readAsBytes();
      }
      
      // Convert to base64 for upload
      final base64Image = 'data:image/jpeg;base64,${base64Encode(bytes)}';
      return base64Image;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to encode avatar: $e');
      }
      return null;
    }
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();
    final initialDate = _selectedDob ?? DateTime(now.year - 25, now.month, now.day);
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1940),
      lastDate: now,
      helpText: 'Select Date of Birth',
    );
    
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to Terms of Service'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Call registration API through auth provider
    final authProvider = ref.read(authProviderV2.notifier);
    final success = await authProvider.register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
      phone: _phoneController.text.trim(),
      // Optional fields
      dob: _dobController.text.isNotEmpty ? _dobController.text : null,
      gender: _selectedGender,
      city: _cityController.text.trim().isNotEmpty ? _cityController.text.trim() : null,
      nationality: _nationalityController.text.trim().isNotEmpty ? _nationalityController.text.trim() : null,
      carBrand: _carBrandController.text.trim().isNotEmpty ? _carBrandController.text.trim() : null,
      carModel: _carModelController.text.trim().isNotEmpty ? _carModelController.text.trim() : null,
      carColor: _carColorController.text.trim().isNotEmpty ? _carColorController.text.trim() : null,
      carYear: _carYearController.text.trim().isNotEmpty ? int.tryParse(_carYearController.text.trim()) : null,
      iceName: _iceNameController.text.trim().isNotEmpty ? _iceNameController.text.trim() : null,
      icePhone: _icePhoneController.text.trim().isNotEmpty ? _icePhoneController.text.trim() : null,
      avatar: (_avatarImage != null || _avatarImageBytes != null) ? await _uploadAvatar() : null, // Upload avatar during registration
    );

    if (mounted) {
      setState(() => _isLoading = false);
      
      if (success) {
        // Show success and navigate to login
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful! Please sign in.'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/login');
      } else {
        // Error is already set in auth provider state
        final error = ref.read(authProviderV2).error;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error ?? 'Registration failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // List of all countries
  // Removed hardcoded countries list - now using dynamic countryChoicesProvider

  Widget _buildNationalitySearchField(ThemeData theme, ColorScheme colors) {
    return Consumer(
      builder: (context, ref, _) {
        final countriesAsync = ref.watch(countryChoicesProvider);
        
        return countriesAsync.when(
          data: (countries) {
            // Create map for value-to-label lookup
            final countryMap = {for (var c in countries) c.value: c.label};
            final countryLabels = countries.map((c) => c.label).toList();
            
            return Autocomplete<String>(
              optionsBuilder: (TextEditingValue textEditingValue) {
                if (textEditingValue.text.isEmpty) {
                  return const Iterable<String>.empty();
                }
                return countryLabels.where((String option) {
                  return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                });
              },
              onSelected: (String selection) {
                // Find country value from label
                final selectedCountry = countries.firstWhere((c) => c.label == selection);
                setState(() {
                  _selectedNationality = selectedCountry.value;
                  _nationalityController.text = selection;
                });
              },
              fieldViewBuilder: (BuildContext context, TextEditingController textEditingController,
                  FocusNode focusNode, VoidCallback onFieldSubmitted) {
                if (_selectedNationality != null && textEditingController.text.isEmpty) {
                  // Display label from value
                  final country = countries.firstWhere(
                    (c) => c.value == _selectedNationality,
                    orElse: () => countries.first,
                  );
                  textEditingController.text = country.label;
                }
                return TextFormField(
                  controller: textEditingController,
                  focusNode: focusNode,
                  decoration: InputDecoration(
                    labelText: 'Nationality',
                    hintText: 'Search for your country',
                    prefixIcon: const Icon(Icons.flag_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onFieldSubmitted: (String value) {
                    onFieldSubmitted();
                  },
                );
              },
            );
          },
          loading: () => TextFormField(
            controller: _nationalityController,
            decoration: InputDecoration(
              labelText: 'Nationality',
              hintText: 'Loading countries...',
              prefixIcon: const Icon(Icons.flag_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            enabled: false,
          ),
          error: (e, s) => TextFormField(
            controller: _nationalityController,
            decoration: InputDecoration(
              labelText: 'Nationality',
              hintText: 'Enter your nationality',
              prefixIcon: const Icon(Icons.flag_outlined),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build username field with live validation
  Widget _buildUsernameField(ThemeData theme, ColorScheme colors) {
    final usernameValidation = ref.watch(usernameValidationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Username',
          hint: 'Choose a unique username',
          controller: _usernameController,
          prefixIcon: const Icon(Icons.account_circle_outlined),
          onChanged: (value) {
            // Trigger live validation with debouncing
            ref.read(usernameValidationProvider.notifier).validate(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a username';
            }
            if (value.length < 3) {
              return 'Username must be at least 3 characters';
            }
            if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
              return 'Username can only contain letters, numbers, and underscores';
            }
            // Check live validation result
            if (usernameValidation.isInvalid) {
              return usernameValidation.result!.error;
            }
            return null;
          },
        ),
        // Live validation feedback
        if (usernameValidation.isValidating)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking availability...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else if (usernameValidation.isValid && _usernameController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (usernameValidation.isInvalid && _usernameController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                Icon(Icons.cancel, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    usernameValidation.result!.error,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build email field with live validation
  Widget _buildEmailField(ThemeData theme, ColorScheme colors) {
    final emailValidation = ref.watch(emailValidationProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Email',
          hint: 'Enter your email',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          prefixIcon: const Icon(Icons.email_outlined),
          onChanged: (value) {
            // Trigger live validation with debouncing
            ref.read(emailValidationProvider.notifier).validate(value);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your email';
            }
            if (!value.contains('@')) {
              return 'Please enter a valid email';
            }
            // Check live validation result
            if (emailValidation.isInvalid) {
              return emailValidation.result!.error;
            }
            return null;
          },
        ),
        // Live validation feedback
        if (emailValidation.isValidating)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(strokeWidth: 2, color: colors.primary),
                ),
                const SizedBox(width: 8),
                Text(
                  'Checking availability...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else if (emailValidation.isValid && _emailController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: Colors.green),
                const SizedBox(width: 8),
                Text(
                  'Available',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )
        else if (emailValidation.isInvalid && _emailController.text.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 12),
            child: Row(
              children: [
                Icon(Icons.cancel, size: 16, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    emailValidation.result!.error,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  /// Build password field with strength indicator
  Widget _buildPasswordField(ThemeData theme, ColorScheme colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Password',
          hint: 'Enter your password',
          controller: _passwordController,
          obscureText: true,
          prefixIcon: const Icon(Icons.lock_outlined),
          onChanged: (value) {
            // Trigger rebuild to update password strength indicator
            setState(() {});
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter a password';
            }
            // Use PasswordValidator for comprehensive validation
            final errors = PasswordValidator.validate(
              value,
              username: _usernameController.text,
              email: _emailController.text,
            );
            if (errors.isNotEmpty) {
              return 'Password does not meet requirements';
            }
            return null;
          },
        ),
        // Password strength indicator
        PasswordStrengthIndicator(
          password: _passwordController.text,
          username: _usernameController.text,
          email: _emailController.text,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // AD4X4 Club Logo with Pulsing Corona
                const AnimatedLogo(
                  size: 100,
                ),
                const SizedBox(height: 16),

                // Header
                Text(
                  'Create Account',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Join the AD4x4 community',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Avatar Picker
                Center(
                  child: Stack(
                    children: [
                      // Avatar Display
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.surfaceContainerHighest,
                          border: Border.all(
                            color: colors.primary,
                            width: 3,
                          ),
                        ),
                        child: ClipOval(
                          child: _avatarImageBytes != null
                              ? Image.memory(
                                  _avatarImageBytes!,
                                  fit: BoxFit.cover,
                                  width: 120,
                                  height: 120,
                                )
                              : _avatarImage != null
                                  ? Image.file(
                                      _avatarImage!,
                                      fit: BoxFit.cover,
                                      width: 120,
                                      height: 120,
                                    )
                                  : Icon(
                                      Icons.person,
                                      size: 60,
                                      color: colors.onSurfaceVariant,
                                    ),
                        ),
                      ),
                      // Upload/Loading Indicator
                      if (_isUploadingAvatar)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black54,
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      // Camera Button
                      if (!_isUploadingAvatar)
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickAndCropAvatar,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.primary,
                                border: Border.all(
                                  color: colors.surface,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: colors.onPrimary,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Profile Picture',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withValues(alpha: 0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // === ACCOUNT INFORMATION ===
                Text(
                  'Account Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // Username with live validation
                _buildUsernameField(theme, colors),
                const SizedBox(height: 20),

                // Email with live validation
                _buildEmailField(theme, colors),
                const SizedBox(height: 20),

                // Password with strength indicator
                _buildPasswordField(theme, colors),
                const SizedBox(height: 20),

                // Confirm Password
                CustomTextField(
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  controller: _confirmPasswordController,
                  obscureText: true,
                  prefixIcon: const Icon(Icons.lock_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // === PERSONAL INFORMATION ===
                Text(
                  'Personal Information',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 16),

                // First Name
                CustomTextField(
                  label: 'First Name',
                  hint: 'Enter your first name',
                  controller: _firstNameController,
                  prefixIcon: const Icon(Icons.person_outlined),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Last Name
                CustomTextField(
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  controller: _lastNameController,
                  prefixIcon: const Icon(Icons.person_outlined),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  prefixIcon: const Icon(Icons.phone_outlined),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Date of Birth (Optional)
                TextFormField(
                  controller: _dobController,
                  decoration: InputDecoration(
                    labelText: 'Date of Birth',
                    hintText: 'Select your date of birth',
                    prefixIcon: const Icon(Icons.cake_outlined),
                    suffixIcon: const Icon(Icons.calendar_today),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  readOnly: true,
                  onTap: _selectDateOfBirth,
                ),
                const SizedBox(height: 20),

                // Gender (Optional) - Dynamic from backend
                Consumer(
                  builder: (context, ref, _) {
                    final gendersAsync = ref.watch(genderChoicesProvider);
                    return gendersAsync.when(
                      data: (genders) => DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender (Optional)',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: genders.map((gender) => DropdownMenuItem(
                          value: gender.value,
                          child: Text(gender.label),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      loading: () => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Gender (Optional)',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                          DropdownMenuItem(value: 'prefer_not_say', child: Text('Prefer not to say')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                      error: (e, s) => DropdownButtonFormField<String>(
                        value: _selectedGender,
                        decoration: InputDecoration(
                          labelText: 'Gender (Optional)',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'male', child: Text('Male')),
                          DropdownMenuItem(value: 'female', child: Text('Female')),
                          DropdownMenuItem(value: 'other', child: Text('Other')),
                          DropdownMenuItem(value: 'prefer_not_say', child: Text('Prefer not to say')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedGender = value;
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Emirate/City - Dynamic from backend
                Consumer(
                  builder: (context, ref, _) {
                    final emiratesAsync = ref.watch(emirateChoicesProvider);
                    return emiratesAsync.when(
                      data: (emirates) => DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'Emirate / City',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: emirates.map((emirate) => DropdownMenuItem(
                          value: emirate.value,
                          child: Text(emirate.label),
                        )).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      loading: () => DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Emirate / City',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'abu_dhabi', child: Text('Abu Dhabi')),
                          DropdownMenuItem(value: 'dubai', child: Text('Dubai')),
                          DropdownMenuItem(value: 'sharjah', child: Text('Sharjah')),
                          DropdownMenuItem(value: 'ajman', child: Text('Ajman')),
                          DropdownMenuItem(value: 'umm_al_quwain', child: Text('Umm Al Quwain')),
                          DropdownMenuItem(value: 'ras_al_khaimah', child: Text('Ras Al Khaimah')),
                          DropdownMenuItem(value: 'fujairah', child: Text('Fujairah')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                      error: (e, s) => DropdownButtonFormField<String>(
                        value: _selectedCity,
                        decoration: InputDecoration(
                          labelText: 'Emirate / City',
                          prefixIcon: const Icon(Icons.location_city_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'abu_dhabi', child: Text('Abu Dhabi')),
                          DropdownMenuItem(value: 'dubai', child: Text('Dubai')),
                          DropdownMenuItem(value: 'sharjah', child: Text('Sharjah')),
                          DropdownMenuItem(value: 'ajman', child: Text('Ajman')),
                          DropdownMenuItem(value: 'umm_al_quwain', child: Text('Umm Al Quwain')),
                          DropdownMenuItem(value: 'ras_al_khaimah', child: Text('Ras Al Khaimah')),
                          DropdownMenuItem(value: 'fujairah', child: Text('Fujairah')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedCity = value;
                          });
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Nationality - Searchable Dropdown
                _buildNationalitySearchField(theme, colors),
                const SizedBox(height: 32),

                // === VEHICLE INFORMATION (Optional Section) ===
                InkWell(
                  onTap: () {
                    setState(() {
                      _showVehicleInfo = !_showVehicleInfo;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Vehicle Information',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _showVehicleInfo
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showVehicleInfo) ...[
                  const SizedBox(height: 16),
                  // Car Brand - Dynamic from backend
                  Consumer(
                    builder: (context, ref, _) {
                      final brandsAsync = ref.watch(carBrandChoicesProvider);
                      return brandsAsync.when(
                        data: (brands) => DropdownButtonFormField<String>(
                          value: _carBrandController.text.isNotEmpty ? _carBrandController.text : null,
                          decoration: InputDecoration(
                            labelText: 'Car Brand',
                            hintText: 'Select your vehicle brand',
                            prefixIcon: const Icon(Icons.directions_car),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          items: brands.map((brand) => DropdownMenuItem(
                            value: brand.value,
                            child: Text(brand.label),
                          )).toList(),
                          onChanged: (value) {
                            setState(() {
                              _carBrandController.text = value ?? '';
                            });
                          },
                        ),
                        loading: () => CustomTextField(
                          label: 'Car Brand',
                          hint: 'Loading brands...',
                          controller: _carBrandController,
                          prefixIcon: const Icon(Icons.directions_car),
                          textCapitalization: TextCapitalization.words,
                          enabled: false,
                        ),
                        error: (e, s) => CustomTextField(
                          label: 'Car Brand',
                          hint: 'e.g., Toyota, Land Rover',
                          controller: _carBrandController,
                          prefixIcon: const Icon(Icons.directions_car),
                          textCapitalization: TextCapitalization.words,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  // Car Model
                  CustomTextField(
                    label: 'Car Model',
                    hint: 'e.g., Land Cruiser, Defender',
                    controller: _carModelController,
                    prefixIcon: const Icon(Icons.car_rental),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  // Car Color
                  CustomTextField(
                    label: 'Car Color',
                    hint: 'e.g., White, Black',
                    controller: _carColorController,
                    prefixIcon: const Icon(Icons.palette_outlined),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  // Car Year
                  CustomTextField(
                    label: 'Car Year',
                    hint: 'e.g., 2020',
                    controller: _carYearController,
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.calendar_today),
                    validator: (value) {
                      if (value != null && value.isNotEmpty) {
                        final year = int.tryParse(value);
                        if (year == null || year < 1900 || year > DateTime.now().year + 1) {
                          return 'Please enter a valid year';
                        }
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 32),

                // === EMERGENCY CONTACT (Optional Section) ===
                InkWell(
                  onTap: () {
                    setState(() {
                      _showEmergencyContact = !_showEmergencyContact;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_hospital_outlined,
                          color: colors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Emergency Contact',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Icon(
                          _showEmergencyContact
                              ? Icons.keyboard_arrow_up
                              : Icons.keyboard_arrow_down,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_showEmergencyContact) ...[
                  const SizedBox(height: 16),
                  // Emergency Contact Name
                  CustomTextField(
                    label: 'Emergency Contact Name',
                    hint: 'Enter emergency contact name',
                    controller: _iceNameController,
                    prefixIcon: const Icon(Icons.person_outline),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 20),
                  // Emergency Contact Phone
                  CustomTextField(
                    label: 'Emergency Contact Phone',
                    hint: 'Enter emergency contact phone',
                    controller: _icePhoneController,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ],
                const SizedBox(height: 32),

                // Terms Checkbox with Links
                Row(
                  children: [
                    Checkbox(
                      value: _agreedToTerms,
                      onChanged: (value) {
                        setState(() {
                          _agreedToTerms = value ?? false;
                        });
                      },
                      activeColor: colors.primary,
                    ),
                    Expanded(
                      child: Wrap(
                        children: [
                          Text(
                            'I agree to the ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/settings/terms');
                            },
                            child: Text(
                              'Terms of Service',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            ' and ',
                            style: theme.textTheme.bodyMedium,
                          ),
                          GestureDetector(
                            onTap: () {
                              context.push('/settings/privacy');
                            },
                            child: Text(
                              'Privacy Policy',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colors.primary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Register Button
                PrimaryButton(
                  text: 'Create Account',
                  onPressed: _handleRegister,
                  isLoading: _isLoading,
                  height: 56,
                ),
                const SizedBox(height: 24),

                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        'Sign In',
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
