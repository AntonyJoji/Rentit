import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
//import 'package:user/screen/cart.dart';

class ProductPage extends StatefulWidget {
  final int itemId; // Pass only item ID

  const ProductPage({super.key, required this.itemId});

  @override
  _ProductPageState createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? product;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    try {
      final response = await supabase
          .from('tbl_item')
          .select()
          .eq('item_id', widget.itemId)
          .single(); // Fetch single product

      setState(() {
        product = response;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching product details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addToCart(int id) async {
    try {
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('booking_status', 0)
          .eq('user_id', supabase.auth.currentUser!.id)
          .maybeSingle();

      int bookingId;
      if (booking == null) {
        final response = await supabase
            .from('tbl_booking')
            .insert([
              {'user_id': supabase.auth.currentUser!.id, 'booking_status': 0}
            ])
            .select("booking_id")
            .single();
        bookingId = response['booking_id'];
      } else {
        bookingId = booking['booking_id'];
      }

      final cartResponse = await supabase
          .from('tbl_cart')
          .select()
          .eq('booking_id', bookingId)
          .eq('item_id', id);

      if (cartResponse.isEmpty) {
        await addCart(context, bookingId, id);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Item already in cart")));
      }
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  Future<void> addCart(BuildContext context, int bid, int cid) async {
    try {
      await supabase.from('tbl_cart').insert([
        {
          'booking_id': bid,
          'item_id': cid,
        }
      ]);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Added to cart")));
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product?['item_name'] ?? "Loading...")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : product == null
              ? Center(child: Text("Product not found"))
              : SingleChildScrollView(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        product?['item_photo'] ??
                            'https://via.placeholder.com/250',
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.broken_image, size: 250),
                      ),
                      SizedBox(height: 16),
                      Text(product?['item_name'] ?? 'Unknown Item',
                          style: TextStyle(
                              fontSize: 24, fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      Text(product?['item_details'] ?? 'No details available',
                          style: TextStyle(fontSize: 16)),
                      SizedBox(height: 16),
                      Text(
                          "Price: ₹${product?['item_rentprice'] ?? 'N/A'} per day",
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          addToCart(product?['item_id']);
                        },
                        child: Text("Add to Cart"),
                      ),
                    ],
                  ),
                ),
    );
  }
}
