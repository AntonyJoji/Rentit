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
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopContactController = TextEditingController();
  final TextEditingController _shopEmailController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool isLoading = false;

  String? selectedDist;
  String? selectedPlace;
  List<Map<String, dynamic>> _distList = [];
  List<Map<String, dynamic>> _placeList = [];
  PlatformFile? _shopProof;

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
      });
    } catch (e) {
      print("Error fetching places: $e");
    }
  }

  Future<void> register() async {
    if (_shopNameController.text.isEmpty ||
        _shopContactController.text.isEmpty ||
        _shopEmailController.text.isEmpty ||
        _shopAddressController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        selectedDist == null ||
        selectedPlace == null ||
        _shopProof == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration successful!')),
        );
        // Navigate to shop login page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ShopLogin()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error in registration: $e')),
      );
    } finally {
      setState(() => isLoading = false);
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
        'shop_name': _shopNameController.text,
        'shop_contact': _shopContactController.text,
        'shop_address': _shopAddressController.text,
        'shop_email': _shopEmailController.text,
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Shop Registration',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: 500, // Fixed width for the form
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Your Shop Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fill in your shop details to get started',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 32),
                _buildFormField(
                  controller: _shopNameController,
                  label: 'Shop Name',
                  icon: Icons.store,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _shopContactController,
                  label: 'Contact Number',
                  icon: Icons.phone,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _shopEmailController,
                  label: 'Email Address',
                  icon: Icons.email,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _shopAddressController,
                  label: 'Shop Address',
                  icon: Icons.location_on,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
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
                          setState(() {
                            selectedDist = newValue;
                            fetchPlace(newValue!);
                          });
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
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Shop Proof Document',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickProof,
                  child: Container(
                    width: double.infinity,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
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
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Upload Shop Proof',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: kIsWeb
                                ? Image.memory(_shopProof!.bytes!, fit: BoxFit.cover)
                                : Image.file(File(_shopProof!.path!), fit: BoxFit.cover),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _passwordController,
                  label: 'Password',
                  icon: Icons.lock,
                  obscureText: true,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
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

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey[600]),
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
          borderSide: const BorderSide(color: Colors.blue, width: 2),
        ),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonFormField<String>(
        value: value,
        hint: Text(hint),
        icon: const Icon(Icons.arrow_drop_down),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
        onChanged: onChanged,
        items: items,
      ),
    );
  }
}
