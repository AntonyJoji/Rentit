import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageBooking extends StatefulWidget {
  const ManageBooking({super.key});

  @override
  State<ManageBooking> createState() => _ManageBookingState();
}

class _ManageBookingState extends State<ManageBooking> {
  final supabase = Supabase.instance.client;

  Future<String?> getShopId() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response = await supabase
          .from('tbl_user_shop')
          .select('shop_id')
          .eq('user_id', userId)
          .maybeSingle();

      return response?['shop_id'];
    } catch (e) {
      print('Error fetching shop ID: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchBookings() async {
    try {
      final shopId = await getShopId();
      if (shopId == null) return [];

      print('Current Shop ID: $shopId');

      final bookingData = await supabase
          .from('tbl_booking')
          .select('*, tbl_cart(cart_qty, item_id, tbl_item!inner(item_name))')
          .eq('tbl_cart.shop_id', shopId)
          .eq('tbl_booking.booking_status', 0);  // Filter by booking status (Pending)

      print('Fetched Data: $bookingData');

      return (bookingData as List<dynamic>).expand((bookingItem) {
        final cartList = bookingItem['tbl_cart'] is List
            ? bookingItem['tbl_cart']
            : [bookingItem['tbl_cart']];

        return cartList.map((cartItem) => {
          'booking_id': bookingItem['booking_id'],
          'item_name': cartItem?['tbl_item']?['item_name'] ?? 'N/A',
          'cart_qty': cartItem?['cart_qty'] ?? 0,
          'rental_date': bookingItem['booking_date'] ?? 'N/A',
          'return_date': bookingItem['return_date'] ?? 'N/A',
          'status': bookingItem['booking_status'] == 0 ? 'Pending' : 'Completed'
        }).toList();
      }).toList().cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  Future<void> confirmReturn(int bookingId) async {
    try {
      await supabase
          .from('tbl_booking')
          .update({'booking_status': 1})  // Change status to 1 (Completed)
          .eq('booking_id', bookingId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Return confirmed successfully")),
      );

      setState(() {}); // Refresh the data after confirmation
    } catch (e) {
      print('Error confirming return: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to confirm return")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchBookings(),
      builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No pending bookings found.'));
        }

        final bookings = snapshot.data!;
        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: ListTile(
                leading: const Icon(Icons.shopping_cart, color: Colors.blueAccent),
                title: Text('Booking ID: ${booking['booking_id']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Item: ${booking['item_name']}'),
                    Text('Quantity: ${booking['cart_qty']}'),
                    Text('Rental Date: ${booking['rental_date']}'),
                    Text('Return Date: ${booking['return_date']}'),
                    Text('Status: ${booking['status']}'),
                  ],
                ),
                trailing: ElevatedButton(
                  onPressed: () => confirmReturn(booking['booking_id']),
                  child: const Text('Confirm Return'),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
