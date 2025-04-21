import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryHistoryPage extends StatefulWidget {
  @override
  _DeliveryHistoryPageState createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  int boyId = 0;
  bool isLoading = true;
  List<dynamic> deliveryHistory = [];

  @override
  void initState() {
    super.initState();
    loadSessionAndData();
  }

  Future<void> loadSessionAndData() async {
    final session = Supabase.instance.client.auth.currentSession;
    print('Current session: $session');

    if (session != null) {
      final user = session.user;
      boyId = user.userMetadata?['boy_id'] ?? 0;
      print('Fetched boyId from metadata: $boyId');
    } else {
      print('No user/session logged in');
    }

    if (boyId != 0) {
      await fetchDeliveryHistory();
    }

    setState(() {
      isLoading = false;
    });
  }

Future<void> fetchDeliveryHistory() async {
  try {
    final response = await Supabase.instance.client
        .from('tbl_cart')
        .select('cart_status, tbl_item!inner(item_name, item_photo)')
        .contains('cart_status', [5, 6]) 
        .eq('boy_id', boyId)
        .order('cart_id', ascending: false)
        .limit(100);

    print('Fetched delivery history: ${response.length} items');

    setState(() {
      deliveryHistory = response;
    });
  } catch (e) {
    print('Error fetching delivery history: $e');
  }
}

  String getCartStatusLabel(int status) {
    switch (status) {
      case 5:
        return 'Delivered';
      case 6:
        return 'Returned';
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
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : deliveryHistory.isEmpty
              ? const Center(child: Text('No delivered items found.'))
              : ListView.builder(
                  itemCount: deliveryHistory.length,
                  itemBuilder: (context, index) {
                    final item = deliveryHistory[index];
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
                ),
    );
  }
}
