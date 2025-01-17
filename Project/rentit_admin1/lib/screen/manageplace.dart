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
  final Duration _animationDuration = const Duration(milliseconds: 300);
  final TextEditingController placeController = TextEditingController();

Future<void> Manageplace() async{
  try {
    String place = placeController.text;
    await supabase.from('tbl_place').insert({
      'place_name':place,
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content:Text(
          'place added',
          style:TextStyle(color:Colors.white),
        ),
        backgroundColor: Colors.green,
         ),
    );
    print("Inserted");
    placeController.clear();
  } catch(e){
    print("Error adding place");
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
              const Text("Manage Place"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label:Text(_isFormVisible ? "Cancel":"Add place"),
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
                          "Place Form",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
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
          Container(
            height: 500,
            child: const Center(
              child: Text("Place Data"),
            ),
          ),
        ],
      ),
    );
  }
}
