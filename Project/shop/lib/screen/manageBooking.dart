import 'package:flutter/material.dart';
import 'package:shop/screen/order_details_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  final supabase = Supabase.instance.client;

  Future<List<dynamic>> _fetchBookings() async {
    final shopId = supabase.auth.currentUser?.id;
    if (shopId == null) {
      print("Error: Shop ID is null.");
      return [];
    }

    try {
      final response = await supabase
          .from('tbl_booking')
          .select('*, tbl_cart!inner(*, tbl_item!inner(*))')
          .eq('tbl_cart.tbl_item.shop_id',
              shopId) // Correct condition for `shop_id`
          .order('booking_date', ascending: false)
          .then((value) {
        print("Response: $value"); // Debugging output
        return value;
      });

      return response;
    } catch (e) {
      print("Error fetching bookings: $e"); // Catch any exceptions
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _fetchBookings(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Failed to load bookings."));
        } else if (snapshot.data == null || snapshot.data!.isEmpty) {
          return const Center(child: Text("No bookings available"));
        }

        final bookings = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text("Bookings List", style: TextStyle(fontSize: 20)),
              ),
              ListView.builder(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final booking = bookings[index];
                  final cartItems = booking['tbl_cart'] as List<dynamic>? ?? [];

                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text("Booking ID: ${booking['booking_id']}"),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              "Total Price: \$${booking['booking_totalprice']}"),
                          ...cartItems.map((cartItem) {
                            final itemName = cartItem['tbl_item']
                                    ['item_name'] ??
                                'Unknown Item';
                            final itemStatus = cartItem['cart_status'] == 1
                                ? 'Confirmed'
                                : cartItem['cart_status'] == 2
                                    ? 'Pending'
                                    : cartItem['cart_status'] == 3
                                        ? 'item'
                                        : 'Unknown Status';

                            return Text("$itemName - Status: $itemStatus");
                          }).toList(),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderDetailsPage(
                                bid: booking['booking_id'],
                              ),
                            ),
                          );
                        },
                        child: const Text("View Details"),
                      ),
                    ),
                  );
                },
              )
            ],
          ),
        );
      },
    );
  }
}
