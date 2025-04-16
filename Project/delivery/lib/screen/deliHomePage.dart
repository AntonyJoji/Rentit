import 'package:delivery/screen/delidetails.dart';
import 'package:delivery/screen/delihistory.dart';
import 'package:delivery/screen/login.dart' show deliLoginPage;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryBoyHomePage extends StatefulWidget {
  final String boyId;
  const DeliveryBoyHomePage({super.key, required this.boyId});

  @override
  State<DeliveryBoyHomePage> createState() => _DeliveryBoyHomePageState();
}

class _DeliveryBoyHomePageState extends State<DeliveryBoyHomePage> {
  List<dynamic> deliveries = [];
  bool isLoading = true;
  String boyName = '';
  bool isNameLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBoyName();
    fetchDeliveries();
  }

  // Fetch the name of the delivery boy
  Future<void> fetchBoyName() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_deliveryboy')
          .select('boy_name')
          .eq('boy_id', widget.boyId)
          .maybeSingle();

      setState(() {
        boyName = response?['boy_name'] ?? 'Name not found';
        isNameLoading = false;
      });
    } catch (e) {
      print('Error fetching delivery boy name: $e');
      setState(() {
        boyName = 'Error loading name';
        isNameLoading = false;
      });
    }
  }

  // Fetch assigned deliveries for the delivery boy
  Future<void> fetchDeliveries() async {
    setState(() => isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('tbl_cart')
          .select(
              'cart_id, cart_qty, boy_id, booking_id, cart_status, tbl_booking(booking_id, user_id), tbl_item(item_name,item_rentprice)')
          .inFilter('cart_status', [3, 5])
          .eq('boy_id', widget.boyId);

      // Fetch user_name for each delivery using user_id
      for (var delivery in response) {
        final userId = delivery['tbl_booking']?['user_id'];
        final userResponse = await Supabase.instance.client
            .from('tbl_user')
            .select('user_name')
            .eq('user_id', userId)
            .maybeSingle();

        delivery['user_name'] =
            userResponse?['user_name'] ?? 'Unknown User';
      }

      setState(() {
        deliveries = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching deliveries: $e');
      setState(() => isLoading = false);
    }
  }

  // Logout method
  void logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => deliLoginPage()),
    );
  }

  // Update delivery status (optional trigger)
  void updateDeliveryStatus(String bookingId) async {
    await Supabase.instance.client
        .from('tbl_booking')
        .update({'delivery_status': 'Picked Up'})
        .eq('booking_id', bookingId);

    fetchDeliveries();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text('Delivery Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
      centerTitle: true,
      actions: [
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: fetchDeliveries,
        ),
      ],
    ),
    drawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.blue),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.delivery_dining, size: 40, color: Colors.blue),
                ),
                SizedBox(height: 8),
                Text('Delivery Agent', style: TextStyle(color: Colors.white, fontSize: 16)),
                SizedBox(height: 4),
                Flexible(
                  child: Text(
                    isNameLoading ? 'Loading name...' : (boyName.isNotEmpty ? boyName : 'No name found'),
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.history),
            title: Text('Delivery History'),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryHistoryPage()));
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text('Settings'),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.logout),
            title: Text('Logout'),
            onTap: logout,
          ),
        ],
      ),
    ),
    body: Padding(
      padding: EdgeInsets.all(16.0),
      child: isLoading
          ? Center(child: CircularProgressIndicator())
          : deliveries.isEmpty
              ? Center(child: Text("No assigned deliveries"))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assigned Deliveries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),

                      // Displaying "Items to Deliver"
                      Text('Items to Deliver', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: deliveries.where((delivery) => delivery['cart_status'] != 5).length,
                        itemBuilder: (context, index) {
                          final delivery = deliveries.where((delivery) => delivery['cart_status'] != 5).toList()[index];
                          final itemName = delivery['tbl_item']['item_name'];
                          final quantity = delivery['cart_qty'];
                          final userName = delivery['user_name'];
                          final cartStatus = delivery['cart_status'];

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(
                                Icons.local_shipping,
                                color: cartStatus == 5 ? Colors.orange : Colors.blue,
                                size: 36,
                              ),
                              title: Text(
                                'Item: $itemName',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Quantity: $quantity\nUser: $userName'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  updateDeliveryStatus(delivery['booking_id']);
                                },
                                child: Text('details'),
                              ),
                              onTap: () {
                                if (delivery != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeliveryDetails(delivery: delivery),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),

                      SizedBox(height: 20),
                      Text('Items to Return', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: deliveries.where((delivery) => delivery['cart_status'] == 5).length,
                        itemBuilder: (context, index) {
                          final delivery = deliveries.where((delivery) => delivery['cart_status'] == 5).toList()[index];
                          final itemName = delivery['tbl_item']['item_name'];
                          final quantity = delivery['cart_qty'];
                          final userName = delivery['user_name'];
                          final cartStatus = delivery['cart_status'];

                          return Card(
                            elevation: 4,
                            margin: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: Icon(
                                Icons.local_shipping,
                                color: cartStatus == 5 ? Colors.orange : Colors.blue,
                                size: 36,
                              ),
                              title: Text(
                                'Item: $itemName',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Text('Quantity: $quantity\nUser: $userName'),
                              trailing: ElevatedButton(
                                onPressed: () {
                                  updateDeliveryStatus(delivery['booking_id']);
                                },
                                child: Text('details'),
                              ),
                              onTap: () {
                                if (delivery != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DeliveryDetails(delivery: delivery),
                                    ),
                                  );
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
    ),
  );
}
}