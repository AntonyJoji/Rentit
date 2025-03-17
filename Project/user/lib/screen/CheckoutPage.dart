import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/userhomepage.dart';

class CheckoutPage extends StatefulWidget {
  final int bid;
  const CheckoutPage({super.key, required this.bid});

  @override
  _CheckoutPageState createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final supabase = Supabase.instance.client;

  String userName = '';
  String userAddress = '';
  String userPhone = '';
  double totalAmount = 0.0;
  double _advancePaymentAmount = 0.0; // Added for advance payment

  DateTime? startDate;
  DateTime? pickupDate;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchTotalAmount();
  }

  Future<void> _fetchUserDetails() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception("User not logged in");

      final response = await supabase
          .from('tbl_user')
          .select('user_name, user_address, user_contact')
          .eq('user_id', userId)
          .single();

      if (!mounted) return;
      setState(() {
        userName = response['user_name'] ?? 'N/A';
        userAddress = response['user_address'] ?? 'N/A';
        userPhone = response['user_contact'] ?? 'N/A';
      });
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load user details")),
        );
      }
    }
  }

Future<void> _fetchTotalAmount() async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    final cartResponse = await supabase
        .from('tbl_cart')
        .select('cart_qty, item_id')
        .eq('booking_id', widget.bid);

    if (cartResponse .isEmpty) {
      setState(() {
        totalAmount = 0.0;
        _advancePaymentAmount = 0.0;
      });
      return;
    }

    double total = 0.0;
    double advancePaymentTotal = 0.0;

    for (var cartItem in cartResponse) {
      final itemResponse = await supabase
          .from('tbl_item')
          .select('item_rentprice')
          .eq('item_id', cartItem['item_id'])
          .maybeSingle();

      if (itemResponse == null) continue;

      final dailyRentPrice = double.tryParse(
        itemResponse['item_rentprice']?.toString() ?? '0',
      ) ?? 0;

      final totalDays = (startDate != null && pickupDate != null)
          ? pickupDate!.difference(startDate!).inDays
          : 1;

      final itemTotal = (cartItem['cart_qty'] ?? 0) * dailyRentPrice * totalDays;
      total += itemTotal;
      advancePaymentTotal += itemTotal * 0.3;
    }

    if (!mounted) return;
    setState(() {
      totalAmount = total;
      _advancePaymentAmount = advancePaymentTotal;
    });

    print("Total Amount: $totalAmount");
    print("Advance Payment Amount: $_advancePaymentAmount");

  } catch (error) {
    print("Error fetching total amount: $error");
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load total amount")),
      );
    }
  }
}



  Future<void> _confirmPayment() async {
  try {
    // Mock payment confirmation (Replace this with actual payment gateway logic)
    bool paymentSuccessful = await _simulatePayment(); // Simulating a payment process

    if (paymentSuccessful) {
      await _placeOrder();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Payment failed. Please try again.")),
      );
    }
  } catch (error) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("An error occurred. Please try again.")),
    );
  }
}

  Future<bool> _simulatePayment() async {
  await Future.delayed(Duration(seconds: 2));
  return DateTime.now().millisecond % 10 < 8; // 80% success chance
}

Future<void> _placeOrder() async {
  try {
    if (!mounted) return;

    final userId = supabase.auth.currentUser?.id;
    if (userId == null) throw Exception("User not logged in");

    if (startDate == null || pickupDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select both start and pickup dates")),
      );
      return;
    }

   await supabase
    .from('tbl_booking')
    .update({
      'booking_status': 1,
      'return_date': DateFormat('yyyy-MM-dd').format(pickupDate!),
      'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
      'booking_totalprice': totalAmount.toInt(), 
    })
    .eq('booking_id', widget.bid);



    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Order Confirmed"),
        content: Text(
          "Your order has been placed successfully!\n\n"
          "Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}\n"
          "Pickup Date: ${DateFormat('yyyy-MM-dd').format(pickupDate!)}\n"
          "Return Date: ${DateFormat('yyyy-MM-dd').format(pickupDate!)}\n"
          "Advance Payment: \$${_advancePaymentAmount.toStringAsFixed(2)}"
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close the dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => UserHomePage()),
              );
            },
            child: Text("OK"),
          ),
        ],
      ),
    );
  } catch (error) {
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Failed to place order: $error")),
    );
    print("Order Placement Error: $error");
  }
}

}




Future<void> _selectDate(BuildContext context, bool isStartDate) async {
  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2000),
    lastDate: DateTime(2101),
  );

  if (picked != null) {
    setState(() {
      if (isStartDate) {
        startDate = picked;
      } else {
        pickupDate = picked;
      }
    });

    if (!isStartDate && pickupDate != null) {
      await _updateReturnDate(pickupDate!);
    }

    if (startDate != null && pickupDate != null) {
      await _fetchTotalAmount();  // Now calculates total only when both dates are picked
    }
  }
}


  Future<void> _updateReturnDate(DateTime returnDate) async {
    // Implement the logic to update the return date if needed
    // For now, this is a placeholder function
    print("Return date updated to: $returnDate");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Checkout")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text("Delivery Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Name: $userName"),
            Text("Address: $userAddress"),
            Text("Phone: $userPhone"),
            SizedBox(height: 10),

            Text("Start Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(
                startDate == null
                    ? "Select a start date"
                    : DateFormat('yyyy-MM-dd').format(startDate!),
              ),
              trailing: ElevatedButton(
                onPressed: () => _selectDate(context, true),
                child: Text("Pick Start Date"),
              ),
            ),

            Text("Pickup Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ListTile(
              title: Text(
                pickupDate == null
                    ? "Select a pickup date"
                    : DateFormat('yyyy-MM-dd').format(pickupDate!),
              ),
              trailing: ElevatedButton(
                onPressed: startDate != null
                    ? () => _selectDate(context, false)
                    : null,
                child: Text("Pick Pickup Date"),
              ),
            ),

            SizedBox(height: 20),

            Text("Total: \$${totalAmount.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Advance Payment: \$${_advancePaymentAmount.toStringAsFixed(2)}",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

            ElevatedButton(
              onPressed: _confirmPayment,
              child: Text("Proceed to Payment"),
            ),
          ],
        ),
      ),
    );
  }
}