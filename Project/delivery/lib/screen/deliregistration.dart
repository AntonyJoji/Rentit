import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class deliregistration extends StatefulWidget {
  const deliregistration({super.key});

  @override
  State<deliregistration> createState() => _deliregistrationState();
}

class _deliregistrationState extends State<deliregistration> {
  final TextEditingController _deliNameController = TextEditingController();
  final TextEditingController _deliContactController = TextEditingController();
  final TextEditingController _deliEmailController = TextEditingController();
  final TextEditingController _deliAddressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedDist;
  String? selectedPlace;
  List<Map<String, dynamic>> _distList = [];
  List<Map<String, dynamic>> _placeList = [];
  PlatformFile? _deliphoto;
  PlatformFile? _deliid;

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
        email: _deliEmailController.text,
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
      await Supabase.instance.client.from('tbl_deliveryboy').insert({
        'boy_id': uid,
        'boy_name': _deliNameController.text,
        'boy_contact': _deliContactController.text,
        'boy_address': _deliAddressController.text,
        'boy_email': _deliEmailController.text,
        'boy_password': _passwordController.text,
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
      appBar: AppBar(title: Text('DeliveryBoy Registration')),
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
                  controller: _deliNameController,
                  decoration: InputDecoration(labelText: 'DeliveryBoy Name', border: OutlineInputBorder()),
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _deliContactController,
                  decoration: InputDecoration(labelText: 'DeliveryBoy Contact', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _deliEmailController,
                  decoration: InputDecoration(labelText: 'DeliveryBoy Email', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 12),
                TextFormField(
                  controller: _deliAddressController,
                  decoration: InputDecoration(labelText: 'DeliveryBoy Address', border: OutlineInputBorder()),
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
                Text('DeliveryBoy Photo'),
                GestureDetector(
                  onTap: () => _pickImage(true),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _deliphoto == null ? Center(child: Icon(Icons.add_a_photo, size: 40)) : Image.file(File(_deliphoto!.path!), fit: BoxFit.cover),
                  ),
                ),
                SizedBox(height: 12),
                Text('DeliveryBoy Id'),
                GestureDetector(
                  onTap: () => _pickImage(false),
                  child: Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(8)),
                    child: _deliid == null ? Center(child: Icon(Icons.add_a_photo, size: 40)) : Image.file(File(_deliid!.path!), fit: BoxFit.cover),
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
  