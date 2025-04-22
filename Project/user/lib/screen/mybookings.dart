import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaintpage.dart';
import 'package:intl/intl.dart';

class Mybookings extends StatefulWidget {
  const Mybookings({super.key});

  @override
  State<Mybookings> createState() => _MybookingsState();
}

class _MybookingsState extends State<Mybookings> {
  List<Map<String, dynamic>> bookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final bookingResponse = await Supabase.instance.client
          .from('tbl_booking')
          .select('*, tbl_cart(*, tbl_item(item_name,item_id))')
          .eq('user_id', user.id)
          .order('booking_date', ascending: false);

      setState(() {
        bookings = bookingResponse;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching bookings: $e");
      setState(() => isLoading = false);
    }
  }

  void _submitComplaint(int bookingId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ComplaintPage(bookingId: bookingId),
      ),
    );
  }

  Future<void> _returnProduct(int bookingId, int itemId) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Return'),
          content: Text('Are you sure you want to return this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text('Confirm'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get booking details to check dates and calculate potential refund
      final bookingResponse = await Supabase.instance.client
          .from('tbl_booking')
          .select('*, tbl_cart(*, tbl_item(item_rentprice))')
          .eq('booking_id', bookingId)
          .single();
      
      // Calculate the refund amount if returned early
      double updatedAmount = double.parse(bookingResponse['booking_totalprice'].toString());
      print('Original booking total price: $updatedAmount');
      DateTime now = DateTime.now();
      DateTime scheduledReturnDate = DateTime.parse(bookingResponse['return_date'] ?? now.toIso8601String());
      print('Current date: $now');
      print('Scheduled return date: $scheduledReturnDate');
      
      // Check if the return is early
      if (now.isBefore(scheduledReturnDate)) {
        print('Early return detected - calculating refund');
        // Find the specific cart item being returned
        final cartItem = (bookingResponse['tbl_cart'] as List).firstWhere(
          (item) => item['item_id'] == itemId,
          orElse: () => null
        );
        
        if (cartItem != null) {
          // Calculate days remaining and potential refund
          int daysRemaining = scheduledReturnDate.difference(now).inDays;
          print('Days remaining in rental period: $daysRemaining');
          
          if (daysRemaining > 0) {
            double dailyRate = double.parse(cartItem['tbl_item']['item_rentprice'].toString());
            print('Daily rate for this item: $dailyRate');
            
            int itemQuantity = cartItem['cart_qty'] ?? 1;
            print('Item quantity: $itemQuantity');
            
            double potentialRefund = dailyRate * daysRemaining * itemQuantity;
            print('Calculated potential refund: $potentialRefund');
            
            // Update the total amount
            updatedAmount = updatedAmount - potentialRefund;
            if (updatedAmount < 0) updatedAmount = 0;
            print('Updated booking total price after refund: $updatedAmount');
          }
        } else {
          print('Could not find the specific cart item in booking response');
        }
      } else {
        print('Return is not early - no refund needed');
      }

      // Update cart status to 5 (returned)
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': 5})
          .eq('booking_id', bookingId)
          .eq('item_id', itemId);
      print('Updated cart_status to 5 for item $itemId in booking $bookingId');

      // Update booking status, return date, and total price
      final nowString = DateTime.now().toIso8601String();
      final updateResponse = await Supabase.instance.client
          .from('tbl_booking')
          .update({
            'booking_status': 3, // Update booking status to returned
            'return_date': nowString,
            'booking_totalprice': updatedAmount.round() // Convert to integer by rounding
          })
          .eq('booking_id', bookingId);
      print('Updated booking with return date, status 3, and total price ${updatedAmount.round()}');
      print('Supabase update response: $updateResponse');

      // Verify the update was successful by fetching the booking again
      final verifyBooking = await Supabase.instance.client
          .from('tbl_booking')
          .select('booking_totalprice, booking_status, return_date')
          .eq('booking_id', bookingId)
          .single();
      print('Verification - Updated booking data: $verifyBooking');

      // Close loading dialog
      Navigator.pop(context);

      // Show success message with refund information if applicable
      String message = 'Product returned successfully';
      double originalAmount = double.parse(bookingResponse['booking_totalprice'].toString());
      if (updatedAmount < originalAmount) {
        double refundAmount = originalAmount - updatedAmount;
        message += '. Refund amount: ₹${refundAmount.toStringAsFixed(2)}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Refresh bookings list
      fetchBookings();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning product: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error returning product: $e');
    }
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            )
          : bookings.isEmpty
              ? _buildEmptyBookings()
              : RefreshIndicator(
                  onRefresh: fetchBookings,
                  color: Colors.blueAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      var booking = bookings[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Booking Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Booking #${booking['booking_id']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(booking['booking_date']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Items List
                            ListView.separated(
                              padding: const EdgeInsets.all(16),
                              separatorBuilder: (context, index) => const Divider(height: 24),
                              itemCount: booking['tbl_cart'].length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                var cartItem = booking['tbl_cart'][index];
                                return Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem['tbl_item']['item_name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Quantity: ${cartItem['cart_qty']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _returnProduct(booking['booking_id'], cartItem['tbl_item']['item_id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Return",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: () => _submitComplaint(cartItem['tbl_item']['item_id']),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        "Complaint",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            // Booking Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Total Price",
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        "₹${booking['booking_totalprice']}",
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blueAccent,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Return Date",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _formatDate(booking['return_date']),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyBookings() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 100,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            "No Bookings Found",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "You haven't made any bookings yet.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
