import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/cart.dart';
import 'package:user/screen/mybookings.dart';
import 'package:user/screen/login.dart';
import 'package:user/screen/productpage.dart';
import 'package:user/screen/settingsPage.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  _UserHomePageState createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final SupabaseClient supabase = Supabase.instance.client;
  List<Map<String, dynamic>> items = [];
  List<Map<String, dynamic>> filteredItems = [];
  Map<int, int> itemStocks = {}; // Store stock quantities
  bool isLoading = true;
  TextEditingController searchController = TextEditingController();
  
  // Add user data variables
  String userName = 'Loading...';
  String userEmail = 'Loading...';
  bool isUserDataLoading = true;

  @override
  void initState() {
    super.initState();
    fetchItems();
    fetchUserData();
    searchController.addListener(_filterItems);
  }

  Future<void> fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_email')
          .eq('user_id', user.id)
          .single();

      setState(() {
        userName = response['user_name'] ?? 'User';
        userEmail = response['user_email'] ?? user.email ?? 'No email';
        isUserDataLoading = false;
      });
    } catch (e) {
      print('Error fetching user data: $e');
      setState(() {
        userName = 'User';
        userEmail = 'No email';
        isUserDataLoading = false;
      });
    }
  }

  Future<void> fetchItems() async {
    try {
      // Fetch items
      final response = await supabase.from('tbl_item').select();
      
      // Fetch stock information for all items
      final stockResponse = await supabase
          .from('tbl_stock')
          .select('item_id, stock_quantity, stock_date')
          .order('stock_date', ascending: false);

      // Create a map of item_id to latest stock quantity
      Map<int, int> stocks = {};
      for (var stock in stockResponse) {
        // Only set the stock if we haven't seen this item_id before
        // This ensures we get the latest stock for each item
        if (!stocks.containsKey(stock['item_id'])) {
          stocks[stock['item_id']] = stock['stock_quantity'];
        }
      }

      setState(() {
        items = List<Map<String, dynamic>>.from(response);
        filteredItems = List<Map<String, dynamic>>.from(items);
        itemStocks = stocks;
        isLoading = false;
      });

      // Debug print to check stock data
      print('Stock data: $stocks');
    } catch (e) {
      print('Error fetching items: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _filterItems() {
    setState(() {
      filteredItems = items.where((item) {
        return item['item_name']
            .toLowerCase()
            .contains(searchController.text.toLowerCase());
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.removeListener(_filterItems);
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RentIt',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => CartPage()));
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: BoxDecoration(color: Colors.blueAccent),
              accountName: Text(
                userName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              accountEmail: Text(
                userEmail,
                style: TextStyle(
                  fontSize: 14,
                ),
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(
                  Icons.person,
                  size: 40,
                  color: Colors.blueAccent,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.home_outlined),
              title: Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.calendar_today_outlined),
              title: Text('My Bookings'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => Mybookings()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings_outlined),
              title: Text('Settings'),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => UserLoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available Tools',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            SizedBox(height: 12),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      itemCount: filteredItems.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        childAspectRatio: 0.75,
                      ),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Card(
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(item['item_photo']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item['item_name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        '₹${item['item_rentprice']}/day',
                                        style: TextStyle(color: Colors.green, fontSize: 14),
                                      ),
                                      SizedBox(height: 4),
                                      if ((itemStocks[item['item_id']] ?? 0) <= 0)
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red[50],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            'Out of Stock',
                                            style: TextStyle(
                                              color: Colors.red[700],
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      SizedBox(height: 8),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ProductPage(itemId: item['item_id']),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            padding: EdgeInsets.symmetric(vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            backgroundColor: Colors.blueAccent,
                                          ),
                                          child: Text('Details'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
