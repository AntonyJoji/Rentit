import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryHistoryPage extends StatefulWidget {
  @override
  _DeliveryHistoryPageState createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  late Future<List<dynamic>> deliveryHistory;

  Future<List<dynamic>> fetchDeliveryHistory() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_status, tbl_item!inner(item_name, item_photo)')
          .eq('cart_status', 4)
          .order('cart_id', ascending: false)
          .limit(100);

      return response as List<dynamic>;
    } catch (e) {
      print('Error fetching delivery history: $e');
      return [];
    }
  }

  String getCartStatusLabel(int status) {
    switch (status) {
      case 1:
        return 'Ordered';
      case 2:
        return 'Packed';
      case 3:
        return 'Shipped';
      case 4:
        return 'Delivered';
      default:
        return 'Unknown';
    }
  }

  @override
  void initState() {
    super.initState();
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
                final itemName = item['tbl_item']['item_name'] ?? 'Unknown Item';
                final itemImageUrl = item['tbl_item']['item_photo'] ?? '';
                final cartStatus = item['cart_status'];

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    leading: itemImageUrl.isNotEmpty
                        ? Image.network(itemImageUrl, width: 50, height: 50, fit: BoxFit.cover)
                        : Icon(Icons.image, size: 50, color: Colors.grey), // Placeholder if no image
                    title: Text(itemName, style: TextStyle(fontSize: 18)),
                    subtitle: Text('Status: ${getCartStatusLabel(cartStatus)}',
                        style: TextStyle(fontSize: 16)),
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
