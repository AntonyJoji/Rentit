import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shop/main.dart';
import 'package:shop/services/auth_service.dart';
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
  final TextEditingController _repassEditingController = TextEditingController();

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('User creation failed. Please try again.')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password and re-entered password mismatch')),
      );
    }
  } catch (e) {
    if (e.toString().contains('user_already_exists')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('This email is already registered. Please log in.')),
      );
    } else {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during registration: $e')),
      );
    }
  }
}


  Future<void> storeData(String uid) async {
  try {
    if (_deliphoto == null || _deliid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please upload both photo and proof.')),
      );
      return;
    }

    final photoUrl = await uploadImage(_deliphoto!, 'photos/${_deliphoto!.name}');
    final proofUrl = await uploadImage(_deliid!, 'proofs/${_deliid!.name}');

    if (photoUrl == null || proofUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading files. Please try again.')),
      );
      return;
    }

   
    final shopId = Supabase.instance.client.auth.currentUser?.id;
    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Shop ID not found. Please try again.')),
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
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data inserted successfully!')),
    );
  } catch (e) {
    print("Error inserting data: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error inserting data: $e')),
    );
  }
}


  @override
  void initState() {
    super.initState();

  }

  @override
@override
Widget build(BuildContext context) {
  return Center(
    child: Container(
      width: 400,
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
            TextFormField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: _repassEditingController,
              decoration: InputDecoration(labelText: 'Re-enter Password', border: OutlineInputBorder()),
              obscureText: true,
            ),
            SizedBox(height: 12),

            // Photo Upload
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickImage(true), // Photo
                    child: Text(_deliphoto != null
                        ? 'Photo Selected: ${_deliphoto!.name}'
                        : 'Upload DeliveryBoy Photo'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),

            // Proof Upload
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _pickImage(false), // Proof
                    child: Text(_deliid != null
                        ? 'Proof Selected: ${_deliid!.name}'
                        : 'Upload DeliveryBoy Proof'),
                  ),
                ),
              ],
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
  );
}
}
