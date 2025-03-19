import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaintpage.dart'; // Imported ComplaintPage

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF64B5F6)))
          : bookings.isEmpty
              ? _buildEmptyBookings()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookings.length,
                  itemBuilder: (context, index) {
                    var booking = bookings[index];
                    print(booking['tbl_cart']);
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
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListView.separated(
                              separatorBuilder: (context, index) => const Divider(),
                              itemCount: booking['tbl_cart'].length,
                              shrinkWrap: true,
                              physics: NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                print(booking['tbl_cart'][index]['tbl_item']);
                              return ListTile(
                                title: Text(booking['tbl_cart'][index]['tbl_item']['item_name']),
                                subtitle: Text("Quantity: ${booking['tbl_cart'][index]['cart_qty']}"),
                                trailing: ElevatedButton(
                              onPressed: () => _submitComplaint(booking['tbl_cart'][index]['tbl_item']['item_id']),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                              ),
                              child: const Text("Complaint"),
                            ),
                              );
                            },),
                             const Divider(),
                            Text(
                              "Total Price: ₹${booking['booking_totalprice']}",
                              style: const TextStyle(
                                fontSize: 16,
                                color: Color(0xFF64B5F6),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Return Date: ${booking['return_date'] ?? 'N/A'}",
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
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
