import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shop/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class addProduct extends StatefulWidget {
  const addProduct({super.key});

  @override
  _addProductState createState() => _addProductState();
}

class _addProductState extends State<addProduct> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _detailsController = TextEditingController();

  String? _selectedCategory;
  String? _selectedSubcategory;

  List<Map<String, dynamic>> categories = [];
  List<Map<String, dynamic>> subcategories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  PlatformFile? pickedImage;

  Future<void> handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      allowMultiple: false, // Only single file upload
    );
    if (result != null) {
      setState(() {
        pickedImage = result.files.first;
      });
    }
  }

  Future<String?> photoUpload() async {
    try {
      final bucketName = 'shop'; // Replace with your bucket name
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileExtension =
          pickedImage!.name.split('.').last; // Get the file extension
      final fileName =
          "${timestamp}.${fileExtension}"; // New file name with timestamp
      final filePath = fileName;

      await supabase.storage.from(bucketName).uploadBinary(
            filePath,
            pickedImage!.bytes!, // Use file.bytes for Flutter Web
          );

      final publicUrl =
          supabase.storage.from(bucketName).getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      print("Error photo upload: $e");
      return null;
    }
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

 Future<void> _submitProduct() async {
  try {
    String? url = await photoUpload(); 
    
    // Get current shop ID from auth
    final shopId = Supabase.instance.client.auth.currentUser?.id;
    if (shopId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Error: Unable to get shop ID. Please login again."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final response = await Supabase.instance.client.from('tbl_item').insert({
      'item_name': _nameController.text,
      'category_id': int.parse(_selectedCategory!),
      'subcategory_id': int.parse(_selectedSubcategory!),
      'item_rentprice': double.parse(_priceController.text),
      'item_detail': _detailsController.text,
      'item_photo': url,
      'shop_id': shopId, // Add shop_id to associate product with current shop
    });

    print("Product added successfully: $response");

    // Clear fields after insertion
    setState(() {
      _nameController.clear();
      _priceController.clear();
      _detailsController.clear();
      pickedImage = null;
      _selectedCategory = null;
      _selectedSubcategory = null;
    });
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Product added successfully!"),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    print("Error inserting product: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Error adding product: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}



  @override
Widget build(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Reduced horizontal padding
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
                  "ADD PRODUCT",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                
                // Item Name Field
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: "Item Name"),
                ),
                
                const SizedBox(height: 10), // Adjusted spacing between elements

                // Category Dropdown
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
                
                const SizedBox(height: 10), // Adjusted spacing

                // Subcategory Dropdown
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
                
                const SizedBox(height: 10), // Adjusted spacing

                // Rental Price Field
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "Rental Price"),
                ),
                
                const SizedBox(height: 10), // Adjusted spacing

                // Details Field
                TextField(
                  controller: _detailsController,
                  decoration: const InputDecoration(labelText: "Details"),
                  maxLines: 3,
                ),
                
                const SizedBox(height: 20),

                // Image Picker
                SizedBox(
                  height: 100, // Reduced height for image picker
                  width: 100,  // Reduced width for image picker
                  child: pickedImage == null
                      ? GestureDetector(
                          onTap: handleImagePick,
                          child: Icon(
                            Icons.add_a_photo,
                            color: Color(0xFF0277BD),
                            size: 50,
                          ),
                        )
                      : GestureDetector(
                          onTap: handleImagePick,
                          child: ClipRRect(
                            child: pickedImage!.bytes != null
                                ? Image.memory(
                                    Uint8List.fromList(
                                        pickedImage!.bytes!), // For web
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(pickedImage!.path!), // For mobile/desktop
                                    fit: BoxFit.cover,
                                  ),
                          ),
                        ),
                ),
                
                const SizedBox(height: 10),

                // Add Item Button
                ElevatedButton(
                  onPressed: _submitProduct,
                  child: const Text("Add Item"),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}