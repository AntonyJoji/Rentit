import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  String? selectedDist;
  String? selectedPlace;
  List<Map<String, dynamic>> _distList = [];
  List<Map<String, dynamic>> _placeList = [];
  PlatformFile? _shopLogo;
  PlatformFile? _shopProof;

  Future<void> _pickImage(bool isLogo) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        if (isLogo) {
          _shopLogo = result.files.first;
        } else {
          _shopProof = result.files.first;
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
        email: _shopEmailController.text,
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
      await Supabase.instance.client.from('tbl_shop').insert({
        'shop_id': uid,
        'shop_name': _shopNameController.text,
        'shop_contact': _shopContactController.text,
        'shop_address': _shopAddressController.text,
        'shop_email': _shopEmailController.text,
        'shop_password': _passwordController.text,
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
      appBar: AppBar(title: Text('Shop Registration')),
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
                  controller: _shopNameController,
                  decoration: InputDecoration(labelText: 'Shop Name', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _shopContactController,
                  decoration: InputDecoration(labelText: 'Shop Contact', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _shopEmailController,
                  decoration: InputDecoration(labelText: 'Shop Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _shopAddressController,
                  decoration: InputDecoration(labelText: 'Shop Address', border: OutlineInputBorder()),
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
                Text('Shop Logo'),
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _shopLogo == null ? Center(child: Icon(Icons.add_a_photo, size: 40)) : Image.file(File(_shopLogo!.path!), fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 12),
                Text('Shop Proof'),
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _shopProof == null ? Center(child: Icon(Icons.add_a_photo, size: 40)) : Image.file(File(_shopProof!.path!), fit: BoxFit.cover),
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
                    onPressed: register,
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
  