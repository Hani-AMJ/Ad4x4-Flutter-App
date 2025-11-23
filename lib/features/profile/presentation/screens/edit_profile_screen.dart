import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../../core/providers/auth_provider_v2.dart';
import '../../../../core/providers/repository_providers.dart';
import '../../../../core/providers/gender_provider.dart';
import '../../../../core/providers/country_provider.dart';
import '../../../../core/providers/car_brand_provider.dart';
import '../../../../shared/widgets/widgets.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Personal Information Controllers
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  
  // Emergency Contact Controllers
  late TextEditingController _iceNameController;
  late TextEditingController _icePhoneController;
  
  // Vehicle Information Controllers
  late TextEditingController _carModelController;
  late TextEditingController _carColorController;
  
  // Date of Birth
  DateTime? _selectedDob;
  
  // Dropdown Selections
  String? _selectedGender;
  String? _selectedNationality;
  String? _selectedCarBrand;
  int? _selectedCarYear;
  
  // Image Picker
  XFile? _selectedImage;
  final ImagePicker _imagePicker = ImagePicker();
  
  bool _isLoading = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final user = ref.read(authProviderV2).user;
    
    _firstNameController = TextEditingController(text: user?.firstName ?? '');
    _lastNameController = TextEditingController(text: user?.lastName ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? user?.phoneNumber ?? '');
    _cityController = TextEditingController(text: user?.city ?? '');
    
    _iceNameController = TextEditingController(text: user?.iceName ?? '');
    _icePhoneController = TextEditingController(text: user?.icePhone ?? '');
    
    _carModelController = TextEditingController(text: user?.carModel ?? '');
    _carColorController = TextEditingController(text: user?.carColor ?? '');
    
    // Parse DOB if available
    if (user?.dob != null && user!.dob!.isNotEmpty) {
      try {
        _selectedDob = DateTime.parse(user.dob!);
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Failed to parse DOB: ${user.dob}');
        }
      }
    }
    
    _selectedGender = user?.gender;
    _selectedNationality = user?.nationality;
    _selectedCarBrand = user?.carBrand;
    _selectedCarYear = user?.carYear;
    
    _isInitialized = true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _iceNameController.dispose();
    _icePhoneController.dispose();
    _carModelController.dispose();
    _carColorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final repository = ref.read(mainApiRepositoryProvider);
      final user = ref.read(authProviderV2).user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }
      
      // Build update data according to API schema
      final updateData = <String, dynamic>{
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'phone': _phoneController.text.trim(),
      };
      
      // Add optional fields only if they have values
      if (_cityController.text.trim().isNotEmpty) {
        updateData['city'] = _cityController.text.trim();
      }
      
      if (_selectedDob != null) {
        updateData['dob'] = DateFormat('yyyy-MM-dd').format(_selectedDob!);
      }
      
      if (_selectedGender != null && _selectedGender!.isNotEmpty) {
        updateData['gender'] = _selectedGender;
      }
      
      if (_selectedNationality != null && _selectedNationality!.isNotEmpty) {
        updateData['nationality'] = _selectedNationality;
      }
      
      // Emergency Contact
      if (_iceNameController.text.trim().isNotEmpty) {
        updateData['iceName'] = _iceNameController.text.trim();
      }
      
      if (_icePhoneController.text.trim().isNotEmpty) {
        updateData['icePhone'] = _icePhoneController.text.trim();
      }
      
      // Vehicle Information
      if (_selectedCarBrand != null && _selectedCarBrand!.isNotEmpty) {
        updateData['carBrand'] = _selectedCarBrand;
      }
      
      if (_carModelController.text.trim().isNotEmpty) {
        updateData['carModel'] = _carModelController.text.trim();
      }
      
      if (_selectedCarYear != null) {
        updateData['carYear'] = _selectedCarYear;
      }
      
      if (_carColorController.text.trim().isNotEmpty) {
        updateData['carColor'] = _carColorController.text.trim();
      }
      
      // Upload avatar if selected
      if (_selectedImage != null) {
        updateData['avatar'] = _selectedImage!.path;
      }

      await repository.updateProfile(updateData);

      // Refresh user profile in auth provider
      await ref.read(authProviderV2.notifier).refreshProfile();

      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Color(0xFF42B883),
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate back to profile page
        context.go('/profile');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob ?? DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final user = ref.watch(authProviderV2).user;

    if (kDebugMode) {
      debugPrint('🔍 [EditProfile] Building screen...');
      debugPrint('   User: ${user?.username ?? "null"}');
      debugPrint('   Initialized: $_isInitialized');
      debugPrint('   Profile Complete: ${user?.isProfileComplete ?? false}');
      if (user != null && !user.isProfileComplete) {
        debugPrint('   Missing Fields: ${user.missingFields}');
      }
    }

    if (!_isInitialized || user == null) {
      if (kDebugMode) {
        debugPrint('⚠️ [EditProfile] Not initialized or user is null');
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    if (kDebugMode) {
      debugPrint('✅ [EditProfile] Rendering form');
    }

    return PopScope(
      canPop: user.isProfileComplete,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !user.isProfileComplete) {
          // Show warning if trying to go back with incomplete profile
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please complete your profile before continuing'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Profile'),
          // Hide back button if profile is incomplete
          automaticallyImplyLeading: user.isProfileComplete,
          actions: [
          TextButton(
            onPressed: _isLoading ? null : _handleSave,
            child: Text(
              'Save',
              style: TextStyle(
                color: _isLoading
                    ? colors.onSurface.withValues(alpha: 0.5)
                    : colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Builder(
              builder: (context) {
                if (kDebugMode) {
                  debugPrint('📝 [EditProfile] Building Form Column');
                }
                try {
                  return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // DEBUG: Test widget to verify column is rendering
                    if (kDebugMode) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.2),
                          border: Border.all(color: Colors.blue, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'DEBUG: Form column is rendering!\nUser: ${user.username}\nProfile Complete: ${user.isProfileComplete}',
                          style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    
                    // Profile Completion Banner (if incomplete)
                    if (!user.isProfileComplete) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors.errorContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors.error,
                        width: 2,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: colors.error,
                              size: 28,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Complete Your Profile',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Please complete the following mandatory fields to continue using the app:',
                          style: TextStyle(
                            fontSize: 14,
                            color: colors.onErrorContainer,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...user.missingFields.map((field) => Padding(
                          padding: const EdgeInsets.only(left: 8, top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.circle,
                                size: 8,
                                color: colors.error,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                field,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colors.onErrorContainer,
                                ),
                              ),
                            ],
                          ),
                        )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Avatar Section
                Center(
                  child: Stack(
                    children: [
                      _selectedImage != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: kIsWeb
                                  ? NetworkImage(_selectedImage!.path)
                                  : FileImage(File(_selectedImage!.path)) as ImageProvider,
                            )
                          : UserAvatar(
                              name: '${_firstNameController.text.trim().isEmpty ? user.username : _firstNameController.text} ${_lastNameController.text}',
                              imageUrl: user.avatar ?? user.profileImage,
                              radius: 60,
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.primary,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.surface,
                              width: 3,
                            ),
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            size: 20,
                            color: colors.onPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: TextButton(
                    onPressed: _pickAndCropImage,
                    child: Text(
                      'Change Photo',
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Personal Information Section
                _buildSectionHeader('Personal Information', Icons.person, colors),
                const SizedBox(height: 16),
                
                CustomTextField(
                  label: 'First Name',
                  hint: 'Enter your first name',
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Last Name',
                  hint: 'Enter your last name',
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Date of Birth
                _buildDateField(
                  label: 'Date of Birth',
                  value: _selectedDob != null 
                      ? DateFormat('MMMM dd, yyyy').format(_selectedDob!)
                      : null,
                  onTap: _selectDate,
                ),
                const SizedBox(height: 16),

                // Gender Dropdown
                _buildGenderDropdown(colors),
                const SizedBox(height: 16),

                // Nationality Dropdown
                _buildNationalityDropdown(colors),
                const SizedBox(height: 32),

                // Contact Information Section
                _buildSectionHeader('Contact Information', Icons.contact_phone, colors),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter your phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'City (Optional)',
                  hint: 'e.g., Abu Dhabi, Dubai',
                  controller: _cityController,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),

                // Emergency Contact Section
                _buildSectionHeader('Emergency Contact', Icons.local_hospital, colors),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'ICE Contact Name',
                  hint: 'In Case of Emergency contact name',
                  controller: _iceNameController,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'ICE Contact Phone',
                  hint: 'In Case of Emergency contact phone',
                  controller: _icePhoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 32),

                // Vehicle Information Section
                _buildSectionHeader('Vehicle Information', Icons.directions_car, colors),
                const SizedBox(height: 16),

                _buildCarBrandDropdown(colors),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Car Model',
                  hint: 'e.g., Patrol, Land Cruiser',
                  controller: _carModelController,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),

                _buildCarYearDropdown(colors),
                const SizedBox(height: 16),

                CustomTextField(
                  label: 'Car Color',
                  hint: 'e.g., White, Black',
                  controller: _carColorController,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 32),

                // Action Buttons
                PrimaryButton(
                  text: 'Save Changes',
                  onPressed: _handleSave,
                  isLoading: _isLoading,
                  width: double.infinity,
                  height: 56,
                ),
                const SizedBox(height: 16),

                SecondaryButton(
                  text: 'Change Password',
                  onPressed: () {
                    _showChangePasswordDialog(context);
                  },
                  width: double.infinity,
                  height: 56,
                ),
                const SizedBox(height: 24),
              ],
                );
                } catch (e, stack) {
                  if (kDebugMode) {
                    debugPrint('❌ [EditProfile] ERROR building form: $e');
                    debugPrint('   Stack: $stack');
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error loading form: $e'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _isInitialized = false;
                              });
                              Future.delayed(const Duration(milliseconds: 100), () {
                                _initializeControllers();
                              });
                            },
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  );
                }
              },
            ),
          ),
        ),
      ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, ColorScheme colors) {
    return Row(
      children: [
        Icon(icon, color: colors.primary, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required String label,
    required String? value,
    required VoidCallback onTap,
  }) {
    final colors = Theme.of(context).colorScheme;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: colors.outline),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value ?? 'Select date',
                    style: TextStyle(
                      fontSize: 16,
                      color: value != null 
                          ? colors.onSurface 
                          : colors.onSurface.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.calendar_today,
              color: colors.primary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderDropdown(ColorScheme colors) {
    final genders = ref.watch(genderChoicesProvider);
    
    return genders.when(
      data: (genderList) {
        if (kDebugMode) {
          debugPrint('✅ Gender choices loaded: ${genderList.length} items');
        }
        
        // Validate that selected value exists in the list
        final validatedValue = _selectedGender != null && 
            genderList.any((g) => g.value == _selectedGender)
            ? _selectedGender
            : null;
        
        if (_selectedGender != null && validatedValue == null && kDebugMode) {
          debugPrint('⚠️ Invalid gender value: $_selectedGender, resetting to null');
        }
        
        return DropdownButtonFormField<String>(
          value: validatedValue,
          decoration: InputDecoration(
            labelText: 'Gender (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: genderList.map((gender) {
            return DropdownMenuItem<String>(
              value: gender.value,
              child: Text(gender.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedGender = value;
            });
          },
        );
      },
      loading: () {
        if (kDebugMode) {
          debugPrint('⏳ Loading gender choices...');
        }
        return TextFormField(
          initialValue: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender (Optional)',
            hintText: 'Loading options...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabled: false,
            suffixIcon: const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
      error: (error, stack) {
        if (kDebugMode) {
          debugPrint('❌ Error loading gender choices: $error');
        }
        return TextFormField(
          initialValue: _selectedGender,
          decoration: InputDecoration(
            labelText: 'Gender (Optional)',
            hintText: 'Enter your gender',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            _selectedGender = value;
          },
        );
      },
    );
  }

  Widget _buildNationalityDropdown(ColorScheme colors) {
    final countries = ref.watch(countryChoicesProvider);
    
    return countries.when(
      data: (countryList) {
        if (kDebugMode) {
          debugPrint('✅ Country choices loaded: ${countryList.length} items');
        }
        
        // Validate that selected value exists in the list
        final validatedValue = _selectedNationality != null && 
            countryList.any((c) => c.value == _selectedNationality)
            ? _selectedNationality
            : null;
        
        if (_selectedNationality != null && validatedValue == null && kDebugMode) {
          debugPrint('⚠️ Invalid nationality value: $_selectedNationality, resetting to null');
        }
        
        return DropdownButtonFormField<String>(
          value: validatedValue,
          decoration: InputDecoration(
            labelText: 'Nationality (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: countryList.map((country) {
            return DropdownMenuItem<String>(
              value: country.value,
              child: Text(country.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedNationality = value;
            });
          },
        );
      },
      loading: () {
        if (kDebugMode) {
          debugPrint('⏳ Loading country choices...');
        }
        return TextFormField(
          initialValue: _selectedNationality,
          decoration: InputDecoration(
            labelText: 'Nationality (Optional)',
            hintText: 'Loading options...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabled: false,
            suffixIcon: const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
      error: (error, stack) {
        if (kDebugMode) {
          debugPrint('❌ Error loading country choices: $error');
        }
        return TextFormField(
          initialValue: _selectedNationality,
          decoration: InputDecoration(
            labelText: 'Nationality (Optional)',
            hintText: 'Enter your nationality',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            _selectedNationality = value;
          },
        );
      },
    );
  }

  Widget _buildCarBrandDropdown(ColorScheme colors) {
    final carBrands = ref.watch(carBrandChoicesProvider);
    
    return carBrands.when(
      data: (brandList) {
        if (kDebugMode) {
          debugPrint('✅ Car brand choices loaded: ${brandList.length} items');
        }
        
        // Validate that selected value exists in the list
        final validatedValue = _selectedCarBrand != null && 
            brandList.any((b) => b.value == _selectedCarBrand)
            ? _selectedCarBrand
            : null;
        
        if (_selectedCarBrand != null && validatedValue == null && kDebugMode) {
          debugPrint('⚠️ Invalid car brand value: $_selectedCarBrand, resetting to null');
        }
        
        return DropdownButtonFormField<String>(
          value: validatedValue,
          decoration: InputDecoration(
            labelText: 'Car Brand (Optional)',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: brandList.map((brand) {
            return DropdownMenuItem<String>(
              value: brand.value,
              child: Text(brand.label),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCarBrand = value;
            });
          },
        );
      },
      loading: () {
        if (kDebugMode) {
          debugPrint('⏳ Loading car brand choices...');
        }
        return TextFormField(
          initialValue: _selectedCarBrand,
          decoration: InputDecoration(
            labelText: 'Car Brand (Optional)',
            hintText: 'Loading options...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabled: false,
            suffixIcon: const SizedBox(
              width: 20,
              height: 20,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
        );
      },
      error: (error, stack) {
        if (kDebugMode) {
          debugPrint('❌ Error loading car brand choices: $error');
        }
        return TextFormField(
          initialValue: _selectedCarBrand,
          decoration: InputDecoration(
            labelText: 'Car Brand (Optional)',
            hintText: 'Enter your car brand',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onChanged: (value) {
            _selectedCarBrand = value;
          },
        );
      },
    );
  }

  Widget _buildCarYearDropdown(ColorScheme colors) {
    final currentYear = DateTime.now().year;
    final years = List.generate(50, (index) => currentYear - index);
    
    return DropdownButtonFormField<int>(
      value: _selectedCarYear,
      decoration: InputDecoration(
        labelText: 'Car Year (Optional)',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: years.map((year) {
        return DropdownMenuItem<int>(
          value: year,
          child: Text(year.toString()),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedCarYear = value;
        });
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Current Password',
                controller: currentPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'New Password',
                controller: newPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Required';
                  }
                  if (value.length < 6) {
                    return 'Min 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Confirm New Password',
                controller: confirmPasswordController,
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  final repository = ref.read(mainApiRepositoryProvider);
                  await repository.changePassword(
                    oldPassword: currentPasswordController.text,
                    password: newPasswordController.text,
                    passwordConfirm: confirmPasswordController.text,
                  );
                  
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password changed successfully!'),
                        backgroundColor: Color(0xFF42B883),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to change password: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndCropImage() async {
    try {
      // Show image source selection dialog
      final ImageSource? source = await showDialog<ImageSource>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );

      if (source == null) return;

      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      // Crop image with circular crop
      final CroppedFile? croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Profile Photo',
            toolbarColor: Theme.of(context).colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            cropStyle: CropStyle.circle,
          ),
          IOSUiSettings(
            title: 'Crop Profile Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
            aspectRatioPresets: [
              CropAspectRatioPreset.square,
            ],
            cropStyle: CropStyle.circle,
          ),
          WebUiSettings(
            context: context,
            presentStyle: WebPresentStyle.dialog,
            size: const CropperSize(
              width: 520,
              height: 520,
            ),
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _selectedImage = XFile(croppedFile.path);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Photo selected! Click Save to upload.'),
              backgroundColor: Color(0xFF42B883),
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Error picking/cropping image: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to select photo: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
