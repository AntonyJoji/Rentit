import 'package:flutter/material.dart';
import 'package:rentit_admin1/main.dart';

class subCategory extends StatefulWidget {
  const subCategory ({super.key});

  @override
  State<subCategory> createState() => _subCategoryState();
}

class _subCategoryState extends State<subCategory>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormVisible = false; // To manage form visibility 
  String? selectedCategory; // Changed to nullable to handle unselected state
  List<Map<String, dynamic>> subCategoryList = [];
  List<Map<String, dynamic>> categoryList = [];

  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController subCategoryController = TextEditingController();
  

  Future<void> fetchcategory() async {
    try {
      final response = await supabase.from('tbl_category').select();
      if (response.isNotEmpty) {
        print(response);
        setState(() {
          categoryList = response;
        });
      }
    } catch (e) {
      print("Error fetching categories: $e");
    }
  }

  Future<void> fetchsubcategory() async {
    try {
      final response = await supabase.from('tbl_subcategory').select('*,tbl_category(*)');
      setState(() {
        subCategoryList = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      print("Error fetching subcategories: $e");
    }
  }

  Future<void> subCategory() async {
    try {
      String subCategoryName = subCategoryController.text;
      if (selectedCategory == null || subCategoryName.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a Category and enter a Subcategory name"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      await supabase.from('tbl_subcategory').insert({
        'subcategory_name': subCategoryName,
        'category_id': int.parse(selectedCategory!), // Ensure integer type
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Subcategory added successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );

      subCategoryController.clear();
      setState(() {
        selectedCategory = null; // Reset selection
      });
      fetchsubcategory(); // Refresh subcategories instead of categories
    } catch (e) {
      print("Error adding subcategory: $e");
    }
  }

  Future<void> delsubcategory(String did) async {
   try {
      await supabase.from('tbl_subcategory').delete().eq('subcategory_id', did);
      fetchsubcategory();
   } catch (e) {
     print("ERROR: $e");
   }
  }

  @override
  void initState() {
    super.initState();
    fetchcategory();
    fetchsubcategory();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Manage subcategory"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text(_isFormVisible ? "Cancel" : "Add subcategory"),
                icon: Icon(_isFormVisible ? Icons.cancel : Icons.add),
              ),
            ],
          ),
          AnimatedSize(
            duration: _animationDuration,
            curve: Curves.easeInOut,
            child: _isFormVisible
                ? Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Subcategory Form",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory,
                                hint: const Text("Select category"),
                                onChanged: (newValue) {
                                  setState(() {
                                    selectedCategory = newValue;
                                  });
                                },
                                items: categoryList.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category['category_id'].toString(),
                                    child: Text(category['category_name']),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: subCategoryController,
                                decoration: const InputDecoration(
                                  labelText: "Subcategory Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                subCategory();
                              },
                              child: const Text("Add"),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          DataTable(
            columns: [
              DataColumn(label: Text("Sl.No")),
              DataColumn(label: Text("Category")),
              DataColumn(label: Text("Subcategory")),
              DataColumn(label: Text("Delete")),
            ],
            rows: subCategoryList.asMap().entries.map((entry) {
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())), // Serial number
                DataCell(Text(entry.value['tbl_category']['category_name'])),
                DataCell(Text(entry.value['subcategory_name'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      delsubcategory(entry.value['subcategory_id'].toString());
                      fetchsubcategory();
                    },
                  ),
                ),
              ]);
            }).toList(),
          )
        ],
      ),
    );
  }
}
