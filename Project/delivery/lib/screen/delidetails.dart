import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class DeliveryDetails extends StatelessWidget {
  final dynamic delivery;

  const DeliveryDetails({super.key, required this.delivery});

  @override
  Widget build(BuildContext context) {
    final itemName = delivery['tbl_item']['item_name'] ?? 'No item name'; // Handle null
    final userName = delivery['user_name'] ?? 'Unknown user'; // Handle null
    final userId = delivery['tbl_booking']['user_id'] ?? ''; // Ensure userId is non-null

    // Fetch address and contact
    Future<Map<String, String>> fetchUserDetails(String userId) async {
      try {
        final response = await Supabase.instance.client
            .from('tbl_user')
            .select('user_address, user_contact')
            .eq('user_id', userId)
            .maybeSingle();

        if (response != null) {
          final address = response['user_address'] ?? 'No address found';
          final contact = response['user_contact'] ?? 'No contact found';
          return {'address': address, 'contact': contact};
        } else {
          return {'address': 'No address found', 'contact': 'No contact found'};
        }
      } catch (e) {
        print('Error fetching user details: $e');
        return {'address': 'Error loading address', 'contact': 'Error loading contact'};
      }
    }

    // Launch phone dialer
    void _launchDialer(String number) async {
      final uri = Uri.parse('tel:$number');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        print('Could not launch dialer');
      }
    }

    // Update delivery status to "4" (item delivered)
    Future<void> _updateDeliveryStatus() async {
      try {
        final response = await Supabase.instance.client
            .from('tbl_cart') // Update status in tbl_cart
            .update({'cart_status': 4}) // Setting status to 4 for delivered
            .eq('cart_id', delivery['cart_id']); // Use the cart_id from the delivery object

        // Check if response is valid
        if (response == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No response from server')),
          );
          return;
        }

        // Check for error in the response
        if (response.error != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${response.error?.message ?? 'Unknown error'}')),
          );
          return;
        }

        // Success case
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Item marked as delivered')),
        );
      } catch (e) {
        print('Error updating status: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating status: $e')),
        );
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
            FutureBuilder<Map<String, String>>(
              future: fetchUserDetails(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError || !snapshot.hasData) {
                  return Text('Error loading user details');
                } else {
                  final data = snapshot.data!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Address: ${data['address']}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => _launchDialer(data['contact']!),
                        child: Text('Contact: ${data['contact']}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue,
                          )),
                      ),
                    ],
                  );
                }
              },
            ),
            SizedBox(height: 20),
            // Mark as delivered button
            ElevatedButton(
              onPressed: _updateDeliveryStatus,
              child: Text('Delivered'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromARGB(255, 190, 188, 199), // Green color to indicate success
                padding: EdgeInsets.symmetric(vertical: 14),
                textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
