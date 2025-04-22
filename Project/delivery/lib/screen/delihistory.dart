import 'package:delivery/main.dart';
import 'package:flutter/material.dart';

class DeliveryHistoryPage extends StatefulWidget {
  const DeliveryHistoryPage({super.key});

  @override
  _DeliveryHistoryPageState createState() => _DeliveryHistoryPageState();
}

class _DeliveryHistoryPageState extends State<DeliveryHistoryPage> {
  bool isLoading = true;
  List<dynamic> deliveryHistory = [];

  @override
  void initState() {
    super.initState();
    fetchDeliveryHistory();
  }

  Future<void> fetchDeliveryHistory() async {
    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        print('No user logged in');
        setState(() {
          isLoading = false;
          deliveryHistory = [];
        });
        return;
      }

      print("boy_id: ${currentUser.id}");
      
      final response = await supabase
          .from('tbl_cart')
          .select('*, tbl_item!inner(item_name, item_photo), tbl_booking!inner(start_date, return_date)')
          .or('cart_status.eq.5,cart_status.eq.6')
          .eq('boy_id', currentUser.id)
          .order('cart_id', ascending: false)
          .limit(100);

      print("response: $response");

      setState(() {
        deliveryHistory = response;
        isLoading = false;
      });
    } catch (e, stackTrace) {
      print('Error fetching delivery history:');
      print('Error: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        isLoading = false;
        deliveryHistory = [];
      });
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
        backgroundColor: Colors.teal,
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                isLoading = true;
              });
              fetchDeliveryHistory();
            },
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
              : deliveryHistory.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.history, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No delivery history found',
                            style: TextStyle(fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      itemCount: deliveryHistory.length,
                      itemBuilder: (context, index) {
                        final item = deliveryHistory[index];
                        final itemDetails = item['tbl_item'] ?? {};
                        final bookingDetails = item['tbl_booking'] ?? {};
                        final itemName = itemDetails['item_name'] ?? 'Unknown Item';
                        final itemImageUrl = itemDetails['item_photo'] ?? '';
                        final cartStatus = item['cart_status'];
                        final startDate = bookingDetails['start_date'] ?? 'N/A';
                        final returnDate = bookingDetails['return_date'] ?? 'N/A';

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
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
                            title: Text(itemName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Status: ${getCartStatusLabel(cartStatus)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: cartStatus == 5 ? Colors.green : Colors.orange,
                                    )),
                                Text('Start Date: $startDate'),
                                Text('Return Date: $returnDate'),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        );
                      },
                    ),
    );
  }
}
