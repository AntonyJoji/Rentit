import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/CheckoutPage.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  _CartPageState createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> cartItems = [];
  Map<int, int> itemStocks = {}; // Store stock quantities
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchCartItems();
  }

  int? bid;

  // Fetch Cart Items from Supabase
  Future<void> fetchCartItems() async {
    try {
      final bookingResponse = await supabase.from('tbl_booking').select("booking_id")
        .eq('user_id', supabase.auth.currentUser!.id)
        .eq('booking_status', 0)
        .order('booking_date', ascending: false)
        .limit(1);

      if (bookingResponse.isEmpty) {
        print("No active booking found.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      int bookingId = bookingResponse[0]['booking_id'];

      setState(() {
        bid = bookingId;
      });

      final cartResponse = await supabase
          .from('tbl_cart')
          .select('*')
          .eq('booking_id', bookingId)
          .eq('cart_status', 0);

      List<Map<String, dynamic>> items = [];
      Map<int, int> stocks = {};

      for (var cartItem in cartResponse) {
        // Fetch item details
        final itemResponse = await supabase
            .from('tbl_item')
            .select('item_name, item_photo, item_rentprice')
            .eq('item_id', cartItem['item_id'])
            .maybeSingle();

        // Fetch stock information
        final stockResponse = await supabase
            .from('tbl_stock')
            .select('stock_quantity')
            .eq('item_id', cartItem['item_id'])
            .order('stock_date', ascending: false)
            .limit(1)
            .maybeSingle();

        if (itemResponse != null) {
          items.add({
            "cart_id": cartItem['cart_id'],
            "item_id": cartItem['item_id'],
            "name": itemResponse['item_name'],
            "image": itemResponse['item_photo'],
            "price": itemResponse['item_rentprice'],
            "quantity": cartItem['cart_qty'],
          });

          // Store stock information
          stocks[cartItem['item_id']] = stockResponse?['stock_quantity'] ?? 0;
        }
      }

      setState(() {
        cartItems = items;
        itemStocks = stocks;
        isLoading = false;
      });

    } catch (e) {
      print("Error fetching cart data: $e");
      setState(() => isLoading = false);
    }
  }

  // Delete Item from Cart
  Future<void> deleteCartItem(int cartId, int itemId, int quantity) async {
    try {
      print('Deleting cart item - Cart ID: $cartId, Item ID: $itemId, Quantity: $quantity');
      
      await supabase.from('tbl_cart').delete().eq('cart_id', cartId);

      // Update stock when item is removed from cart
      final currentStock = itemStocks[itemId] ?? 0;
      final newStock = currentStock + quantity;
      print('Current stock: $currentStock, New stock: $newStock');

      // Insert new stock record
      final stockResponse = await supabase
          .from('tbl_stock')
          .insert({
            'item_id': itemId,
            'stock_quantity': newStock,
            'stock_date': DateTime.now().toIso8601String(),
          })
          .select();
      
      print('Stock update response: $stockResponse');

      // Update local stock map
      setState(() {
        itemStocks[itemId] = newStock.toInt();
      });

      fetchCartItems(); // Refresh cart after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Item removed from cart.')),
      );
    } catch (e) {
      print("Error deleting item: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete item. Please try again.')),
      );
    }
  }

  // **Updated Cart Quantity Method**
  Future<void> updateCartQuantity(int cartId, int itemId, int newQuantity) async {
    try {
      print('Updating cart quantity - Cart ID: $cartId, Item ID: $itemId, New Quantity: $newQuantity');
      
      // Check if new quantity exceeds available stock
      if (newQuantity > (itemStocks[itemId] ?? 0)) {
        print('Error: New quantity ($newQuantity) exceeds available stock (${itemStocks[itemId]})');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot add more than available stock')),
        );
        return;
      }

      // Get the current cart item to calculate the difference
      final currentCartItem = cartItems.firstWhere((item) => item['cart_id'] == cartId);
      final quantityDifference = newQuantity - currentCartItem['quantity'];
      print('Quantity difference: $quantityDifference');

      // Update cart quantity
      await supabase
          .from('tbl_cart')
          .update({'cart_qty': newQuantity})
          .eq('cart_id', cartId);

      // Update stock quantity
      final currentStock = itemStocks[itemId] ?? 0;
      final newStock = currentStock - quantityDifference;
      print('Current stock: $currentStock, New stock: $newStock');

      // Insert new stock record
      final stockResponse = await supabase
          .from('tbl_stock')
          .insert({
            'item_id': itemId,
            'stock_quantity': newStock,
            'stock_date': DateTime.now().toIso8601String(),
          })
          .select();
      
      print('Stock update response: $stockResponse');

      // Update local stock map
      setState(() {
        itemStocks[itemId] = newStock.toInt();
      });

      fetchCartItems(); // Refresh cart after updating quantity
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cart quantity updated.')),
      );
    } catch (e) {
      print("Error updating cart quantity: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity. Please try again.')),
      );
    }
  }

  // Calculate Total Price
  double getTotalPrice() {
    return cartItems.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  // Update stock for all items in cart
  Future<void> updateStockForCheckout() async {
    try {
      print('Updating stock for checkout');
      
      for (var item in cartItems) {
        final itemId = item['item_id'];
        final quantity = item['quantity'];
        final currentStock = itemStocks[itemId] ?? 0;
        final newStock = currentStock - quantity;
        
        print('Updating stock for item $itemId - Current: $currentStock, New: $newStock');
        
        // Insert new stock record
        final stockResponse = await supabase
            .from('tbl_stock')
            .insert({
              'item_id': itemId,
              'stock_quantity': newStock,
              'stock_date': DateTime.now().toIso8601String(),
            })
            .select();
        
        print('Stock update response for item $itemId: $stockResponse');
        
        // Update local stock map
        setState(() {
          itemStocks[itemId] = newStock.toInt();
        });
      }
    } catch (e) {
      print("Error updating stock for checkout: $e");
      throw e; // Re-throw to handle in the calling function
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 24),
            SizedBox(width: 8),
            Text(
              "Your Cart",
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
        actions: [
          SizedBox(width: 48), // Balance the centered title
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              ),
            )
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.shopping_cart_outlined,
                          size: 70,
                          color: Colors.blue.shade700,
                        ),
                      ),
                      SizedBox(height: 24),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "Add items to start shopping",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          var item = cartItems[index];
                          return Container(
                            margin: EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                Hero(
                                  tag: 'cart_image_${item['item_id']}',
                                  child: Container(
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(16),
                                        bottomLeft: Radius.circular(16),
                                      ),
                                      image: DecorationImage(
                                        image: NetworkImage(item['image']),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ),
                                // Product Details
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.grey.shade800,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.green.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "₹${item['price']} per day",
                                                style: TextStyle(
                                                  color: Colors.green.shade700,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: 8,
                                                vertical: 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                "${itemStocks[item['item_id']] ?? 0} available",
                                                style: TextStyle(
                                                  color: Colors.blue.shade700,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Quantity Controls
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  _buildQuantityButton(
                                                    Icons.remove,
                                                    () {
                                                      if (item['quantity'] > 1) {
                                                        updateCartQuantity(
                                                          item['cart_id'],
                                                          item['item_id'],
                                                          item['quantity'] - 1,
                                                        );
                                                      }
                                                    },
                                                  ),
                                                  Container(
                                                    width: 35,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      item['quantity'].toString(),
                                                      style: TextStyle(
                                                        fontSize: 16,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                                  _buildQuantityButton(
                                                    Icons.add,
                                                    () {
                                                      updateCartQuantity(
                                                        item['cart_id'],
                                                        item['item_id'],
                                                        item['quantity'] + 1,
                                                      );
                                                    },
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Delete Button
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: IconButton(
                                                icon: Icon(
                                                  Icons.delete_outline,
                                                  color: Colors.red.shade400,
                                                ),
                                                onPressed: () {
                                                  deleteCartItem(
                                                    item['cart_id'],
                                                    item['item_id'],
                                                    item['quantity'],
                                                  );
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    // Bottom Total and Checkout
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: Offset(0, -5),
                          ),
                        ],
                      ),
                      child: SafeArea(
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Total Amount",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                                Text(
                                  "₹${getTotalPrice().toStringAsFixed(2)}",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              height: 54,
                              child: ElevatedButton(
                                onPressed: () async {
                                  try {
                                    await updateStockForCheckout();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CheckoutPage(bid: bid!),
                                      ),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Failed to update stock. Please try again.'),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade700,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.shopping_bag_outlined),
                                    SizedBox(width: 8),
                                    Text(
                                      "Proceed to Checkout",
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
                    ),
                  ],
                ),
    );
  }

  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return Container(
      width: 32,
      height: 32,
      margin: EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16, color: Colors.grey.shade700),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(),
      ),
    );
  }
}
