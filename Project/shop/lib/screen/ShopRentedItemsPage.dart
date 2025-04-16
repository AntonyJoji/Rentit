import 'package:flutter/material.dart';
import 'package:shop/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ShopRentedItemsPage extends StatefulWidget {
  const ShopRentedItemsPage({super.key});

  @override
  _ShopRentedItemsPageState createState() => _ShopRentedItemsPageState();
}

class _ShopRentedItemsPageState extends State<ShopRentedItemsPage> {
  late Future<List<Map<String, dynamic>>> rentedItems;

  Future<List<Map<String, dynamic>>> fetchRentedItems() async {
    try {
      final cartResponse = await Supabase.instance.client
          .from('tbl_cart')
          .select('cart_id, item_id, booking_id, cart_status, cart_qty')
          .eq('cart_status', 4); // Only rented

      final List<Map<String, dynamic>> cartItems =
          List<Map<String, dynamic>>.from(cartResponse);

      List<Map<String, dynamic>> rentedData = [];

      for (var cartItem in cartItems) {
        final itemId = cartItem['item_id'];
        final bookingId = cartItem['booking_id'];
        final cartQty = cartItem['cart_qty'];

        final itemResponse = await Supabase.instance.client
            .from('tbl_item')
            .select('item_name, item_photo, shop_id')
            .eq('item_id', itemId)
            .maybeSingle();

        if (itemResponse == null ||
            itemResponse['shop_id'] != supabase.auth.currentUser!.id) {
          continue;
        }

        final bookingResponse = await Supabase.instance.client
            .from('tbl_booking')
            .select(
                'booking_id, start_date, return_date, booking_status, booking_totalprice')
            .eq('booking_id', bookingId)
            .maybeSingle();

        if (bookingResponse != null) {
          rentedData.add({
            'cart_id': cartItem['cart_id'],
            'booking_id': bookingId,
            'cart_qty': cartQty,
            'tbl_item': itemResponse,
            'tbl_booking': bookingResponse
          });
        }
      }

      return rentedData;
    } catch (e) {
      debugPrint('Error fetching rented items: $e');
      return [];
    }
  }

  Future<void> markAsReturned(int cartId) async {
    try {
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': 5})
          .eq('cart_id', cartId);

      setState(() {
        rentedItems = fetchRentedItems();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Marked as Returned')),
      );
    } catch (e) {
      debugPrint('Error updating cart status: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    rentedItems = fetchRentedItems();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: FutureBuilder<List<Map<String, dynamic>>>(
        future: rentedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No rented items.'));
          } else {
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                final cartId = item['cart_id'];
                final itemName = item['tbl_item']['item_name'];
                final itemPhoto = item['tbl_item']['item_photo'];
                final startDate = item['tbl_booking']['start_date'];
                final returnDate = item['tbl_booking']['return_date'];
                final totalPrice = item['tbl_booking']['booking_totalprice'];
                final qty = item['cart_qty'];

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: itemPhoto != null
                              ? Image.network(itemPhoto,
                                  width: 80, height: 80, fit: BoxFit.cover)
                              : Icon(Icons.image_not_supported, size: 80),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemName,
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Text('Qty: $qty'),
                              Text(
                                  'Start: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(startDate))}'),
                              Text(
                                  'Return: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(returnDate))}'),
                              Text('Total Price: ₹$totalPrice'),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => markAsReturned(cartId),
                          child: Text('Mark Returned'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
