import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int? totalOrders;
  int? totalBookings;
  int? pendingOrders;
  int? completedOrders;
  double? earnings;

  @override
  void initState() {
    super.initState();
    fetchTotalOrders(1); // Replace 1 with the actual shopId
  }

Future<void> fetchTotalOrders(int shopId) async {
  try {
    print("Fetching cart entries...");

    final cartResponse = await Supabase.instance.client
        .from('tbl_cart')
        .select('item_id')
        .eq('cart_status', 1)
        .order('cart_id', ascending: true); // Optional for better data flow

    print("Cart entries fetched: $cartResponse");

    if (cartResponse.isEmpty) {
      print("No pending orders found.");
      setState(() => totalOrders = 0);
      return;
    }

    final itemIds = cartResponse
        .map((item) => item['item_id'])
        .where((id) => id != null)
        .toList();

    print("Item IDs from tbl_cart: $itemIds");

    if (itemIds.isEmpty) {
      print("No valid item IDs found in cart.");
      setState(() => totalOrders = 0);
      return;
    }

    // Fetch matched items from tbl_item
    final matchedItems = await Supabase.instance.client
        .from('tbl_item')
        .select('item_id')
        .inFilter('item_id', itemIds)
        .eq('itemshop_id', shopId);

    print("Matched items for shop $shopId: $matchedItems");

    final orderCount = matchedItems.length;

    print("Total orders for shop $shopId: $orderCount");

    await Future.delayed(const Duration(seconds: 1)); // Optional delay for smooth UI update

    setState(() {
      totalOrders = orderCount;
    });
  } catch (error) {
    print("Error fetching total orders: $error");
    setState(() => totalOrders = 0); // Set to 0 on error
  }
}



  Widget buildBox(String title, IconData icon, Color color, String value) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: color,
      ),
      height: 200,
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: Colors.white),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 5,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Text(
              "Welcome shop user!",
              style: TextStyle(
                color: Color(0xFF1F4037),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: buildBox(
                  "Total Orders",
                  Icons.shopping_cart,
                  Colors.indigo,
                  totalOrders?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBox(
                  "Pending Orders",
                  Icons.pending_actions,
                  Colors.orange,
                  pendingOrders?.toString() ?? '0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: buildBox(
                  "Completed Orders",
                  Icons.check_circle,
                  Colors.green,
                  completedOrders?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: buildBox(
                  "Earnings",
                  Icons.attach_money,
                  Colors.purple,
                  earnings?.toStringAsFixed(2) ?? '0.00',
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
