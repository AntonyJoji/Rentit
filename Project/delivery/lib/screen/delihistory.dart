import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryHistoryPage extends StatefulWidget {
  @override
  _DeliveryHistoryPageState createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  late Future<List<dynamic>> deliveryHistory;

  // Function to fetch delivery history with cart_status = 4
  Future<List<dynamic>> fetchDeliveryHistory() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_id, tbl_item!inner(item_name), user_name, cart_status') // Using inner join to fetch item_name from tbl_item
          .eq('cart_status', 4) // Only fetch delivered items
          .order('cart_id', ascending: false) // Optional: Order by cart_id (newest first)
          .execute();

      if (response.error == null) {
        return response.data as List<dynamic>;
      } else {
        print('Error fetching delivery history: ${response.error?.message}');
        return [];
      }
    } catch (e) {
      print('Error fetching delivery history: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    // Initialize delivery history
    deliveryHistory = fetchDeliveryHistory();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery History'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: deliveryHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No delivered items found.'));
          } else {
            final history = snapshot.data!;
            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final itemName = item['tbl_item']['item_name'];
                final userName = item['user_name'];
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    title: Text(itemName, style: TextStyle(fontSize: 18)),
                    subtitle: Text('Delivered to: $userName', style: TextStyle(fontSize: 16)),
                    leading: Icon(Icons.delivery_dining, color: Colors.green),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
