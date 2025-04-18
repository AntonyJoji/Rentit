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
    fetchPendingOrders(1); // Replace 1 with the actual shopId
    fetchCompletedOrders(1); // Replace 1 with the actual shopId
    fetchEarnings(1); // Replace 1 with the actual shopId
  }

  // Fetch total orders
  Future<void> fetchTotalOrders(int shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('item_id')
          .eq('cart_status', 1) // Adjust to match your criteria for total orders
          .order('cart_id', ascending: true);

      if (cartResponse.isEmpty) {
        setState(() => totalOrders = 0);
        return;
      }

      setState(() {
        totalOrders = cartResponse.length;
      });
    } catch (error) {
      setState(() => totalOrders = 0);
    }
  }

  // Fetch pending orders
  Future<void> fetchPendingOrders(int shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('item_id')
          .eq('cart_status', 0) // Pending orders
          .order('cart_id', ascending: true);

      setState(() {
        pendingOrders = cartResponse.length;
      });
    } catch (error) {
      setState(() => pendingOrders = 0);
    }
  }

  // Fetch completed orders
  Future<void> fetchCompletedOrders(int shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('item_id')
          .eq('cart_status', 1) // Completed orders
          .order('cart_id', ascending: true);

      setState(() {
        completedOrders = cartResponse.length;
      });
    } catch (error) {
      setState(() => completedOrders = 0);
    }
  }

  // Fetch earnings
  Future<void> fetchEarnings(int shopId) async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_totalprice') // Assuming this field holds the price
          .eq('cart_status', 1) // Completed orders only
          .order('cart_id', ascending: true);

      double totalEarnings = 0;
      for (var item in cartResponse) {
        totalEarnings += item['cart_totalprice'] ?? 0.0;
      }

      setState(() {
        earnings = totalEarnings;
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
