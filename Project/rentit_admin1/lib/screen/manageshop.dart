import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert'; // To decode JSON responses

class Manageshop extends StatefulWidget {
  const Manageshop({super.key});

  @override
  _ManageshopState createState() => _ManageshopState();
}

class _ManageshopState extends State<Manageshop> {
  List<Map<String, dynamic>> shops = [];

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  // Fetch list of shops from the backend API
  Future<void> fetchShops() async {
    final response = await http.get(Uri.parse('https://yourapi.com/getShops'));

    if (response.statusCode == 200) {
      // Parse the response and update the state
      setState(() {
        shops = List<Map<String, dynamic>>.from(json.decode(response.body));
      });
    } else {
      // Handle error
      print('Failed to load shops');
    }
  }

  // Approve shop
  Future<void> approveShop(int shopId) async {
    final response = await http.post(
      Uri.parse('https://yourapi.com/approveShop'),
      body: {'shop_id': shopId.toString()},
    );

    if (response.statusCode == 200) {
      // On success, reload the shop list
      fetchShops();
    } else {
      // Handle error
      print('Failed to approve shop');
    }
  }

  // Reject shop
  Future<void> rejectShop(int shopId) async {
    final response = await http.post(
      Uri.parse('https://yourapi.com/rejectShop'),
      body: {'shop_id': shopId.toString()},
    );

    if (response.statusCode == 200) {
      // On success, reload the shop list
      fetchShops();
    } else {
      // Handle error
      print('Failed to reject shop');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // Wrapping the content in a scrollable view
      child: Center(
        child: shops.isEmpty
            ? CircularProgressIndicator() // Loading indicator
            : ListView.builder(
                itemCount: shops.length,
                shrinkWrap: true, // Ensures the ListView uses only the required space
                physics: NeverScrollableScrollPhysics(), // Disables the internal scrolling
                itemBuilder: (context, index) {
                  var shop = shops[index];
                  return Card(
                    margin: EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(shop['shop_name']),
                      subtitle: Text(shop['shop_address']),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.check_circle),
                            onPressed: () {
                              approveShop(shop['shop_id']);
                            },
                            tooltip: 'Approve',
                          ),
                          IconButton(
                            icon: Icon(Icons.cancel),
                            onPressed: () {
                              rejectShop(shop['shop_id']);
                            },
                            tooltip: 'Reject',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                      contentPadding: EdgeInsets.all(10),
                      leading: Icon(Icons.store),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
