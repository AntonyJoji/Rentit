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
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDeliveryHistory();
  }

  Future<void> _loadDeliveryHistory() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Get current user session
      final session = supabase.auth.currentSession;
      if (session == null) {
        setState(() {
          errorMessage = 'You must be logged in to view history';
          isLoading = false;
        });
        return;
      }

      // Get boy_id from the database using email
      final user = session.user;
      if (user.email == null) {
        setState(() {
          errorMessage = 'Unable to identify user';
          isLoading = false;
        });
        return;
      }

      final deliveryBoy = await supabase
          .from('tbl_deliveryboy')
          .select('boy_id')
          .eq('boy_email', user.email!)
          .maybeSingle();

      if (deliveryBoy == null || deliveryBoy['boy_id'] == null) {
        setState(() {
          errorMessage = 'Delivery boy profile not found';
          isLoading = false;
        });
        return;
      }

      final boyId = deliveryBoy['boy_id'];
      print('Fetching history for boyId: $boyId');

      // Get history with status 5 or 7
      final response = await supabase
          .from('tbl_cart')
          .select('*, tbl_item!inner(item_name, item_photo), tbl_booking!inner(start_date, return_date)')
          .or('cart_status.eq.5,cart_status.eq.7')
          .eq('boy_id', boyId)
          .order('cart_id', ascending: false);

      print('History response: ${response.length} items');

      if (response.isEmpty) {
        print('No history found for this delivery boy');
      } else {
        print('First item: ${response.first}');
      }

      setState(() {
        deliveryHistory = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching delivery history: $e');
      setState(() {
        errorMessage = 'Error loading history: $e';
        isLoading = false;
      });
    }
  }

  String getCartStatusLabel(int status) {
    switch (status) {
      case 5:
        return 'Delivered';
      case 7:
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
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliveryHistory,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[300],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        errorMessage!,
                        style: const TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _loadDeliveryHistory,
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                )
              : deliveryHistory.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.history,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No delivery history found',
                            style: TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loadDeliveryHistory,
                            child: const Text('Refresh'),
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
                        
                        // Format dates
                        final startDate = bookingDetails['start_date'] ?? 'N/A';
                        final returnDate = bookingDetails['return_date'] ?? 'N/A';
                        
                        String formattedStartDate = startDate;
                        String formattedReturnDate = returnDate;
                        try {
                          if (startDate != 'N/A') {
                            final DateTime parsedStartDate = DateTime.parse(startDate);
                            formattedStartDate = '${parsedStartDate.day}/${parsedStartDate.month}/${parsedStartDate.year}';
                          }
                          if (returnDate != 'N/A') {
                            final DateTime parsedReturnDate = DateTime.parse(returnDate);
                            formattedReturnDate = '${parsedReturnDate.day}/${parsedReturnDate.month}/${parsedReturnDate.year}';
                          }
                        } catch (e) {
                          print('Error formatting dates: $e');
                        }

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          child: ListTile(
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: itemImageUrl.isNotEmpty
                                    ? DecorationImage(
                                        image: NetworkImage(itemImageUrl),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: Colors.grey[200],
                              ),
                              child: itemImageUrl.isEmpty
                                  ? const Icon(Icons.image_not_supported, color: Colors.grey)
                                  : null,
                            ),
                            title: Text(
                              itemName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: cartStatus == 5 ? Colors.green[100] : Colors.orange[100],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    getCartStatusLabel(cartStatus),
                                    style: TextStyle(
                                      color: cartStatus == 5 ? Colors.green[800] : Colors.orange[800],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text('Start: $formattedStartDate'),
                                Text('Return: $formattedReturnDate'),
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
