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
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = '';
      });

      final bookingData = await supabase
          .from('tbl_booking')
          .select('*, tbl_user(user_name), tbl_item(item_name)');

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
            'user_name': bookingItem['tbl_user']['user_name'] ?? 'N/A',
            'item_name': bookingItem['tbl_item']['item_name'] ?? 'N/A',
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
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Manage Bookings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16.0),
            Expanded(
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
                          Text('User Name: ${booking['user_name']}'),
                          Text('Item Name: ${booking['item_name']}'),
                          Text('Booking Date: ${booking['booking_date']}'),
                          Text('Return Date: ${booking['return_date']}'),
                          Text('Booking Status: ${booking['booking_status']}'),
                          Text('Payment Status: ${booking['payment_status']}'),
                          Text('Shop ID: ${booking['shop_id']}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BookingDetails(booking: booking),
                          ),
                        ),
                        child: const Text('View Details'),
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

class BookingDetails extends StatelessWidget {
  final Map<String, dynamic> booking;

  const BookingDetails({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Booking Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Booking ID: ${booking['booking_id']}'),
            Text('User Name: ${booking['user_name']}'),
            Text('Item Name: ${booking['item_name']}'),
            Text('Booking Date: ${booking['booking_date']}'),
            Text('Return Date: ${booking['return_date']}'),
            Text('Booking Status: ${booking['booking_status']}'),
            Text('Payment Status: ${booking['payment_status']}'),
            Text('Shop ID: ${booking['shop_id']}'),
          ],
        ),
      ),
    );
  }
}