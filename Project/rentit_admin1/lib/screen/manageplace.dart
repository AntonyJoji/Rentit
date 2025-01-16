import 'package:flutter/material.dart';

class Manageplace extends StatefulWidget {
  const Manageplace ({super.key});

  @override
  State<Manageplace> createState() => _ManageplaceState();
}

class _ManageplaceState extends State<Manageplace>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool _isFormVisible = false; // To manage form visibility
  final Duration _animationDuration = const Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Manage Place"),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _isFormVisible = !_isFormVisible; // Toggle form visibility
                  });
                },
                label: Text("Add Place"),
                icon: Icon(Icons.add),
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
                        TextFormField(
                          decoration: const InputDecoration(
                            labelText: "place Name",
                            border: OutlineInputBorder(),
                          ),
                          
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState!.validate()) {
                              // Handle form submission logic here
                            }
                          },
                          child: const Text("Add"),
                        ),
                      ],
                    ),
                  )
                : Container(),
          ),
          Container(
            height: 500,
            child: Center(
              child: Text("Place Data"),
            ),
          )
        ],
      ),
    );
  }
}
