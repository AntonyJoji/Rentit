import 'package:flutter/material.dart';
import 'package:rentit_admin1/main.dart';

class category extends StatefulWidget {
  const category({super.key});

  @override
  State<category> createState() => _categoryState();
}

class _categoryState extends State<category>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController categoryController = TextEditingController();

  List<Map<String, dynamic>> categoryList = [];

  Future<void> category() async {
    try {
      String category = categoryController.text;
      await supabase.from('tbl_category').insert({
        'category_name': category,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'category added',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      print("Inserted");
      categoryController.clear();
      fetchcategory();
    } catch (e) {
      print("Error adding category:$e");
    }
  }

  Future<void> fetchcategory() async {
    try {
      final response = await supabase.from('tbl_category').select();
      setState(() {
        categoryList = (response);
      });
      display();
    } catch (e) {
      print("ERROR FETCHING category DATA: $e");
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    try {
      await supabase.from('tbl_category').delete().eq('category_id', categoryId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Category deleted',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      fetchcategory();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }

  void display() {
    print(categoryList);
  }

  @override
  void initState() {
    super.initState();
    fetchcategory();
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
              const Text("Manage category"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text(_isFormVisible ? "Cancel" : "Add category"),
                icon: Icon(_isFormVisible ? Icons.cancel : Icons.add),
              )
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
                          "category Form",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: categoryController,
                                decoration: const InputDecoration(
                                  labelText: "category Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                category();
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
              DataColumn(label: Text("Delete")),
            ],
            rows: categoryList.asMap().entries.map((entry) {
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())), // Serial number
                DataCell(Text(entry.value['category_name'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      deleteCategory(entry.value['category_id'].toString());
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