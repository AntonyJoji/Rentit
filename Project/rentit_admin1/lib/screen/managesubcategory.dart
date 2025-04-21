import 'package:flutter/material.dart';
import 'package:rentit_admin1/main.dart';

class ManageSubcategory extends StatefulWidget {
  const ManageSubcategory({super.key});

  @override
  State<ManageSubcategory> createState() => _ManageSubcategoryState();
}

class _ManageSubcategoryState extends State<ManageSubcategory> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormVisible = false;
  bool _isLoading = true;
  String? selectedCategory;
  List<Map<String, dynamic>> subCategoryList = [];
  List<Map<String, dynamic>> categoryList = [];

  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController subCategoryController = TextEditingController();

  Future<void> fetchCategories() async {
    try {
      final response = await supabase.from('tbl_category').select();
      if (mounted) {
        setState(() {
          categoryList = List<Map<String, dynamic>>.from(response);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching categories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> fetchSubcategories() async {
    try {
      setState(() => _isLoading = true);
      final response = await supabase.from('tbl_subcategory').select('*,tbl_category(*)');
      if (mounted) {
        setState(() {
          subCategoryList = List<Map<String, dynamic>>.from(response);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error fetching subcategories: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> addSubcategory() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isLoading = true);
      String subCategoryName = subCategoryController.text.trim();

      await supabase.from('tbl_subcategory').insert({
        'subcategory_name': subCategoryName,
        'category_id': int.parse(selectedCategory!),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subcategory added successfully'),
          backgroundColor: Colors.green,
        ),
      );

      subCategoryController.clear();
      setState(() {
        selectedCategory = null;
        _isFormVisible = false;
      });
      await fetchSubcategories();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding subcategory: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> deleteSubcategory(String subcategoryId) async {
    try {
      await supabase.from('tbl_subcategory').delete().eq('subcategory_id', subcategoryId);
      setState(() {
        subCategoryList.removeWhere((subcategory) => 
          subcategory['subcategory_id'].toString() == subcategoryId
        );
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Subcategory deleted successfully'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting subcategory: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchCategories();
    fetchSubcategories();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.category_outlined,
                              color: Colors.orange,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Manage Subcategories',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[900],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Add and manage product subcategories',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _isFormVisible = !_isFormVisible);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFormVisible ? Colors.red : Colors.orange,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: Icon(_isFormVisible ? Icons.close : Icons.add),
                        label: Text(_isFormVisible ? "Cancel" : "Add Subcategory"),
                      ),
                    ],
                  ),
                  AnimatedSize(
                    duration: _animationDuration,
                    curve: Curves.easeInOut,
                    child: _isFormVisible ? Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withOpacity(0.1)),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedCategory,
                                decoration: InputDecoration(
                                  labelText: "Select Category",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null) return 'Please select a category';
                                  return null;
                                },
                                onChanged: (newValue) {
                                  setState(() => selectedCategory = newValue);
                                },
                                items: categoryList.map((category) {
                                  return DropdownMenuItem<String>(
                                    value: category['category_id'].toString(),
                                    child: Text(category['category_name']),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: subCategoryController,
                                decoration: InputDecoration(
                                  labelText: "Subcategory Name",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter a subcategory name';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton(
                              onPressed: _isLoading ? null : addSubcategory,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Text("Add Subcategory"),
                            ),
                          ],
                        ),
                      ),
                    ) : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : subCategoryList.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            'No subcategories found',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.grey[50]),
                          columns: const [
                            DataColumn(
                              label: Text(
                                "Sl.No",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Category",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Subcategory",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                "Actions",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                          rows: subCategoryList.asMap().entries.map((entry) {
                            return DataRow(
                              cells: [
                                DataCell(Text((entry.key + 1).toString())),
                                DataCell(Text(entry.value['tbl_category']['category_name'])),
                                DataCell(Text(entry.value['subcategory_name'])),
                                DataCell(
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                                    onPressed: () {
                                      showDialog(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          title: const Text('Delete Subcategory'),
                                          content: const Text('Are you sure you want to delete this subcategory?'),
                                          actions: [
                                            TextButton(
                                              onPressed: () => Navigator.pop(context),
                                              child: const Text('Cancel'),
                                            ),
                                            TextButton(
                                              onPressed: () {
                                                Navigator.pop(context);
                                                deleteSubcategory(entry.value['subcategory_id'].toString());
                                              },
                                              style: TextButton.styleFrom(foregroundColor: Colors.red),
                                              child: const Text('Delete'),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
