import 'package:flutter/material.dart';
import 'package:rentit_admin1/main.dart';

class Manageplace extends StatefulWidget {
  const Manageplace({super.key});

  @override
  State<Manageplace> createState() => _ManageplaceState();
}

class _ManageplaceState extends State<Manageplace>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormVisible = false; // To manage form visibility
  String? selectedDist; // Changed to nullable to handle unselected state
  List<Map<String, dynamic>> placeList = [];
  List<Map<String, dynamic>> _distList = [];
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController placeController = TextEditingController();
  

  Future<void> Manageplace() async {
    try {
      String place = placeController.text;
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
      placeController.clear();
      setState(() {
        selectedDist = null; // Reset selection
      });
       fetchPlace();
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
  Future<void> fetchPlace() async {
    try {
      final response = await supabase.from('tbl_place').select('*,tbl_district(*)');
      // print(response);
      setState(() {
        placeList = List<Map<String, dynamic>>.from(response);
      });
      display();
    } catch (e) {
      print("ERROR FETCHING DISTRICT DATA: $e");
    }
  }
   void display(){
    print(placeList);
  }
  

  @override
  void initState() {
    super.initState();
    fetchDist();
    fetchPlace();

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
              const Text("Manage Place"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text(_isFormVisible ? "Cancel" : "Add Place"),
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
                          "Place Form",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
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
                                },
                                items: _distList.map((district) {
                                  return DropdownMenuItem<String>(
                                    value: district['id'].toString(),
                                    child: Text(district['district_name']),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: placeController,
                                decoration: const InputDecoration(
                                  labelText: "Place Name",
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            ElevatedButton(
                              onPressed: () {
                                Manageplace();
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

              DataColumn(label: Text("place")),
              DataColumn(label: Text("Delete")),
            ],
            rows: placeList.asMap().entries.map((entry) {
              print(entry.value);
              return DataRow(cells: [
                DataCell(Text((entry.key + 1).toString())), // Serial number
                DataCell(Text(entry.value['tbl_district']['district_name'])),

                DataCell(Text(entry.value['place_name'])),
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