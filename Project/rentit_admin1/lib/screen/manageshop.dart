import 'package:flutter/material.dart';
//import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:rentit_admin1/main.dart';

class Manageshop extends StatefulWidget {
  const Manageshop({super.key});

  @override
  _ManageshopState createState() => _ManageshopState();
}

class _ManageshopState extends State<Manageshop> {
  List<Map<String, dynamic>> shops = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchShops();
  }

  // Fetch list of shops from Supabase
  Future<void> fetchShops() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final response = await supabase
          .from("tbl_shop")
          .select()
          .eq('shop_vstatus', 0);
      
      print("Fetched Pending Shops Data: $response");
      
      setState(() {
        shops = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching shops: $e");
      setState(() {
        errorMessage = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // Approve shop
  Future<void> approveShop(String shopId) async {
    try {
      await supabase
          .from('tbl_shop')
          .update({'shop_vstatus': 1})
          .eq('shop_id', shopId);
      
      fetchShops();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shop Approved!"))
      );
    } catch (e) {
      print("Error approving shop: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to approve shop."))
      );
    }
  }

  // Reject shop
  Future<void> rejectShop(String shopId) async {
    try {
      await supabase
          .from('tbl_shop')
          .update({'shop_vstatus': 2})
          .eq('shop_id', shopId);
      
      fetchShops();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Shop Rejected!"))
      );
    } catch (e) {
      print("Error rejecting shop: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to reject shop."))
      );
    }
  }

  // View proof image in full screen
  void _viewProofImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AspectRatio(
              aspectRatio: 1,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                          : null,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(
                    child: Text('Error loading image', style: TextStyle(color: Colors.red)),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0)
      ),
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop["shop_name"] ?? 'N/A',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black
                        ),
                      ),
                      SizedBox(height: 8),
                      Text("Email: ${shop["shop_email"] ?? 'N/A'}"),
                      Text("Contact: ${shop["shop_contact"] ?? 'N/A'}"),
                      Text("Address: ${shop["shop_address"] ?? 'N/A'}"),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                if (shop["shop_proof"] != null)
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: GestureDetector(
                      onTap: () => _viewProofImage(shop["shop_proof"]),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            shop["shop_proof"],
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(Icons.error, color: Colors.red),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => approveShop(shop['shop_id']),
                      icon: Icon(Icons.check_circle, color: Colors.white),
                      label: Text(
                        "Approve",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 194, 170, 250),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => rejectShop(shop['shop_id']),
                      icon: Icon(Icons.cancel, color: Colors.white),
                      label: Text(
                        "Reject",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color.fromARGB(255, 194, 170, 250),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }
    
    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage, style: TextStyle(color: Colors.red)));
    }
    
    if (shops.isEmpty) {
      return Center(child: Text('No pending shops to display'));
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: shops.map((shop) => _buildShopCard(shop)).toList(),
      ),
    );
  }
}
