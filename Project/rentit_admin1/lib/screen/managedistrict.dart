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

Future<void> Managedistrict() async{
  try {
    String district = districtController.text;
    await supabase.from('tbl_district').insert({
      'district_name':district,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:Text(
          'district added',
          style:TextStyle(color:Colors.white),
        ),
        backgroundColor: Colors.green,
         ),
    );
    print("Inserted");
    districtController.clear();
  } catch(e){
    print("Error adding district:$e");
  }
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
                label:Text(_isFormVisible ? "Cancel":"Add district"),
                icon: Icon(_isFormVisible ? Icons.cancel:Icons.add),
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
          Container(
            height: 500,
            child: const Center(
              child: Text("district Data"),
            ),
          ),
        ],
      ),
    );
  }
}
