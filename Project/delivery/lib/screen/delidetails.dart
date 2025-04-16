import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DeliveryDetails extends StatefulWidget {
  final dynamic delivery;

  const DeliveryDetails({super.key, required this.delivery});

  @override
  _DeliveryDetailsState createState() => _DeliveryDetailsState();
}

class _DeliveryDetailsState extends State<DeliveryDetails> {
  late int totalDays;
  late double totalAmount;
  String formattedTotalAmount = '';
  String formattedStartDate = '';
  String formattedReturnDate = '';
  Map<String, dynamic> user = {};

  @override
  void initState() {
    super.initState();
    calculateAmount();
    fetchUserData();
  }

  // Method to fetch user data based on user_id from tbl_user table
  Future<void> fetchUserData() async {
  final userId = widget.delivery['tbl_booking']['user_id'];
  try {
    // Fetching data from the tbl_user table based on user_id
    final userResponse = await Supabase.instance.client
        .from('tbl_user')
        .select('*')
        .eq('user_id', userId)
        .single();

    if (userResponse != null) {
      setState(() {
        user = userResponse as Map<String, dynamic>;
      });
    } else {
      print('Error fetching user data: $userResponse');
    }

    // Fetching booking data based on booking_id to get start_date and return_date
    final bookingId = widget.delivery['tbl_booking']['booking_id'];
    final bookingResponse = await Supabase.instance.client
        .from('tbl_booking')
        .select('start_date, return_date') // Only selecting the start_date and return_date fields
        .eq('booking_id', bookingId)
        .single();

    if (bookingResponse != null) {
      // Set the start_date and return_date values
      setState(() {
        formattedStartDate = bookingResponse['start_date'] ?? 'N/A';
        formattedReturnDate = bookingResponse['return_date'] ?? 'N/A';
      });
    } else {
      print('Error fetching booking data: $bookingResponse');
    }
  } catch (e) {
    print('Error fetching data: $e');
  }
}

  void calculateAmount() {
  final booking = widget.delivery['tbl_booking'] ?? {};
  final item = widget.delivery['tbl_item'] ?? {};

  // Debugging: Check if data is being passed correctly
  print("Delivery: ${widget.delivery}");
  print("Booking: $booking");
  print("Item: $item");

  // Ensure that fields exist before accessing them
  double itemPrice = double.tryParse(item['item_rentprice']?.toString() ?? '0') ?? 0.0;
  String startDateStr = booking['start_date'] ?? '';
  String returnDateStr = booking['return_date'] ?? '';

  // Debugging: Print the dates
  print("Start Date String: $startDateStr");
  print("Return Date String: $returnDateStr");

  totalDays = 1;  // Default to 1 if there is no valid date range
  totalAmount = itemPrice;

  try {
    if (startDateStr.isNotEmpty && returnDateStr.isNotEmpty) {
      DateTime startDate = DateTime.parse(startDateStr);
      DateTime returnDate = DateTime.parse(returnDateStr);

      // Calculate the difference in days between the start date and return date
      totalDays = returnDate.difference(startDate).inDays;
      if (totalDays <= 0) totalDays = 1;  // Ensure at least 1 day is considered

      // Calculate the total amount
      totalAmount = itemPrice * totalDays;

      // Format the dates
      formattedStartDate = DateFormat('dd MMM yyyy').format(startDate);
      formattedReturnDate = DateFormat('dd MMM yyyy').format(returnDate);
    } else {
      formattedStartDate = 'N/A';
      formattedReturnDate = 'N/A';
    }
  } catch (e) {
    print('Date parsing error: $e');
    formattedStartDate = 'Invalid';
    formattedReturnDate = 'Invalid';
  }

  // Format the total amount
  formattedTotalAmount = NumberFormat.currency(symbol: '₹', decimalDigits: 2)
      .format(totalAmount);

  setState(() {
    // Ensure UI is updated after recalculating
  });
}


  Future<void> updateDeliveryStatus() async {
    final cartStatus = widget.delivery['cart_status'];
    final isReturn = cartStatus == 5;
    final newStatus = isReturn ? 6 : 4;

    try {
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': newStatus})
          .eq('cart_id', widget.delivery['cart_id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isReturn
              ? 'Item marked as picked'
              : 'Item marked as delivered'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error updating status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartStatus = widget.delivery['cart_status'];
    final isReturn = cartStatus == 5;
    final buttonText = isReturn ? 'Item Picked' : 'Delivered';

    final userName = user['user_name'] ?? 'Unknown';
    final userContact = user['user_contact'] ?? 'N/A';
    final userAddress = user['user_address'] ?? 'N/A';

    return Scaffold(
      appBar: AppBar(
        title: Text(isReturn ? 'Return Details' : 'Delivery Details'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'User Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text('Name: $userName', style: TextStyle(fontSize: 16)),
                Text('Contact: $userContact', style: TextStyle(fontSize: 16)),
                Text('Address: $userAddress', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 10),
                Text(
                  'Start Date:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  formattedStartDate,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Text(
                  'Return Date:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  formattedReturnDate,
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(height: 20),
                Divider(),
                SizedBox(height: 10),
                Text(
                  'Total Amount:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  formattedTotalAmount,
                  style: TextStyle(fontSize: 22, color: Colors.green),
                ),
                Spacer(),
                ElevatedButton(
                  onPressed: updateDeliveryStatus,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isReturn ? Colors.orange : Colors.green,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    textStyle:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  child: Text(buttonText),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
