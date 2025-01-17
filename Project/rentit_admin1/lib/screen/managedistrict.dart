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
            'district added',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.green,
        ),
      );
      print("Inserted");
      districtController.clear();
    } catch (e) {
      print("Error adding district:$e");
    }
  }

  Future<void> fetchDistrict() async {
    try {
      final response = await supabase.from('tbl_district').select();
      // print(response);
      setState(() {
        districtList = List<Map<String, dynamic>>.from(response);
      });
      display();
    } catch (e) {
      print("ERROR FETCHING DISTRICT DATA: $e");
    }
  }

  void display(){
    print(districtList);
  }

  @override
  void initState() {
    // TODO: implement initState
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
              const Text("Manage district"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text(_isFormVisible ? "Cancel" : "Add district"),
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
                          "district Form",
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
                                  labelText: "district Name",
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
            columns: [
              DataColumn(label: Text("Sl.No")),
              DataColumn(label: Text("District")),
              DataColumn(label: Text("DElete")),
            ],
            rows: districtList.asMap().entries.map((entry) {
              print(entry.value);
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())), // Serial number
                DataCell(Text(entry.value['district_name'])),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      // _deleteAcademicYear(docId); // Delete academic year
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
