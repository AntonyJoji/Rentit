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
    try {
      final auth = await Supabase.instance.client.auth.signUp(
        password: _passwordController.text,
        email: _userEmailController.text,
      );
      final uid = auth.user?.id;
      if (uid != null && uid.isNotEmpty) {
        await storeData(uid);
      }
    } catch (e) {
      print("Error in authentication: $e");
    }
  }

  Future<void> storeData(String uid) async {
    try {
      await Supabase.instance.client.from('tbl_user').insert({
        'user_id': uid,
        'user_name': _userNameController.text,
        'user_contact': _userContactController.text,
        'user_address': _userAddressController.text,
        'user_email': _userEmailController.text,
        'user_password': _passwordController.text,
        'place_id': selectedPlace,
      });
    } catch (e) {
      print("Error inserting data: $e");
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
                       Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserLoginPage (), // Fixed constructor reference
                              ),
                            );
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
  