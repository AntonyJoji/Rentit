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
      final booking = await supabase.from('tbl_booking').select("booking_id").eq('user_id', supabase.auth.currentUser!.id).eq('booking_status', 0).maybeSingle();
      int bookingId = booking!['booking_id'];
      setState(() {
        bid=bookingId;
      });
      final cartResponse = await supabase
          .from('tbl_cart')
          .select('*')
          .eq('booking_id', bookingId)
          .eq('cart_status', 0);

      List<Map<String, dynamic>> items = [];

      for (var cartItem in cartResponse) {
        final itemResponse = await supabase
            .from('tbl_item')
            .select('item_name, item_photo, item_rentprice')
            .eq('item_id', cartItem['item_id'])
            .maybeSingle();

        if (itemResponse != null) {
          items.add({
            "cart_id": cartItem['cart_id'],
            "name": itemResponse['item_name'],
            "image": itemResponse['item_photo'],
            "price": itemResponse['item_rentprice'],
            "quantity": cartItem['cart_qty'],
          });
        }
      }

      setState(() {
        cartItems = items;
        isLoading = false;
      });
    } catch (e) {
      print("Error fetching cart data: $e");
      setState(() => isLoading = false);
    }
  }

  // Update Cart Quantity
  Future<void> updateCartQuantity(int cartId, int newQty) async {
    try {
      await supabase
          .from('tbl_cart')
          .update({'cart_qty': newQty})
          .eq('cart_id', cartId);

      fetchCartItems(); // Refresh the cart after updating
    } catch (e) {
      print("Error updating cart quantity: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update quantity. Please try again.')),
      );
    }
  }

  // Delete Item from Cart
  Future<void> deleteCartItem(int cartId) async {
    try {
      await supabase.from('tbl_cart').delete().eq('cart_id', cartId);

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

  // Calculate Total Price
  double getTotalPrice() {
    return cartItems.fold(
        0, (sum, item) => sum + (item['price'] * item['quantity']));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Your Cart")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : cartItems.isEmpty
              ? Center(child: Text("Your cart is empty"))
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          var item = cartItems[index];
                          return Container(
                            margin: EdgeInsets.all(8),
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black12, blurRadius: 4)
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Image.network(item['image'],
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover),
                                SizedBox(height: 8),
                                Text(item['name'],
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                                Text("\$${item['price']} per item"),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.remove, size: 18),
                                          onPressed: () {
                                            if (item['quantity'] > 1) {
                                              int newQty = item['quantity'] - 1;
                                              updateCartQuantity(
                                                  item['cart_id'], newQty);
                                            }
                                          },
                                        ),
                                        Text(item['quantity'].toString(),
                                            style: TextStyle(fontSize: 14)),
                                        IconButton(
                                          icon: Icon(Icons.add, size: 18),
                                          onPressed: () {
                                            int newQty = item['quantity'] + 1;
                                            updateCartQuantity(
                                                item['cart_id'], newQty);
                                          },
                                        ),
                                      ],
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        deleteCartItem(item['cart_id']);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4)
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Total:",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                              Text("\$${getTotalPrice().toStringAsFixed(2)}",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => CheckoutPage(bid: bid!,)),
                                );
                              },
                              child: Text("Proceed to Checkout",
                                  style: TextStyle(fontSize: 14)),
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
