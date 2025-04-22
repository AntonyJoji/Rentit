import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shop/screen/login.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
//import 'package:shop/screen/shop_login.dart';

class ShopRegistration extends StatefulWidget {
  const ShopRegistration({super.key});

  @override
  State<ShopRegistration> createState() => _ShopRegistrationState();
}

class _ShopRegistrationState extends State<ShopRegistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopContactController = TextEditingController();
  final TextEditingController _shopEmailController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  String? selectedDist;
  String? selectedPlace;
  List<Map<String, dynamic>> _distList = [];
  List<Map<String, dynamic>> _placeList = [];
  PlatformFile? _shopProof;

  // Validation patterns
  final RegExp _emailRegExp = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
  final RegExp _phoneRegExp = RegExp(r'^[0-9]{10}$');
  final RegExp _nameRegExp = RegExp(r'^[a-zA-Z0-9\s\-&.]{3,}$');
  final RegExp _passwordRegExp = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d@$!%*#?&]{6,}$');

  Future<void> _pickProof() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        _shopProof = result.files.first;
      });
    }
  }

  Future<void> fetchDist() async {
    try {
      final response = await Supabase.instance.client.from('tbl_district').select();
      setState(() {
        _distList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  Future<void> fetchPlace(String id) async {
    try {
      final response = await Supabase.instance.client.from('tbl_place').select().eq('district_id', id);
      setState(() {
        _placeList = List<Map<String, dynamic>>.from(response);
        selectedPlace = null; // Reset place when district changes
      });
    } catch (e) {
      print("Error fetching places: $e");
    }
  }

  Future<void> register() async {
    // Clear any existing snackbars
    ScaffoldMessenger.of(context).clearSnackBars();
    
    // Validate the form
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (_shopProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload shop proof document'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    if (selectedDist == null || selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select district and place'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final auth = await Supabase.instance.client.auth.signUp(
        password: _passwordController.text,
        email: _shopEmailController.text,
      );
      final uid = auth.user?.id;
      if (uid != null && uid.isNotEmpty) {
        await storeData(uid);
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Registration successful! You can now login.'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to shop login page
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const ShopLogin()),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString().split(']').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> storeData(String uid) async {
    try {
      String? proofUrl;

      if (_shopProof != null) {
        final path = 'proofs/$uid-${_shopProof!.name}';
        final bytes = _shopProof!.bytes ?? await File(_shopProof!.path!).readAsBytes();

        await Supabase.instance.client.storage.from('shop').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

        proofUrl = Supabase.instance.client.storage.from('shop').getPublicUrl(path);
      }

      // Insert shop data with shop_vstatus
      await Supabase.instance.client.from('tbl_shop').insert({
        'shop_id': uid,
        'shop_name': _shopNameController.text.trim(),
        'shop_contact': _shopContactController.text.trim(),
        'shop_address': _shopAddressController.text.trim(),
        'shop_email': _shopEmailController.text.trim(),
        'shop_password': _passwordController.text,
        'place_id': selectedPlace,
        'shop_proof': proofUrl,
        'shop_vstatus': 0, // Set shop_vstatus to 0
      });
    } catch (e) {
      print("Error inserting data or uploading proof: $e");
      rethrow;
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDist();
  }

  @override
  void dispose() {
    _shopNameController.dispose();
    _shopContactController.dispose();
    _shopEmailController.dispose();
    _shopAddressController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header with Logo
                  Padding(
                    padding: const EdgeInsets.only(bottom: 30),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset(
                                'assets/ss.jpg',
                                width: 50,
                                height: 50,
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 15),
                              const Text(
                                'RENTIT',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                      color: Color.fromRGBO(0, 0, 0, 0.3),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Create Shop Account',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register your shop to start renting out items',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  // Registration Form Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Shop Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Shop Name Field
                            _buildFormField(
                              controller: _shopNameController,
                              label: 'Shop Name',
                              hintText: 'Enter your shop name',
                              icon: Icons.store,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter shop name';
                                }
                                if (value.length < 3) {
                                  return 'Shop name must be at least 3 characters';
                                }
                                if (!_nameRegExp.hasMatch(value)) {
                                  return 'Shop name can only contain letters, numbers, spaces, and basic punctuation';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Contact Field
                            _buildFormField(
                              controller: _shopContactController,
                              label: 'Contact Number',
                              hintText: 'Enter 10-digit mobile number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter contact number';
                                }
                                if (!_phoneRegExp.hasMatch(value)) {
                                  return 'Please enter a valid 10-digit phone number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Email Field
                            _buildFormField(
                              controller: _shopEmailController,
                              label: 'Email Address',
                              hintText: 'Enter a valid email address',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter email address';
                                }
                                if (!_emailRegExp.hasMatch(value)) {
                                  return 'Please enter a valid email address (example@domain.com)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Address Field
                            _buildFormField(
                              controller: _shopAddressController,
                              label: 'Shop Address',
                              hintText: 'Enter your complete shop address',
                              icon: Icons.location_on,
                              maxLines: 2,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter shop address';
                                }
                                if (value.length < 10) {
                                  return 'Please enter a complete address with at least 10 characters';
                                }
                                if (value.length > 200) {
                                  return 'Address is too long (maximum 200 characters)';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),
                            
                            // Location Section
                            const Text(
                              'Shop Location',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // District & Place Selection
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    value: selectedDist,
                                    hint: "Select District",
                                    items: _distList.map((district) {
                                      return DropdownMenuItem<String>(
                                        value: district['district_id'].toString(),
                                        child: Text(district['district_name']),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          selectedDist = newValue;
                                          fetchPlace(newValue);
                                        });
                                      }
                                    },
                                    icon: Icons.location_city,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDropdown(
                                    value: selectedPlace,
                                    hint: "Select Place",
                                    items: _placeList.map((place) {
                                      return DropdownMenuItem<String>(
                                        value: place['place_id'].toString(),
                                        child: Text(place['place_name']),
                                      );
                                    }).toList(),
                                    onChanged: (newValue) {
                                      setState(() {
                                        selectedPlace = newValue;
                                      });
                                    },
                                    icon: Icons.place,
                                    isEnabled: _placeList.isNotEmpty,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Document Upload Section
                            const Text(
                              'Shop Verification',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload a proof of business (License/Registration)',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF666666),
                              ),
                            ),
                            const SizedBox(height: 12),
                            
                            // Document Upload Area
                            GestureDetector(
                              onTap: _pickProof,
                              child: Container(
                                width: double.infinity,
                                height: 140,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _shopProof == null 
                                        ? Colors.grey.shade300 
                                        : Colors.green.shade300,
                                    width: 1.5,
                                  ),
                                ),
                                child: _shopProof == null
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_upload,
                                            size: 40,
                                            color: Colors.blue.shade700,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Tap to upload document',
                                            style: TextStyle(
                                              color: Colors.grey[600],
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'PNG, JPG or JPEG',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(12),
                                            child: kIsWeb
                                                ? Image.memory(
                                                    _shopProof!.bytes!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  )
                                                : Image.file(
                                                    File(_shopProof!.path!),
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(0.6),
                                                shape: BoxShape.circle,
                                              ),
                                              child: InkWell(
                                                onTap: () {
                                                  setState(() {
                                                    _shopProof = null;
                                                  });
                                                },
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Security Section
                            const Text(
                              'Security',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF333333),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_passwordVisible,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                if (!_passwordRegExp.hasMatch(value)) {
                                  return 'Password must contain at least one letter and one number';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Password',
                                hintText: 'Create a secure password',
                                helperText: 'Min 6 characters with letters and numbers',
                                prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade700),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _passwordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _passwordVisible = !_passwordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                errorMaxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_confirmPasswordVisible,
                              autovalidateMode: AutovalidateMode.onUserInteraction,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                hintText: 'Re-enter your password',
                                prefixIcon: Icon(Icons.lock, color: Colors.blue.shade700),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _confirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _confirmPasswordVisible = !_confirmPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                                ),
                                errorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 1),
                                ),
                                focusedErrorBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.red.shade300, width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.grey.shade50,
                                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                                errorMaxLines: 2,
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Register Button
                            SizedBox(
                              width: double.infinity,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : register,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 2,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text('Create Account'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Login Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account?',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(builder: (context) => const ShopLogin()),
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.blue.shade700,
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    minimumSize: const Size(50, 30),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: const Text(
                                    "Login",
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blue.shade700),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade300, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        errorMaxLines: 2,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData icon,
    bool isEnabled = true,
  }) {
    return FormField<String>(
      initialValue: value,
      validator: (val) {
        if (val == null || val.isEmpty) {
          return 'Please select an option';
        }
        return null;
      },
      builder: (FormFieldState<String> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: state.hasError 
                      ? Colors.red.shade300 
                      : Colors.grey.shade300,
                ),
              ),
              child: DropdownButtonFormField<String>(
                value: value,
                hint: Text(hint),
                icon: const Icon(Icons.arrow_drop_down),
                decoration: InputDecoration(
                  prefixIcon: Icon(icon, color: Colors.blue.shade700),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                onChanged: isEnabled 
                    ? (newValue) {
                        state.didChange(newValue);
                        onChanged(newValue);
                      }
                    : null,
                items: items,
                isExpanded: true,
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                dropdownColor: Colors.white,
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
