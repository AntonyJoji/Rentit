import 'package:flutter/material.dart';
import 'package:user/screen/cart.dart';

class ProductPage extends StatelessWidget {
  final Map<String, dynamic> product;

  const ProductPage({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product['name'])),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(product['image'], height: 250, fit: BoxFit.cover),
            SizedBox(height: 16),
            Text(product['name'], style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(product['description'], style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Text("Price: ₹${product['price']} per day", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                 Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const CartPage(), // Fixed constructor reference
                              ),
                            );
              },
              child: Text("Add to Cart"),
            ),
          ],
        ),
      ),
    );
  }
}
