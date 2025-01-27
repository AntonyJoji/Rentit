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
  

  Future<void> subCategory() async {
    try {
      String subCategory =subCategoryController.text;
      if (selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select a subCategory"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      await supabase.from('tbl_subCategory').insert({
        'subCategory_name': subCategory,
        'category_id': selectedCategory, // Ensure district_id is added
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'subcategory added successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      subCategoryController.clear();
      setState(() {
        selectedCategory = null; // Reset selection
      });
       fetchcategory();
    } catch (e) {
      print("Error adding subcategory: $e");
    }
  }

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
      print("Error fetching districts: $e");
    }
  }
  Future<void> fetchsubcategory() async {
    try {
      final response = await supabase.from('tbl_subcategory').select('*,tbl_category(*)');
      // print(response);
      setState(() {
        subCategoryList = List<Map<String, dynamic>>.from(response);
      });
      display();
    } catch (e) {
      print("ERROR FETCHING category DATA: $e");
    }
  }
   void display(){
    print(subCategoryList);
  }

  Future<void> delsubcategory(String did) async {
   try {
      await supabase.from('tbl_subcategory').delete().eq('subcategory_id', did);
    fetchcategory();
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
                          "subcategory Form",
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
                                  labelText: "subcategory Name",
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
              DataColumn(label: Text("category")),

              DataColumn(label: Text("subcategory")),
              DataColumn(label: Text("Delete")),
            ],
            rows: subCategoryList.asMap().entries.map((entry) {
              print(entry.value);
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())), // Serial number
                DataCell(Text(entry.value['tbl_category']['category_name'])),

                DataCell(Text(entry.value['subcategory_name'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {delsubcategory(entry.value['subcategory_id'].toString());
                      // _deleteAcademicYear(docId); // Delete academic year
                      fetchcategory();
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