import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductPage extends StatefulWidget {
  final int itemId; // Pass only item ID

  const ProductPage({super.key, required this.itemId});

  @override
  _ProductPageState createState() => _ProductPageState();
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
          .single(); // Fetch single product

      print('Raw response from Supabase: $response'); // Debug log
      print('All available fields: ${response.keys.toList()}'); // Debug log
      print('Item details value: ${response['item_details']}'); // Debug log
      print('Item name value: ${response['item_name']}'); // Debug log
      print('Item photo value: ${response['item_photo']}'); // Debug log
      print('Item rent price value: ${response['item_rentprice']}'); // Debug log

      // Fetch stock information
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

      print('Product fetched successfully: $product'); // Debug log
      print('Stock quantity: $stockQuantity');
    } catch (e) {
      print('Error fetching product details: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> addToCart(int itemId) async {
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
          .eq('item_id', itemId);

      if (cartResponse.isEmpty) {
        await addCart(context, bookingId, itemId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Item already in cart")),
        );
      }
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  Future<void> addCart(BuildContext context, int bookingId, int itemId) async {
    try {
      await supabase.from('tbl_cart').insert([
        {
          'booking_id': bookingId,
          'item_id': itemId,
        }
      ]);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Added to cart")),
      );
    } catch (e) {
      print('Error adding to cart: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'RentIt',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main Product Details Section
          Expanded(
            child: isLoading
                ? Center(child: CircularProgressIndicator())
                : product == null
                    ? Center(child: Text("Product not found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)))
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product Image with gradient overlay
                            Stack(
                              children: [
                                Container(
                                  height: 220,
                                  width: double.infinity,
                                  margin: EdgeInsets.only(top: 10),
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      product?['item_photo'] ?? 'https://via.placeholder.com/250',
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Icon(Icons.broken_image, size: 250),
                                    ),
                                  ),
                                ),
                                // Gradient overlay
                                Container(
                                  height: 220,
                                  margin: EdgeInsets.only(top: 10),
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withOpacity(0.7),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            // Product Info Section
                            Padding(
                              padding: EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Product Name
                                  Text(
                                    product?['item_name'] ?? 'Unknown Item',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 15),

                                  // Price Badge
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.green[50],
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      "₹${product?['item_rentprice'] ?? 'N/A'} / day",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green[700],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 15),

                                  // Stock Information
                                  if (stockQuantity! <= 0)
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.red[50],
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.inventory_2_rounded,
                                            color: Colors.red[700],
                                            size: 18,
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            "Out of Stock",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.red[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  SizedBox(height: 20),

                                  // Description Section
                                  Text(
                                    "Description",
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 8),
                                  Container(
                                    padding: EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey[200]!),
                                    ),
                                    child: Text(
                                      product?['item_detail'] ?? 'No details available',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey[700],
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
          ),

          // Bottom Action Bar
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: stockQuantity! > 0 ? () {
                      addToCart(widget.itemId);
                    } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stockQuantity! > 0 ? Colors.blueAccent : Colors.grey[400],
                      padding: EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      stockQuantity! > 0 ? "Add to Cart" : "Out of Stock",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
