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
  Map<String, dynamic>? userDetails;
  Map<String, dynamic>? bookingDetails;
  bool isLoading = true;
  String? selectedDeliveryBoy;
  List<Map<String, dynamic>> deliveryBoys = [];

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
        fetchBookingDetails(),
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

  Future<void> fetchBookingDetails() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select('*')
        .eq('booking_id', widget.bid)
        .single();

    setState(() {
      bookingDetails = response;
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
                'status': item['cart_status'],
              })
          .toList();
    });
  }

  Future<void> fetchDeliveryBoys() async {
    final response = await Supabase.instance.client.from('tbl_deliveryboy').select('*');
    setState(() {
      deliveryBoys = List<Map<String, dynamic>>.from(response);
    });
  }

  Future<void> markAsDelivered(int cartId) async {
    try {
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': 5}).eq('cart_id', cartId);

      setState(() {
        orderItems = orderItems.map((item) {
          if (item['id'] == cartId) {
            item['status'] = 5;
          }
          return item;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Marked as Delivered!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating status: $e")),
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
                  if (userDetails != null)
                    Card(
                      child: ListTile(
                        title: Text("Name: ${userDetails!['user_name']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Address: ${userDetails!['user_address']}"),
                            Text("Contact: ${userDetails!['user_contact']}"),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (bookingDetails != null)
                    Card(
                      child: ListTile(
                        title: Text("Booking Date: ${bookingDetails!['booking_date']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Return Date: ${bookingDetails!['return_date']}"),
                            Text("Total Price: \$${bookingDetails!['booking_totalprice']}"),
                            Text("Payment Status: ${bookingDetails!['payment_status']}"),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    value: selectedDeliveryBoy,
                    hint: const Text("Select Delivery Boy"),
                    items: deliveryBoys.map((boy) {
                      return DropdownMenuItem(
                        value: boy['boy_id'].toString(),
                        child: Text(boy['boy_name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedDeliveryBoy = value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: orderItems.isEmpty
                        ? const Center(child: Text("No items in this order"))
                        : ListView.builder(
                            itemCount: orderItems.length,
                            itemBuilder: (context, index) {
                              final item = orderItems[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  leading: Image.network(
                                    item['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  title: Text(item['product']),
                                  subtitle: Text("Quantity: ${item['qty']}"),
                                  trailing: ElevatedButton(
                                    onPressed: item['status'] == 5 ? null : () => markAsDelivered(item['id']),
                                    child: const Text("Mark as Delivered"),
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
