import 'package:flutter/material.dart';
import 'package:user/screen/CheckoutPage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  List<Map<String, dynamic>> cartItems = [
    {
      "name": "Power Drill",
      "image": "https://via.placeholder.com/150",
      "description": "A high-powered drill for all your construction needs.",
      "price": 15.0,
      "duration": 3,
      "quantity": 1,
    },
    {
      "name": "Ladder",
      "image": "https://via.placeholder.com/150",
      "description": "Sturdy and reliable ladder for home and work.",
      "price": 10.0,
      "duration": 5,
      "quantity": 1,
    }
  ];

  double getTotalPrice() {
    return cartItems.fold(0, (sum, item) => sum + (item['price'] * item['quantity'] * item['duration']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Your Cart"),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: cartItems.length,
              itemBuilder: (context, index) {
                var item = cartItems[index];
                return Container(
                  margin: EdgeInsets.all(8),
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(item['image'], width: 80, height: 80, fit: BoxFit.cover),
                      SizedBox(height: 8),
                      Text(item['name'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(item['description'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text("${item['duration']} days • \$${item['price']} per day"),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove, size: 18),
                            onPressed: () {
                              setState(() {
                                if (item['quantity'] > 1) item['quantity']--;
                              });
                            },
                          ),
                          Text(item['quantity'].toString(), style: TextStyle(fontSize: 14)),
                          IconButton(
                            icon: Icon(Icons.add, size: 18),
                            onPressed: () {
                              setState(() {
                                item['quantity']++;
                              });
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("Total:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    Text("${getTotalPrice().toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CheckoutPage(), // Fixed constructor reference
                              ),
                            );
                    },
                    child: Text("Proceed to Checkout", style: TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
