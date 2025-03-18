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
  int bookingStatus = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrderData();
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

  Future<void> fetchItems() async {
    final response = await Supabase.instance.client
        .from('tbl_cart')
        .select("*,tbl_item(*)")
        .eq('booking_id', widget.bid);

    setState(() {
      orderItems = response.map((item) => {
        'id': item['cart_id'],
        'product': item['tbl_item']['item_name'],
        'image': item['tbl_item']['item_photo'],
        'qty': item['cart_qty'],
        'price': item['tbl_item']['item_rentprice'],
        'total': item['tbl_item']['item_rentprice'] * item['cart_qty'],
        'status': item['cart_status'],
        'booking': item['booking_id'],
      }).toList();
    });
  }

  Future<void> fetchUserDetails() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select("*, tbl_user(*)")
        .eq('booking_id', widget.bid)
        .single();

    setState(() => userDetails = response['tbl_user']);
  }

  Future<void> fetchBookingStatus() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select('booking_status')
        .eq('booking_id', widget.bid)
        .single();

    setState(() => bookingStatus = response['booking_status']);
  }

  Future<void> _updateCartStatus(int cartId, int status) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Status Change"),
        content: const Text("Are you sure you want to update this status?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Confirm")),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': status})
          .eq('cart_id', cartId);

      setState(() {
        orderItems = orderItems.map((item) {
          if (item['id'] == cartId) {
            item['status'] = status;
          }
          return item;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Cart status updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating cart status: $e")),
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
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text("Qty: ${item['qty']} - Total: \$${item['total']}"),
                                  trailing: ElevatedButton(
                                    onPressed: item['status'] == 3
                                        ? null
                                        : () => _updateCartStatus(item['id'], item['status'] == 2 ? 3 : 2),
                                    child: Text(
                                      item['status'] == 3
                                          ? "Completed"
                                          : item['status'] == 2
                                              ? "Complete"
                                              : "Confirm",
                                    ),
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
