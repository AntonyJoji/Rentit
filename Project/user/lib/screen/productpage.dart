import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductPage extends StatefulWidget {
  final int itemId;

  const ProductPage({super.key, required this.itemId});

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  final SupabaseClient supabase = Supabase.instance.client;
  Map<String, dynamic>? product;
  int? stockQuantity;
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
          .single();

      final stockResponse = await supabase
          .from('tbl_stock')
          .select('stock_quantity')
          .eq('item_id', widget.itemId)
          .order('stock_date', ascending: false)
          .limit(1)
          .maybeSingle();

      setState(() {
        product = response;
        stockQuantity = stockResponse?['stock_quantity'] ?? 0;
        isLoading = false;
      });
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addToCart(int itemId) async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final booking = await supabase
          .from('tbl_booking')
          .select()
          .eq('booking_status', 0)
          .eq('user_id', userId)
          .maybeSingle();

      int bookingId;
      if (booking == null) {
        final response = await supabase
            .from('tbl_booking')
            .insert([
              {'user_id': userId, 'booking_status': 0}
            ])
            .select("booking_id")
            .single();
        bookingId = response['booking_id'];
      } else {
        bookingId = booking['booking_id'];
      }

      final cartItem = await supabase
          .from('tbl_cart')
          .select()
          .eq('booking_id', bookingId)
          .eq('item_id', itemId);

      if (cartItem.isEmpty) {
        await supabase.from('tbl_cart').insert([
          {'booking_id': bookingId, 'item_id': itemId}
        ]);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Added to cart")));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item already in cart")));
      }
    } catch (e) {
      print('Add to cart error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Product Details", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : product == null
              ? const Center(child: Text("Product not found"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              product!['item_photo'] ?? 'https://via.placeholder.com/250',
                              height: 220,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 100),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Name & Price
                          Text(
                            product!['item_name'] ?? 'Unknown Product',
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "₹${product!['item_rentprice']} / day",
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Stock Info
                          if (stockQuantity == 0)
                            Row(
                              children: [
                                Icon(Icons.warning, color: Colors.red[400]),
                                const SizedBox(width: 8),
                                Text(
                                  "Out of Stock",
                                  style: TextStyle(color: Colors.red[400], fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          const SizedBox(height: 20),

                          // Description
                          Text(
                            "Description",
                            style: theme.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              product!['item_detail'] ?? 'No details available',
                              style: const TextStyle(fontSize: 16, height: 1.5),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Button
                    SafeArea(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: stockQuantity! > 0 ? () => addToCart(widget.itemId) : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                stockQuantity! > 0 ? Colors.blueAccent : Colors.grey,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            "Add to Cart",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
