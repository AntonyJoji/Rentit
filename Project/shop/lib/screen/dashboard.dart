import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int? totalOrders;
  int? pendingOrders;
  int? completedOrders;
  List<FlSpot> earningsSpots = [];
  List<FlSpot> ordersSpots = [];
  double maxY = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    final shopId = Supabase.instance.client.auth.currentUser?.id;
    if (shopId != null) {
      fetchTotalOrders(shopId);
      fetchPendingOrders(shopId);
      fetchCompletedOrders(shopId);
      fetchMonthlyData(shopId);
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

  // Fetch monthly data for graph
  Future<void> fetchMonthlyData(String shopId) async {
    try {
      // Get data for the last 6 months
      DateTime now = DateTime.now();
      DateTime sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      final bookingResponse = await Supabase.instance.client
          .from('tbl_booking')
          .select('booking_totalprice, start_date, tbl_cart!inner(tbl_item!inner(shop_id))')
          .eq('tbl_cart.tbl_item.shop_id', shopId)
          .gte('start_date', sixMonthsAgo.toIso8601String())
          .order('start_date');

      // Process data by month
      Map<String, double> monthlyEarnings = {};
      Map<String, int> monthlyOrders = {};

      for (var booking in bookingResponse) {
        DateTime bookingDate = DateTime.parse(booking['start_date']);
        String monthKey = DateFormat('yyyy-MM').format(bookingDate);
        
        // Sum earnings
        monthlyEarnings[monthKey] = (monthlyEarnings[monthKey] ?? 0) + 
            (booking['booking_totalprice'] as num).toDouble();
        
        // Count orders
        monthlyOrders[monthKey] = (monthlyOrders[monthKey] ?? 0) + 1;
      }

      // Convert to graph points
      List<FlSpot> earningPoints = [];
      List<FlSpot> orderPoints = [];
      double maxEarnings = 0;
      double maxOrders = 0;
      int index = 0;

      // Ensure we have data for all months
      for (int i = 0; i < 6; i++) {
        String monthKey = DateFormat('yyyy-MM').format(
          DateTime(now.year, now.month - 5 + i, 1)
        );
        
        double earnings = monthlyEarnings[monthKey] ?? 0;
        int orders = monthlyOrders[monthKey] ?? 0;
        
        earningPoints.add(FlSpot(index.toDouble(), earnings));
        orderPoints.add(FlSpot(index.toDouble(), orders.toDouble()));
        
        maxEarnings = maxEarnings < earnings ? earnings : maxEarnings;
        maxOrders = maxOrders < orders ? orders.toDouble() : maxOrders;
        
        index++;
      }

      setState(() {
        earningsSpots = earningPoints;
        ordersSpots = orderPoints;
        maxY = maxEarnings > maxOrders ? maxEarnings : maxOrders;
        isLoading = false;
      });
    } catch (error) {
      print('Error fetching monthly data: $error');
      setState(() => isLoading = false);
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

  String getMonthName(double value) {
    final now = DateTime.now();
    final month = DateTime(now.year, now.month - 5 + value.toInt(), 1);
    return DateFormat('MMM').format(month);
  }

  Widget buildGraph() {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Monthly Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF263238),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            color: Color(0xFF263238),
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            getMonthName(value),
                            style: const TextStyle(
                              color: Color(0xFF263238),
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  // Earnings Line
                  LineChartBarData(
                    spots: earningsSpots,
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  // Orders Line
                  LineChartBarData(
                    spots: ordersSpots,
                    isCurved: true,
                    color: Colors.green,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
                minX: 0,
                maxX: 5,
                minY: 0,
                maxY: maxY + (maxY * 0.1), // Add 10% padding to top
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Earnings'),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Text('Orders'),
                ],
              ),
            ],
          ),
        ],
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

          // Three cards in a row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: buildCard(
                  "Total Orders",
                  Icons.shopping_cart,
                  Color(0xFF1E88E5),
                  totalOrders?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: buildCard(
                  "Pending Orders",
                  Icons.pending_actions,
                  Color(0xFFFFC107),
                  pendingOrders?.toString() ?? '0',
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: buildCard(
                  "Completed Orders",
                  Icons.check_circle,
                  Color(0xFF43A047),
                  completedOrders?.toString() ?? '0',
                ),
              ),
            ],
          ),

          // Graph Section
          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else
            buildGraph(),
        ],
      ),
    );
  }
}
