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
      appBar: AppBar(
        title: Text(
          "Your Cart",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.shopping_cart_outlined,
                        size: 80,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        "Your cart is empty",
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
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
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    item['image'],
                                    width: 100,
                                    height: 100,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                // Product Details
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['name'],
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "₹${item['price']} per day",
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          "Available: ${itemStocks[item['item_id']] ?? 0} units",
                                          style: TextStyle(
                                            color: Colors.blue[700],
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            // Quantity Controls
                                            Container(
                                              decoration: BoxDecoration(
                                                border: Border.all(color: Colors.grey[300]!),
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  IconButton(
                                                    icon: Icon(Icons.remove, size: 18),
                                                    onPressed: () {
                                                      if (item['quantity'] > 1) {
                                                        int newQty = item['quantity'] - 1;
                                                        updateCartQuantity(item['cart_id'], item['item_id'], newQty);
                                                      }
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                  ),
                                                  Container(
                                                    width: 30,
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      item['quantity'].toString(),
                                                      style: TextStyle(fontSize: 14),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: Icon(Icons.add, size: 18),
                                                    onPressed: () {
                                                      int newQty = item['quantity'] + 1;
                                                      updateCartQuantity(item['cart_id'], item['item_id'], newQty);
                                                    },
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Delete Button
                                            IconButton(
                                              icon: Icon(Icons.delete_outline, color: Colors.red),
                                              onPressed: () {
                                                deleteCartItem(item['cart_id'], item['item_id'], item['quantity']);
                                              },
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
                      padding: EdgeInsets.all(16),
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
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Total Amount:",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                "₹${getTotalPrice().toStringAsFixed(2)}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
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
                                    SnackBar(content: Text('Failed to update stock. Please try again.')),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                padding: EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                "Proceed to Checkout",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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
