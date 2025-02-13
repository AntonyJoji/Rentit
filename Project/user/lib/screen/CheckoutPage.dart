import 'package:flutter/material.dart';

class CheckoutPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Delivery Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            TextField(decoration: InputDecoration(labelText: "Full Name")),
            TextField(decoration: InputDecoration(labelText: "Address")),
            TextField(decoration: InputDecoration(labelText: "Phone Number")),
            SizedBox(height: 20),
            Text("Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: const Text('Cash on Delivery'),
              leading: Radio(value: 1, groupValue: 1, onChanged: (value) {}),
            ),
            ListTile(
              title: const Text('Credit/Debit Card'),
              leading: Radio(value: 2, groupValue: 1, onChanged: (value) {}),
            ),
            Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Total: \$75.00", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text("Order Confirmed"),
                        content: Text("Your order has been placed successfully!"),
                        actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text("OK"))],
                      ),
                    );
                  },
                  child: Text("Place Order"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
