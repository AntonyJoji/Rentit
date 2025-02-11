import 'package:flutter/material.dart';

class DeliveryBoyHomePage extends StatelessWidget {
  const DeliveryBoyHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Delivery Dashboard', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Refresh deliveries
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.delivery_dining, size: 40, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text('Delivery Agent', style: TextStyle(color: Colors.white, fontSize: 18)),
                  Text('agent@example.com', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('Delivery History'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {},
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Logout'),
              onTap: () {
                Navigator.pushReplacementNamed(context, 'deliLoginPage'); // Navigate to login
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Assigned Deliveries', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: 5, // Replace with dynamic data
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.local_shipping, color: Colors.blue, size: 36),
                      title: Text('Order #${index + 1}', style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Delivery Address: XYZ Street\nExpected: 2:30 PM'),
                      trailing: ElevatedButton(
                        onPressed: () {
                          // Update delivery status
                        },
                        child: Text('Picked Up'),
                      ),
                      onTap: () {
                        // Open order details
                      },
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
