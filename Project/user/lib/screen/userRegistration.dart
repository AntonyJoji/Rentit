import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/login.dart';

class Userregistration extends StatefulWidget {
  const Userregistration({super.key});

  @override
  State<Userregistration> createState() => _userregistrationState();
}

class _userregistrationState extends State<Userregistration> {
  final TextEditingController _userNameController = TextEditingController();
  final TextEditingController _userContactController = TextEditingController();
  final TextEditingController _userEmailController = TextEditingController();
  final TextEditingController _userAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedDist;
  String? selectedPlace;
  List<Map<String, dynamic>> _distList = [];
  List<Map<String, dynamic>> _placeList = [];
  PlatformFile? _userphoto;
  PlatformFile? _userid;

  Future<void> _pickImage(bool isLogo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        if (isLogo) {
          _userphoto = result.files.first;
        } else {
          _userid = result.files.first;
        }
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
    // Validate input fields
    if (_userNameController.text.trim().isEmpty ||
        _userContactController.text.trim().isEmpty ||
        _userEmailController.text.trim().isEmpty ||
        _userAddressController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        selectedPlace == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill in all required fields'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate email format
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(_userEmailController.text.trim())) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid email address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate password length
    if (_passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Password must be at least 6 characters long'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if photos are selected
    if (_userphoto == null || _userid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please upload both your photo and ID document'),
          backgroundColor: Colors.amber,
        ),
      );
      return;
    }

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      final auth = await Supabase.instance.client.auth.signUp(
        password: _passwordController.text,
        email: _userEmailController.text,
      );
      
      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      final uid = auth.user?.id;
      if (uid != null && uid.isNotEmpty) {
        await storeData(uid);
        
        // Navigate to login page after successful registration
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => UserLoginPage(),
          ),
        );
      } else {
        throw Exception("Failed to create user account");
      }
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print("Error in authentication: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> storeData(String uid) async {
    try {
      // Create loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      String? userPhotoPath;
      String? userIdPath;

      // Upload user photo if selected
      if (_userphoto != null) {
        final photoFile = File(_userphoto!.path!);
        final photoFileName = '${uid}_userphoto_${DateTime.now().millisecondsSinceEpoch}.${_userphoto!.extension}';
        
        try {
          await Supabase.instance.client.storage
              .from('shop')
              .upload(
                'user_photos/$photoFileName',
                photoFile,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
              );
          userPhotoPath = 'user_photos/$photoFileName';
          print('User photo uploaded successfully to: $userPhotoPath');
        } catch (e) {
          print('Error uploading user photo: $e');
        }
      }

      // Upload user ID if selected
      if (_userid != null) {
        final idFile = File(_userid!.path!);
        final idFileName = '${uid}_userid_${DateTime.now().millisecondsSinceEpoch}.${_userid!.extension}';
        
        try {
          await Supabase.instance.client.storage
              .from('shop')
              .upload(
                'user_ids/$idFileName',
                idFile,
                fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
              );
          userIdPath = 'user_ids/$idFileName';
          print('User ID document uploaded successfully to: $userIdPath');
        } catch (e) {
          print('Error uploading user ID: $e');
        }
      }

      // Insert user data including photo and ID paths
      await Supabase.instance.client.from('tbl_user').insert({
        'user_id': uid,
        'user_name': _userNameController.text,
        'user_contact': _userContactController.text,
        'user_address': _userAddressController.text,
        'user_email': _userEmailController.text,
        'user_password': _passwordController.text,
        'place_id': selectedPlace,
        'user_photo': userPhotoPath,
        'user_proof': userIdPath,
      });

      // Close loading dialog
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration successful!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Close loading dialog if still open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      print("Error inserting data: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Registration failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
      appBar: AppBar(title: Text('User Registration')),
      body: Center(
        child: Container(
          width: 400, // Adjust width to make it compact
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                TextFormField(
                  controller: _userNameController,
                  decoration: InputDecoration(labelText: 'user Name', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _userContactController,
                  decoration: InputDecoration(labelText: 'user Contact', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _userEmailController,
                  decoration: InputDecoration(labelText: 'user Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _userAddressController,
                  decoration: InputDecoration(labelText: 'user Address', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedDist,
                        hint: Text("Select District"),
                        onChanged: (newValue) {
                          setState(() {
                            selectedDist = newValue;
                            fetchPlace(newValue!);
                          });
                        },
                        items: _distList.map((district) {
                          return DropdownMenuItem<String>(
                            value: district['district_id'].toString(),
                            child: Text(district['district_name']),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: selectedPlace,
                        hint: Text("Select Place"),
                        onChanged: (newValue) {
                          setState(() {
                            selectedPlace = newValue;
                          });
                        },
                        items: _placeList.map((place) {
                          return DropdownMenuItem<String>(
                            value: place['place_id'].toString(),
                            child: Text(place['place_name']),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text('user photo'),
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _userphoto == null ? Center(child: Icon(Icons.add_a_photo, size: 40)) : Image.file(File(_userphoto!.path!), fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 12),
                Text('user id'),
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _userid == null ? Center(child: Icon(Icons.add_a_photo, size: 40)) : Image.file(File(_userid!.path!), fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                  obscureText: true,
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      register();
                    },
                    child: Text('Submit'),
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
  