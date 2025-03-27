import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final int bid;
  const OrderDetailsPage({super.key, required this.bid});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  List<Map<String, dynamic>> orderItems = [];
  List<Map<String, dynamic>> deliveryBoys = [];
  Map<String, dynamic>? userDetails;
  int bookingStatus = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderData();
    fetchDeliveryBoys();
  }

  Future<void> fetchOrderData() async {
    try {
      await Future.wait([
        fetchItems(),
        fetchUserDetails(),
        fetchBookingStatus(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserDetails() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select('tbl_user:user_id(*)')
        .eq('booking_id', widget.bid)
        .single();

    setState(() {
      userDetails = response['tbl_user'];
    });
  }

  Future<void> fetchBookingStatus() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select('booking_status')
        .eq('booking_id', widget.bid)
        .single();

    setState(() {
      bookingStatus = response['booking_status'];
    });
  }

  Future<void> fetchDeliveryBoys() async {
    final response =
        await Supabase.instance.client.from('tbl_deliveryboy').select('*');
    setState(() {
      deliveryBoys = response
          .map((boy) => {
                'id': boy['boy_id'],
                'name': boy['boy_name'],
              })
          .toList();
    });
  }

  Future<void> fetchItems() async {
    final response = await Supabase.instance.client
        .from('tbl_cart')
        .select("*,tbl_item(*)")
        .eq('booking_id', widget.bid);

    setState(() {
      orderItems = response
          .map((item) => {
                'id': item['cart_id'],
                'product': item['tbl_item']['item_name'],
                'image': item['tbl_item']['item_photo'],
                'qty': item['cart_qty'],
                'price': item['tbl_item']['item_rentprice'],
                'total': item['tbl_item']['item_rentprice'] * item['cart_qty'],
                'status': item['cart_status'],
                'booking': item['booking_id'],
                'boy_id': item['boy_id'] ?? '',
              })
          .toList();
    });
  }

  Future<void> assignDeliveryBoy(int cartId, String boyId) async {
    try {
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'boy_id': boyId, 'cart_status': 4}).eq('cart_id', cartId);

      setState(() {
        orderItems = orderItems.map((item) {
          if (item['id'] == cartId) {
            item['boy_id'] = boyId;
            item['status'] = 4;
          }
          return item;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Delivery boy assigned successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error assigning delivery boy: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 250),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Details",
                    style: GoogleFonts.sanchez(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (userDetails != null) ...[
                    Text("User Name: ${userDetails!['user_name']}",
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Contact: ${userDetails!['user_contact']}"),
                    Text("Address: ${userDetails!['user_address']}"),
                    const SizedBox(height: 20),
                  ],
                  Expanded(
                    child: orderItems.isEmpty
                        ? const Center(child: Text("No items in this order"))
                        : ListView.builder(
                            itemCount: orderItems.length,
                            itemBuilder: (context, index) {
                              final item = orderItems[index];
                              return Card(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(12.0),
                                  leading: Image.network(
                                    item['image'],
                                    height: 100,
                                    width: 100,
                                    fit: BoxFit.cover,
                                  ),
                                  title: Text(
                                    item['product'],
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                          "Qty: ${item['qty']} - Total: \$${item['total']}")
                                      ,
                                      DropdownButton<String>(
                                        value: item['boy_id']?.toString().isNotEmpty == true
                                            ? item['boy_id'].toString()
                                            : null,
                                        hint: const Text("Assign Delivery Boy"),
                                        items: deliveryBoys.map((boy) {
                                          return DropdownMenuItem<String>(
                                            value: boy['id'].toString(),
                                            child: Text(boy['name']),
                                          );
                                        }).toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            assignDeliveryBoy(
                                                item['id'], value);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
