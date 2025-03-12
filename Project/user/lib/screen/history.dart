import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RentHistoryPage extends StatefulWidget {
  @override
  _RentHistoryPageState createState() => _RentHistoryPageState();
}

class _RentHistoryPageState extends State<RentHistoryPage> {
  final supabase = Supabase.instance.client;

  // Fetch rent history data from the database
  Future<List<Map<String, dynamic>>> fetchRentHistory() async {
    try {
      // Fetch cart data along with the relationship to tbl_booking
      final cartData = await supabase
          .from('tbl_cart')
          .select(
            'cart_id, cart_qty, item_id, tbl_booking!tbl_booking_cart_id_fkey(booking_date, return_date, booking_status, early_return_date, booking_id, user_id)'
          )
          .eq('tbl_booking.user_id', supabase.auth.currentUser!.id);

      if (cartData.isEmpty) {
        return [];
      }

      final itemIds = cartData.map((item) => item['item_id']).toList();
      final itemData = await supabase
          .from('tbl_item')
          .select('item_id, item_name, item_rentprice')
          .inFilter('item_id', itemIds);

      // Map cart data with item and booking info
      return cartData.map((cartItem) {
        final matchingItem = itemData.firstWhere(
          (item) => item['item_id'] == cartItem['item_id'],
          orElse: () => {'item_name': 'Unknown', 'item_rentprice': 0},
        );

        final bookingData = (cartItem['tbl_booking'] as List?)?.firstOrNull;

        return {
          'itemName': matchingItem['item_name'],
          'rentalDate': bookingData?['booking_date'] ?? 'N/A',
          'returnDate': bookingData?['return_date'] ?? 'N/A',
          'earlyReturnDate': bookingData?['early_return_date'] ?? 'N/A',
          'status': bookingData?['booking_status'] == 1 ? 'Completed' : 'Pending',
          'totalCost': '\$${(cartItem['cart_qty'] ?? 0) * (matchingItem['item_rentprice'] ?? 0)}',
          'bookingId': bookingData?['booking_id'] ?? 0
        };
      }).toList();
    } catch (e) {
      print('Error fetching rent history: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Rent History'),
        backgroundColor: Colors.blueAccent,
      ),
      body: FutureBuilder(
        future: fetchRentHistory(),
        builder: (context, AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text("No rent history found."));
          }

          final rentHistory = snapshot.data!;
          return ListView.builder(
            itemCount: rentHistory.length,
            itemBuilder: (context, index) {
              final item = rentHistory[index];
              return Card(
                margin: EdgeInsets.all(10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: ListTile(
                  contentPadding: EdgeInsets.all(12),
                  leading: Icon(Icons.shopping_bag, color: Colors.blueAccent),
                  title: Text(item['itemName'], style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Rental Date: ${item['rentalDate']}'),
                      Text('Return Date: ${item['returnDate']}'),
                      Text('Early Return Date: ${item['earlyReturnDate']}'),
                      Text('Total Cost: ${item['totalCost']}'),
                      Text('Status: ${item['status']}',
                          style: TextStyle(
                              color: item['status'] == 'Completed'
                                  ? Colors.green
                                  : Colors.orange)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
