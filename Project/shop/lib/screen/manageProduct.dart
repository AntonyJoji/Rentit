import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ManageProduct extends StatefulWidget {
  const ManageProduct({super.key});

  @override
  _ManageProductState createState() => _ManageProductState();
}

class _ManageProductState extends State<ManageProduct> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;
  File? _image;
  Uint8List? _webImage;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subcategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    final response =
        await Supabase.instance.client.from('tbl_category').select();
    if (mounted) {
      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _fetchSubcategories(int categoryId) async {
    final response = await Supabase.instance.client
        .from('tbl_subcategory')
        .select()
        .eq('category_id', categoryId);
    if (mounted) {
      setState(() {
        subcategories = List<Map<String, dynamic>>.from(response);
      });
    }
  }

  Future<void> _pickImage() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null) {
      if (kIsWeb) {
        setState(() {
          _webImage = result.files.single.bytes;
        });
      } else {
        setState(() {
          _image = File(result.files.single.path!);
        });
      }
    }
  }

  Future<void> _submitProduct() async {
    if (_nameController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _detailsController.text.isEmpty ||
        _selectedCategory == null ||
        _selectedSubcategory == null ||
        (_image == null && _webImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      String? imageUrl;
      final storage = Supabase.instance.client.storage;
      final fileName = 'items/\${DateTime.now().millisecondsSinceEpoch}.png';

      if (_webImage != null) {
        print("Uploading Web Image: \$fileName");
        await storage.from('shop').uploadBinary(fileName, _webImage!);
        imageUrl = storage.from('shop').getPublicUrl(fileName);
        print("Web Image Uploaded: \$imageUrl");
      } else if (_image != null) {
        print("Uploading File Image: \$fileName");
        await storage.from('shop').upload(fileName, _image!);
        imageUrl = storage.from('shop').getPublicUrl(fileName);
        print("File Image Uploaded: \$imageUrl");
      }

      if (imageUrl == null) {
        throw Exception("Image upload failed");
      }

      print("Inserting into DB...");
      await Supabase.instance.client.from('tbl_item').insert({
        'item_name': _nameController.text,
        'item_rentprice': double.parse(_priceController.text),
        'item_detail': _detailsController.text,
        'item_photo': imageUrl,
        'category_id': int.parse(_selectedCategory!),
        'subcategory_id': int.parse(_selectedSubcategory!),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Item added successfully!")),
      );
    } catch (e) {
      print("Error: \${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: \${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Manage Item",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Item Name"),
                ),
                DropdownButtonFormField(
                  value: _selectedCategory,
                  items: categories.map((category) {
                    return DropdownMenuItem(
                      value: category['category_id'].toString(),
                      child: Text(category['category_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                        _fetchSubcategories(int.parse(value));
                        _selectedSubcategory = null;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: "Category"),
                ),
                DropdownButtonFormField(
                  value: _selectedSubcategory,
                  items: subcategories.map((sub) {
                    return DropdownMenuItem(
                      value: sub['subcategory_id'].toString(),
                      child: Text(sub['subcategory_name']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedSubcategory = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(labelText: "Subcategory"),
                ),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Rental Price"),
                ),
                TextField(
                  controller: _detailsController,
                  decoration: const InputDecoration(labelText: "Details"),
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text("Add Image"),
                ),
                const SizedBox(height: 10),
                if (_image != null || _webImage != null)
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey),
                    ),
                    child: kIsWeb && _webImage != null
                        ? Image.memory(_webImage!, fit: BoxFit.cover)
                        : (_image != null ? Image.file(_image!, fit: BoxFit.cover) : Container()),
                  ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _submitProduct,
                  child: const Text("Add Item"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
