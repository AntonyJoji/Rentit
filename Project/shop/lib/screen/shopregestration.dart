//import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:shop/main.dart';
//import 'package:file_picker/file_picker.dart'; // For image picking
//import 'dart:io'; // For File handling

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
  final TextEditingController _placeIdController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  String? selectedDist;
  String? selectedPlace;

  List<Map<String, dynamic>> _distList = [];
  List<Map<String, dynamic>> _placeList = [];
// PlatformFile? _shopLogo; // For storing shop logo image
// PlatformFile? _shopProof; // For storing shop proof image

  // Function to handle form submission
  // void _submitForm() {
  //   // Perform registration logic here
  //   print('Shop Name: ${_shopNameController.text}');
  //   print('Shop Contact: ${_shopContactController.text}');
  //   print('Shop Email: ${_shopEmailController.text}');
  //   print('Shop Address: ${_shopAddressController.text}');
  //   print('Place ID: ${_placeIdController.text}');
  //   print('Password: ${_passwordController.text}');
  //   if (_shopLogo != null) print('Shop Logo: ${_shopLogo!.path}');
  //   if (_shopProof != null) print('Shop Proof: ${_shopProof!.path}');
  // }

  Future<void> Manageplace() async {
    try {
      String place = _placeIdController.text;
      if (selectedDist == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a district"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await supabase.from('tbl_place').insert({
        'place_name': place,
        'district_id': selectedDist, // Ensure district_id is added
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Place added successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      _placeIdController.clear();
      setState(() {
        selectedDist = null; // Reset selection
      });
    } catch (e) {
      print("Error adding place: $e");
    }
  }

  Future<void> fetchDist() async {
    try {
      final response = await supabase.from('tbl_district').select();
      if (response.isNotEmpty) {
        print(response);
        setState(() {
          _distList = response;
        });
      }
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  Future<void> fetchPlace(String? id) async {
    try {
      final response =
          await supabase.from('tbl_place').select().eq('district_id', id!);
      // print(response);
      setState(() {
        _placeList = response;
      });
      display();
    } catch (e) {
      print("ERROR FETCHING DISTRICT DATA: $e");
    }
  }

  void display() {
    print(_placeList);
  }

  Future<void> register() async {
    try {
      final auth = await supabase.auth.signUp(
          password: _passwordController.text, email: _shopEmailController.text);
      final uid = auth.user!.id;
      if (uid.isNotEmpty || uid != "") {
        storeData(uid);
      }
    } catch (e) {
      print("ERROR IN AUTHENTICATION:$e");
    }
  }

  Future<void> storeData(uid) async {
    try {
      String name = _shopNameController.text;
      String contact = _shopContactController.text;
      String address = _shopAddressController.text;
      String email = _shopEmailController.text;
      String password = _passwordController.text;
      await supabase.from('tbl_shop').insert({
        'shop_id': uid,
        'shop_name': name,
        'shop_contact': contact,
        'shop_address': address,
        'shop_email': email,
        'shop_password': password
      });
    } catch (e) {
      print("ERROR INSERTING DATA:$e");
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchDist();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Shop Registration'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            // Shop Name
            TextFormField(
              controller: _shopNameController,
              decoration: InputDecoration(
                labelText: 'Shop Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Shop Contact
            TextFormField(
              controller: _shopContactController,
              decoration: InputDecoration(
                labelText: 'Shop Contact',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 16),

            // Shop Email
            TextFormField(
              controller: _shopEmailController,
              decoration: InputDecoration(
                labelText: 'Shop Email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 16),

            // Shop Address
            TextFormField(
              controller: _shopAddressController,
              decoration: InputDecoration(
                labelText: 'Shop Address',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),

            // Place ID
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedDist,
                    hint: const Text("Select District"),
                    onChanged: (newValue) {
                      setState(() {
                        selectedDist = newValue;
                      });
                      fetchPlace(newValue);
                    },
                    items: _distList.map((district) {
                      return DropdownMenuItem<String>(
                        value: district['district_id'].toString(),
                        child: Text(district['district_name']),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedPlace,
                    hint: const Text("Select place"),
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
                const SizedBox(width: 10),
              ],
            ),
            SizedBox(height: 16),

            // Shop Logo
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop Logo'),
                SizedBox(height: 8),
                // GestureDetector(
                //   onTap: _pickShopLogo,
                //   child: Container(
                //     width: double.infinity,
                //     height: 100,
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.grey),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: _shopLogo == null
                //         ? Center(child: Icon(Icons.add_a_photo, size: 40))
                //         : Image.file(_shopLogo!, fit: BoxFit.cover),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 16),

            // Shop Proof
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Shop Proof'),
                SizedBox(height: 8),
                // GestureDetector(
                //   onTap: _pickShopProof,
                //   child: Container(
                //     width: double.infinity,
                //     height: 100,
                //     decoration: BoxDecoration(
                //       border: Border.all(color: Colors.grey),
                //       borderRadius: BorderRadius.circular(8),
                //     ),
                //     child: _shopProof == null
                //         ? Center(child: Icon(Icons.add_a_photo, size: 40))
                //         : Image.file(_shopProof!, fit: BoxFit.cover),
                //   ),
                // ),
              ],
            ),
            SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            SizedBox(height: 24),

            // Submit Button
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  register();
                },
                child: Text('Submit'))
          ],
        ),
      ),
    );
  }
}
