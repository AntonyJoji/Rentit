import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryHistoryPage extends StatefulWidget {
  @override
  _DeliveryHistoryPageState createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  late Future<List<dynamic>> deliveryHistory;

  // Replace this with actual logged-in delivery boy's ID
  late int boyId;

  @override
  void initState() {
    super.initState();
    // Example: fetch from Supabase Auth or local storage
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      // Example: assuming delivery boy's ID is stored in user metadata
      boyId = user.userMetadata?['boy_id'] ?? 0;
    } else {
      boyId = 0;
    }

    deliveryHistory = fetchDeliveryHistory();
  }

  Future<List<dynamic>> fetchDeliveryHistory() async {
    if (boyId == 0) return [];

    try {
      final response = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_status, tbl_item!inner(item_name, item_photo)')
          .eq('cart_status', 4)
          .eq('boy_id', boyId)
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery History'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple,
        elevation: 2,
      ),
      body: FutureBuilder<List<dynamic>>(
        future: deliveryHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No delivered items found.'));
          } else {
            final history = snapshot.data!;
            return ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final item = history[index];
                final itemDetails = item['tbl_item'] ?? {};
                final itemName = itemDetails['item_name'] ?? 'Unknown Item';
                final itemImageUrl = itemDetails['item_photo'] ?? '';
                final cartStatus = item['cart_status'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                  child: ListTile(
                    leading: itemImageUrl.isNotEmpty
                        ? Image.network(
                            itemImageUrl,
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                          )
                        : const Icon(Icons.image, size: 50, color: Colors.grey),
                    title: Text(itemName, style: const TextStyle(fontSize: 18)),
                    subtitle: Text('Status: ${getCartStatusLabel(cartStatus)}',
                        style: const TextStyle(fontSize: 16)),
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
