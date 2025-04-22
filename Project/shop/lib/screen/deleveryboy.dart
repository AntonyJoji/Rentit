import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
//import 'package:shop/main.dart';
import 'package:shop/services/auth_service.dart';
//import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class deliregistration extends StatefulWidget {
  const deliregistration({super.key});

  @override
  State<deliregistration> createState() => _deliregistrationState();
}

class _deliregistrationState extends State<deliregistration> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _deliNameController = TextEditingController();
  final TextEditingController _deliContactController = TextEditingController();
  final TextEditingController _deliEmailController = TextEditingController();
  final TextEditingController _deliAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _repassEditingController = TextEditingController();

  PlatformFile? _deliphoto;
  PlatformFile? _deliid;
  bool _isSubmitting = false;
  
  // Regular expressions for validation
  final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+',
  );
  
  final RegExp _phoneRegExp = RegExp(
    r'^[0-9]{10}$',
  );
  
  final RegExp _passwordRegExp = RegExp(
    r'^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{8,}$',
  );

 Future<void> _pickImage(bool isLogo) async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
  if (result != null) {
    setState(() {
      if (isLogo) {
        _deliphoto = result.files.first;
      } else {
        _deliid = result.files.first;
      }
    });
  }
}


  

  Future<String?> uploadImage(PlatformFile file, String path) async {
  try {
    if (file.bytes != null) {
      final response = await Supabase.instance.client
          .storage
          .from('shop')
          .uploadBinary(path, file.bytes!);

      return response;
    } else {
      throw Exception('File data is null.');
    }
  } catch (e) {
    print("Error uploading image: $e");
    return null;
  }
}


    final AuthService _authService = AuthService();


  Future<void> register() async {
  if (!_formKey.currentState!.validate()) {
    // Form validation failed
    return;
  }
  
  // Check if images are uploaded
  if (_deliphoto == null || _deliid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please upload both photo and proof ID'),
        backgroundColor: Colors.red,
      ),
    );
    return;
  }
  
  setState(() {
    _isSubmitting = true;
  });
  
  try {
    if (_passwordController.text == _repassEditingController.text) {
      final auth = await Supabase.instance.client.auth.signUp(
        password: _passwordController.text,
        email: _deliEmailController.text,
      );

      await _authService.relogin();

      if (auth.user != null) {
        final uid = auth.user!.id;
        await storeData(uid);
        
        // Clear all input fields and selected files
        setState(() {
          _deliNameController.clear();
          _deliContactController.clear();
          _deliEmailController.clear();
          _deliAddressController.clear();
          _passwordController.clear();
          _repassEditingController.clear();
          _deliphoto = null;
          _deliid = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registration successful!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User creation failed. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password and re-entered password do not match'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } catch (e) {
    if (e.toString().contains('user_already_exists')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This email is already registered. Please use a different email.'),
          backgroundColor: Colors.red,
        ),
      );
    } else {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error during registration: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  } finally {
    setState(() {
      _isSubmitting = false;
    });
  }
}


  Future<void> storeData(String uid) async {
  try {
    if (_deliphoto == null || _deliid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload both photo and proof.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final photoUrl = await uploadImage(_deliphoto!, 'photos/${_deliphoto!.name}');
    final proofUrl = await uploadImage(_deliid!, 'proofs/${_deliid!.name}');

    if (photoUrl == null || proofUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error uploading files. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

   
    final shopId = Supabase.instance.client.auth.currentUser?.id;
    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Shop ID not found. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await Supabase.instance.client.from('tbl_deliveryboy').insert({
      'boy_id': uid,
      'boy_name': _deliNameController.text.trim(),
      'boy_contact': _deliContactController.text.trim(),
      'boy_address': _deliAddressController.text.trim(),
      'boy_email': _deliEmailController.text.trim(),
      'boy_password': _passwordController.text.trim(),
      'shop_id': shopId,
      'boy_photo': photoUrl,
      'boy_proof': proofUrl,
      'boy_status': 1,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data inserted successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print("Error inserting data: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Error inserting data: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  @override
  void initState() {
    super.initState();
  }

  // Dispose controllers when no longer needed
  @override
  void dispose() {
    _deliNameController.dispose();
    _deliContactController.dispose();
    _deliEmailController.dispose();
    _deliAddressController.dispose();
    _passwordController.dispose();
    _repassEditingController.dispose();
    super.dispose();
  }

Widget build(BuildContext context) {
  return Center(
    child: Container(
      width: 400,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                'Delivery Boy Registration',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _deliNameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter name';
                  }
                  if (value.length < 3) {
                    return 'Name must be at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliContactController,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
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
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliEmailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
                  }
                  if (!_emailRegExp.hasMatch(value)) {
                    return 'Please enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _deliAddressController,
                decoration: const InputDecoration(
                  labelText: 'Address',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter address';
                  }
                  if (value.length < 10) {
                    return 'Please enter a complete address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                  helperText: 'Min 8 characters with at least 1 letter and 1 number',
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password';
                  }
                  if (!_passwordRegExp.hasMatch(value)) {
                    return 'Password must be at least 8 characters with letters and numbers';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _repassEditingController,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please confirm password';
                  }
                  if (value != _passwordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              
              // Document Upload Section
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Required Documents',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // Photo Upload
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(true),
                            icon: const Icon(Icons.photo_camera),
                            label: Text(
                              _deliphoto != null
                                  ? 'Photo: ${_deliphoto!.name}'
                                  : 'Upload Photo',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _deliphoto != null ? Colors.green[100] : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ID Proof Upload
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(false),
                            icon: const Icon(Icons.assignment_ind),
                            label: Text(
                              _deliid != null
                                  ? 'ID: ${_deliid!.name}'
                                  : 'Upload ID Proof',
                              overflow: TextOverflow.ellipsis,
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              backgroundColor: _deliid != null ? Colors.green[100] : null,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
