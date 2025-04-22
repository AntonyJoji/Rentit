import 'package:delivery/screen/delidetails.dart';
import 'package:delivery/screen/delihistory.dart';
import 'package:delivery/screen/login.dart' show deliLoginPage;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:delivery/main.dart';

class DeliveryBoyHomePage extends StatefulWidget {
  final String boyId;
  const DeliveryBoyHomePage({super.key, required this.boyId});

  @override
  State<DeliveryBoyHomePage> createState() => _DeliveryBoyHomePageState();
}

class _DeliveryBoyHomePageState extends State<DeliveryBoyHomePage> {
  List<dynamic> deliveries = [];
  bool isLoading = true;
  String boyName = '';
  bool isNameLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBoyName();
    fetchDeliveries();
  }

  // Fetch the name of the delivery boy
  Future<void> fetchBoyName() async {
    try {
      final response = await supabase
          .from('tbl_deliveryboy')
          .select('boy_name')
          .eq('boy_id', widget.boyId)
          .single();

      setState(() {
        boyName = response['boy_name'] ?? 'Name not found';
        isNameLoading = false;
      });
    } catch (e) {
      print('Error fetching delivery boy name: $e');
      setState(() {
        boyName = 'Error loading name';
        isNameLoading = false;
      });
    }
  }

  // Fetch assigned deliveries for the delivery boy
  Future<void> fetchDeliveries() async {
    setState(() => isLoading = true);

    try {
      final response = await supabase
          .from('tbl_cart')
          .select(
              'cart_id, cart_qty, boy_id, booking_id, cart_status, tbl_booking(booking_id, user_id), tbl_item(item_name, item_rentprice, item_photo)')
          .inFilter('cart_status', [3, 5])
          .eq('boy_id', widget.boyId);

      for (var delivery in response) {
        final userId = delivery['tbl_booking']?['user_id'];
        final userResponse = await supabase
            .from('tbl_user')
            .select('user_name, user_address')
            .eq('user_id', userId)
            .single();

        delivery['user_details'] = userResponse;
      }

      setState(() {
        deliveries = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching deliveries: $e');
      setState(() => isLoading = false);
    }
  }

  // Logout method
  Future<void> _handleLogout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      
      if (context.mounted) {
        // Navigate to login page and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const deliLoginPage()),
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  // Update delivery status (optional trigger)
  void updateDeliveryStatus(String bookingId) async {
    await supabase
        .from('tbl_booking')
        .update({'delivery_status': 'Picked Up'})
        .eq('booking_id', bookingId);

    fetchDeliveries();
  }

  @override
  Widget build(BuildContext context) {
    final toDeliver = deliveries.where((d) => d['cart_status'] == 3).toList();
    final toReturn = deliveries.where((d) => d['cart_status'] == 5).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome,',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            Text(
              isNameLoading ? 'Loading...' : boyName,
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => const DeliveryHistoryPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.black),
            onPressed: fetchDeliveries,
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchDeliveries,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSection('Deliveries Pending', toDeliver, Colors.blue),
                      const SizedBox(height: 24),
                      _buildSection('Returns Pending', toReturn, Colors.orange),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${items.length}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(
                    title.contains('Deliveries') ? Icons.local_shipping : Icons.assignment_return,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No ${title.toLowerCase()} at the moment',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final userName = item['user_details']?['user_name'] ?? 'Unknown User';
              final userAddress = item['user_details']?['user_address'] ?? 'No address';
              final itemName = item['tbl_item']?['item_name'] ?? 'Unknown Item';
              final itemPhoto = item['tbl_item']?['item_photo'];

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DeliveryDetails(delivery: item),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: itemPhoto != null
                                ? DecorationImage(
                                    image: NetworkImage(itemPhoto),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey[200],
                          ),
                          child: itemPhoto == null
                              ? const Icon(Icons.image_not_supported, color: Colors.grey)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userAddress,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right,
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}