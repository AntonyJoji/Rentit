import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryDetails extends StatelessWidget {
  final dynamic delivery; // Passing the delivery object

  const DeliveryDetails({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final itemName = delivery['tbl_item']['item_name'];
    final userName = delivery['user_name'];
    final userId = delivery['tbl_booking']['user_id']; // Getting the user_id

    // Fetch the address from the database (moved here)
    Future<String> fetchUserAddress(String userId) async {
      try {
        final response = await Supabase.instance.client
            .from('tbl_user')
            .select('user_address')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null && response['user_address'] != null) {
          return response['user_address'];
        } else {
          return 'No address found';
        }
      } catch (e) {
        print('Error fetching address: $e');
        return 'Error loading address';
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Details'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Product: $itemName',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Text('User: $userName',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            SizedBox(height: 10),
            FutureBuilder<String>(
              future: fetchUserAddress(userId),  // Fetch address here
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Error loading address');
                } else if (!snapshot.hasData) {
                  return Text('No address found');
                } else {
                  final address = snapshot.data!;
                  return Text('Address: $address',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
