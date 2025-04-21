import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/payment.dart';
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

      if (cartResponse.isEmpty) {
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
            ) ??
            0;

        final totalDays = (startDate != null && pickupDate != null)
            ? pickupDate!.difference(startDate!).inDays
            : 1;

        final itemTotal =
            (cartItem['cart_qty'] ?? 0) * dailyRentPrice * totalDays;
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
      bool paymentSuccessful =
          await _simulatePayment(); // Simulating a payment process

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

      await supabase.from('tbl_booking').update({
        'booking_status': 1,
        'return_date': DateFormat('yyyy-MM-dd').format(pickupDate!),
        'start_date': DateFormat('yyyy-MM-dd').format(startDate!),
        'booking_totalprice': totalAmount.toInt(),
      }).eq('booking_id', widget.bid);

      await supabase.from('tbl_cart').update({
        'cart_status': 1,
      }).eq('booking_id', widget.bid);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Order Confirmed"),
          content: Text("Your order has been placed successfully!\n\n"
              "Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}\n"
              "Pickup Date: ${DateFormat('yyyy-MM-dd').format(pickupDate!)}\n"
              "Return Date: ${DateFormat('yyyy-MM-dd').format(pickupDate!)}\n"
              "Advance Payment: \$${_advancePaymentAmount.toStringAsFixed(2)}"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => PaymentGatewayScreen(id: widget.bid,)),
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
        await _fetchTotalAmount(); // Now calculates total only when both dates are picked
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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 24),
            SizedBox(width: 8),
            Text(
              "Checkout",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.blue.shade700,
        elevation: 0,
        actions: [SizedBox(width: 48)],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Delivery Information Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.local_shipping_outlined, 
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Delivery Information",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildInfoRow(Icons.person_outline, "Name", userName),
                        SizedBox(height: 16),
                        _buildInfoRow(Icons.location_on_outlined, "Address", userAddress),
                        SizedBox(height: 16),
                        _buildInfoRow(Icons.phone_outlined, "Phone", userPhone),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Date Selection Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_today_outlined,
                            color: Colors.green.shade700,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "Rental Period",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildDateSelectionCard(
                          "Start Date",
                          startDate,
                          () => _selectDate(context, true),
                          "Pick Start Date",
                          Colors.blue.shade700,
                        ),
                        SizedBox(height: 16),
                        _buildDateSelectionCard(
                          "Pickup Date",
                          pickupDate,
                          startDate != null ? () => _selectDate(context, false) : null,
                          "Pick Pickup Date",
                          Colors.green.shade700,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Payment Summary Card
            Container(
              width: double.infinity,
              margin: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.payment_outlined,
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 12),
            Text(
                          "Payment Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.purple.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildPaymentRow("Total Amount", totalAmount),
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(color: Colors.grey.shade200),
                        ),
                        _buildPaymentRow("Advance Payment (30%)", _advancePaymentAmount),
                        SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
              onPressed: _confirmPayment,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.shade700,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline),
                                SizedBox(width: 8),
                                Text(
                                  "Proceed to Payment",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.blue.shade700, size: 20),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateSelectionCard(
      String title, DateTime? date, VoidCallback? onPressed, String buttonText, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                date == null
                    ? "Not selected"
                    : DateFormat('yyyy-MM-dd').format(date),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(buttonText),
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.purple.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            "₹${amount.toStringAsFixed(2)}",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.purple.shade700,
            ),
          ),
        ),
      ],
    );
  }
}

