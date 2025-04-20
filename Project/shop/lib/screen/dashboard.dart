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
    final shopId = Supabase.instance.client.auth.currentUser?.id;
    if (shopId != null) {
      fetchTotalOrders(shopId);
      fetchPendingOrders(shopId);
      fetchCompletedOrders(shopId);
      fetchEarnings(shopId);
    }
  }

  // Fetch total orders
  Future<void> fetchTotalOrders(String shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_id, tbl_item!inner(shop_id)')
          .eq('tbl_item.shop_id', shopId);

      setState(() {
        totalOrders = cartResponse.length;
      });
    } catch (error) {
      setState(() => totalOrders = 0);
    }
  }

  // Fetch pending orders
  Future<void> fetchPendingOrders(String shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_id, tbl_item!inner(shop_id)')
          .eq('tbl_item.shop_id', shopId)
          .eq('cart_status', 2);

      setState(() {
        pendingOrders = cartResponse.length;
      });
    } catch (error) {
      setState(() => pendingOrders = 0);
    }
  }

  // Fetch completed orders
  Future<void> fetchCompletedOrders(String shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_id, tbl_item!inner(shop_id)')
          .eq('tbl_item.shop_id', shopId)
          .eq('cart_status', 3);

      setState(() {
        completedOrders = cartResponse.length;
      });
    } catch (error) {
      setState(() => completedOrders = 0);
    }
  }

  // Fetch earnings
  Future<void> fetchEarnings(String shopId) async {
    try {
      final earningsResponse = await Supabase.instance.client
          .from('tbl_booking')
          .select('booking_totalprice, tbl_cart!inner(tbl_item!inner(shop_id))')
          .eq('tbl_cart.tbl_item.shop_id', shopId)
          .eq('payment_status', 'completed');

      setState(() {
        earnings = earningsResponse.fold<double>(
            0, (sum, item) => sum + (item['booking_totalprice'] ?? 0));
      });
    } catch (error) {
      setState(() => earnings = 0.0);
    }
  }

  // Widget to build each card
  Widget buildCard(String title, IconData icon, Color color, String data) {
    return GestureDetector(
      onTap: () {
        // You can add navigation or action here
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50,
              color: color,
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF263238),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              data,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section with welcome message
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 12,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Text(
              "Hello, Shop User! 👋",
              style: TextStyle(
                color: Color(0xFF263238),
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(height: 30),

          // Statistics section in cards
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildCard(
                  "Total Orders",
                  Icons.shopping_cart,
                  Color(0xFF1E88E5), // Light Blue
                  totalOrders?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: buildCard(
                  "Pending Orders",
                  Icons.pending_actions,
                  Color(0xFFFFC107), // Amber
                  pendingOrders?.toString() ?? '0',
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // More detailed info in another row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildCard(
                  "Completed Orders",
                  Icons.check_circle,
                  Color(0xFF43A047), // Green
                  completedOrders?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: buildCard(
                  "Earnings",
                  Icons.attach_money,
                  Color(0xFF9C27B0), // Purple
                  earnings?.toStringAsFixed(2) ?? '0.00',
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
