import 'package:flutter/material.dart';
import 'package:rentit_admin1/main.dart';

class Managedistrict extends StatefulWidget {
  const Managedistrict({super.key});

  @override
  State<Managedistrict> createState() => _ManagedistrictState();
}

class _ManagedistrictState extends State<Managedistrict>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController districtController = TextEditingController();

  List<Map<String, dynamic>> districtList = [];

  Future<void> Managedistrict() async {
    try {
      String district = districtController.text;
      await supabase.from('tbl_district').insert({
        'district_name': district,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'District added',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      districtController.clear();
      fetchDistrict(); // Refresh list after adding
    } catch (e) {
      print("Error adding district: $e");
    }
  }

  Future<void> fetchDistrict() async {
    try {
      final response = await supabase.from('tbl_district').select();
      setState(() {
        districtList = response;
      });
    } catch (e) {
      print("Error fetching districts: $e");
    }
  }

  Future<void> delDistrict(String districtId) async {
    try {
      await supabase.from('tbl_district').delete().eq('district_id', districtId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'District deleted successfully',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
        ),
      );
      fetchDistrict(); // Refresh list after deletion
    } catch (e) {
      print("Error deleting district: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchDistrict();
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
              const Text("Manage District"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text(_isFormVisible ? "Cancel" : "Add District"),
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
                          "District Form",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: districtController,
                                decoration: const InputDecoration(
                                  labelText: "District Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Managedistrict();
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
            columns: const [
              DataColumn(label: Text("Sl.No")),
              DataColumn(label: Text("District")),
              DataColumn(label: Text("Delete")),
            ],
            rows: districtList.asMap().entries.map((entry) {
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())), // Serial number
                DataCell(Text(entry.value['district_name'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      delDistrict(entry.value['district_id'].toString());
                    },
                  ),
                ),
              ]);
            }).toList(),
          ),
        ],
      ),
    );
  }
}
