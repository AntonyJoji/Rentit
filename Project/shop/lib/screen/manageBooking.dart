import 'package:flutter/material.dart';
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
    .eq('tbl_cart.tbl_item.shop_id', shopId) // Correct condition for `shop_id`
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



  void _updateBookingStatus(int bookingId, int status) async {
    await supabase
        .from('tbl_booking')
        .update({'booking_status': status}).eq('booking_id', bookingId);

    setState(() {}); // Refresh FutureBuilder
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Booking status updated successfully!")),
    );
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
                  return Card(
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text("Booking ID: ${booking['booking_id']}"),
                      subtitle: Text("Status: ${booking['booking_status']}"),
                      trailing: DropdownButton<int>(
                        value: booking['booking_status'],
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Pending')),
                          DropdownMenuItem(value: 2, child: Text('Confirmed')),
                          DropdownMenuItem(value: 3, child: Text('Completed')),
                        ],
                        onChanged: (newStatus) => _updateBookingStatus(
                            booking['booking_id'], newStatus!),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
