import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RentHistoryPage extends StatefulWidget {
  @override
  _RentHistoryPageState createState() => _RentHistoryPageState();
}

class _RentHistoryPageState extends State<RentHistoryPage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> fetchRentHistory() async {
    try {
      final cartData = await supabase
          .from('tbl_cart')
          .select('*, tbl_booking:booking_id(booking_date, return_date, booking_status, early_return_date)')
          .eq('tbl_booking.user_id', supabase.auth.currentUser!.id);

      final itemIds = cartData.map((item) => item['item_id']).toList();
      final itemData = await supabase
          .from('tbl_item')
          .select('item_id, item_name, item_rentprice')
          .inFilter('item_id', itemIds);

      return cartData.map((cartItem) {
        final matchingItem = itemData.firstWhere(
          (item) => item['item_id'] == cartItem['item_id'],
          orElse: () => {'item_name': 'Unknown', 'item_rentprice': 0},
        );

        return {
          'itemName': matchingItem['item_name'],
          'rentalDate': cartItem['tbl_booking']['booking_date'],
          'returnDate': cartItem['tbl_booking']['return_date'],
          'earlyReturnDate': cartItem['tbl_booking']['early_return_date'] ?? 'N/A',
          'status': cartItem['tbl_booking']['booking_status'] == 1 ? 'Completed' : 'Pending',
          'totalCost': '\$${(cartItem['cart_qty'] ?? 0) * (matchingItem['item_rentprice'] ?? 0)}',
          'bookingId': cartItem['tbl_booking']['booking_id']
        };
      }).toList();
    } catch (e) {
      print('Error fetching rent history: $e');
      return [];
    }
  }

  Future<void> requestEarlyReturn(int bookingId) async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 30)),
    );

    if (selectedDate != null) {
      try {
        await supabase
            .from('tbl_booking')
            .update({'early_return_date': selectedDate.toIso8601String()})
            .eq('booking_id', bookingId);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Early return request submitted successfully!')),
        );
        setState(() {}); // Refresh data after updating
      } catch (e) {
        print('Error submitting early return request: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit request. Please try again.')),
        );
      }
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
                                  : Colors.orange))
                    ],
                  ),
                  trailing: item['status'] == 'Pending'
                      ? ElevatedButton(
                          onPressed: () => requestEarlyReturn(item['bookingId']),
                          child: Text('Request Early Return'),
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}
