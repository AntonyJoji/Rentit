import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ManageBooking extends StatefulWidget {
  const ManageBooking({super.key});

  @override
  State<ManageBooking> createState() => _ManageBookingState();
}

class _ManageBookingState extends State<ManageBooking> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchBookings(); // Fetch data when the widget is initialized
  }

  Future<void> fetchBookings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      // Fetch all bookings without filtering by shop_id
      final bookingData = await supabase
          .from('tbl_booking')
          .select('*'); // Fetch all columns from tbl_booking

      print('Fetched Data: $bookingData');

      if (bookingData.isEmpty) {
        setState(() {
          errorMessage = 'No bookings found.';
          isLoading = false;
        });
        return;
      }

      setState(() {
        bookings = (bookingData as List<dynamic>).map<Map<String, dynamic>>((bookingItem) {
          return {
            'booking_id': bookingItem['booking_id'] ?? 'N/A',
            'user_id': bookingItem['user_id'] ?? 'N/A',
            'item_id': bookingItem['item_id'] ?? 'N/A',
            'booking_date': bookingItem['booking_date'] ?? 'N/A',
            'return_date': bookingItem['return_date'] ?? 'N/A',
            'booking_status': bookingItem['booking_status'] ?? 'N/A',
            'payment_status': bookingItem['payment_status'] ?? 'N/A',
            'shop_id': bookingItem['shop_id'] ?? 'N/A',
          };
        }).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching bookings: $e');
      setState(() {
        errorMessage = 'Failed to fetch bookings. Please try again.';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage.isNotEmpty) {
      return Center(child: Text(errorMessage));
    }

    if (bookings.isEmpty) {
      return const Center(child: Text('No bookings available.'));
    }

    return SafeArea(
      child: SingleChildScrollView( // Allow everything to scroll
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Manage Bookings',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16.0),
              // Use ListView.builder inside a Container to manage height
              Container(
                height: MediaQuery.of(context).size.height - 100, // Adjust to fit within the screen
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      child: ListTile(
                        leading: const Icon(Icons.shopping_cart, color: Colors.blueAccent),
                        title: Text('Booking ID: ${booking['booking_id']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('User ID: ${booking['user_id']}'),
                            Text('Item ID: ${booking['item_id']}'),
                            Text('Booking Date: ${booking['booking_date']}'),
                            Text('Return Date: ${booking['return_date']}'),
                            Text('Booking Status: ${booking['booking_status']}'),
                            Text('Payment Status: ${booking['payment_status']}'),
                            Text('Shop ID: ${booking['shop_id']}'),
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
      ),
    );
  }
}
