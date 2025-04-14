import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderDetailsPage extends StatefulWidget {
  final int bid;
  const OrderDetailsPage({super.key, required this.bid});

  @override
  State<OrderDetailsPage> createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  List<Map<String, dynamic>> orderItems = [];
  Map<String, dynamic>? userDetails;
  Map<String, dynamic>? bookingDetails;
  bool isLoading = true;
  List<Map<String, dynamic>> deliveryBoys = [];

  @override
  void initState() {
    super.initState();
    fetchOrderData();
    fetchDeliveryBoys();
  }

  Future<void> fetchOrderData() async {
    try {
      await Future.wait([
        fetchItems(),
        fetchUserDetails(),
        fetchBookingDetails(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching data: $e")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchUserDetails() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select('tbl_user:user_id(*)')
        .eq('booking_id', widget.bid)
        .single();

    setState(() {
      userDetails = response['tbl_user'];
    });
  }

  Future<void> fetchBookingDetails() async {
    final response = await Supabase.instance.client
        .from('tbl_booking')
        .select('*')
        .eq('booking_id', widget.bid)
        .single();

    setState(() {
      bookingDetails = response;
    });
  }

  Future<void> fetchItems() async {
    final response = await Supabase.instance.client
        .from('tbl_cart')
        .select("*,tbl_item(*)")
        .eq('booking_id', widget.bid);

    print("Fetched order items: $response"); // Added to debug fetched items

    setState(() {
      orderItems = response
          .map<Map<String, dynamic>>((item) => {
                'id': item['cart_id'],
                'product': item['tbl_item']['item_name'],
                'image': item['tbl_item']['item_photo'],
                'qty': item['cart_qty'],
                'status': item['cart_status'],
                'selectedBoy': item['boy_id']?.toString(),
              })
          .toList();
    });
  }

  Future<void> fetchDeliveryBoys() async {
    final response = await Supabase.instance.client.from('tbl_deliveryboy').select('*');
    print("Fetched delivery boys: $response"); // Added to debug fetched delivery boys
    setState(() {
      deliveryBoys = List<Map<String, dynamic>>.from(response);
    });
  }

 Future<void> conformed(int cartId) async {
  print("Conformed method called for cartId: $cartId");

  try {
    final item = orderItems.firstWhere((element) => element['id'] == cartId);
    final selectedBoyId = item['selectedBoy'];

    print("Selected boy id: $selectedBoyId"); // Added to check if a boy is selected

    if (selectedBoyId != null && selectedBoyId.isNotEmpty) {
      final parsedBoyId = selectedBoyId;

      print("Assigning delivery boy id: $parsedBoyId to cart_id: $cartId");

      // Perform the update query
      final updateResponse = await Supabase.instance.client
          .from('tbl_cart')
          .update({
            'cart_status': 3, // Assuming status 3 is for confirmed/assigned state
            'boy_id': parsedBoyId, // Assigning the selected delivery boy
          })
          .eq('cart_id', cartId)
          .select(); // Selecting the updated row to confirm the update

      print("Update response: $updateResponse"); // Debugging the update response

      // Ensure the update was successful
      if (updateResponse.isNotEmpty) {
        // Update the UI state
        setState(() {
          item['status'] = 3; // Mark item as confirmed
          item['selectedBoy'] = selectedBoyId; // Update the selected boy
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Delivery boy assigned successfully!")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to assign the delivery boy.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No delivery boy selected, please select one.")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 245, 245, 250),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Details",
                    style: GoogleFonts.sanchez(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (userDetails != null)
                    Card(
                      child: ListTile(
                        title: Text("Name: ${userDetails!['user_name']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Address: ${userDetails!['user_address']}"),
                            Text("Contact: ${userDetails!['user_contact']}"),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  if (bookingDetails != null)
                    Card(
                      child: ListTile(
                        title: Text("Booking Date: ${bookingDetails!['booking_date']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Return Date: ${bookingDetails!['return_date']}"),
                            Text("Total Price: \$${bookingDetails!['booking_totalprice']}"),
                            Text("Payment Status: ${bookingDetails!['payment_status']}"),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: orderItems.isEmpty
                        ? const Center(child: Text("No items in this order"))
                        : ListView.builder(
                            itemCount: orderItems.length,
                            itemBuilder: (context, index) {
                              final item = orderItems[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 10),
                                child: ListTile(
                                  leading: Image.network(
                                    item['image'],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                  title: Text(item['product']),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text("Quantity: ${item['qty']}"),
                                      const SizedBox(height: 5),
                                      DropdownButtonFormField<String>(
                                        value: item['selectedBoy'],
                                        hint: const Text("Select Delivery Boy"),
                                        items: deliveryBoys.map((boy) {
                                          return DropdownMenuItem(
                                            value: boy['boy_id'].toString(),
                                            child: Text(boy['boy_name']),
                                          );
                                        }).toList(),
                                        onChanged: item['status'] == 3
                                            ? null
                                            : (value) {
                                                setState(() {
                                                  item['selectedBoy'] = value ?? '';
                                                });
                                              },
                                      ),
                                    ],
                                  ),
                                  trailing: ElevatedButton(
                                    onPressed: item['status'] == 3
                                        ? null
                                        : () => conformed(item['id']),
                                    child: const Text("Confirm"),
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
