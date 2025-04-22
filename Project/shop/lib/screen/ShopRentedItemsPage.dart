import 'package:flutter/material.dart';
//import 'package:shop/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ShopRentedItemsPage extends StatefulWidget {
  const ShopRentedItemsPage({super.key});

  @override
  _ShopRentedItemsPageState createState() => _ShopRentedItemsPageState();
}

class _ShopRentedItemsPageState extends State<ShopRentedItemsPage> {
  List<Map<String, dynamic>> rentedItems = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadRentedItems();
  }

  Future<void> _loadRentedItems() async {
    if (!mounted) return;
    
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final items = await fetchRentedItems();
      if (mounted) {
        setState(() {
          rentedItems = items;
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error loading items: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<List<Map<String, dynamic>>> fetchRentedItems() async {
    try {
      // Fetch cart items with status 6 directly, with all necessary joins
      final response = await Supabase.instance.client
          .from('tbl_cart')
          .select('''
            cart_id, cart_qty, cart_status,
            tbl_item!inner(item_id, item_name, item_photo, item_rentprice),
            tbl_booking!inner(booking_id, start_date, return_date, booking_totalprice)
          ''')
          .eq('cart_status', 6);
      
      debugPrint('Cart items found: ${response.length}');
      
      // Convert to list of maps
      final List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(response);
      
      return items;
    } catch (e) {
      debugPrint('Error fetching rented items: $e');
      if (e is PostgrestException) {
        debugPrint('Supabase error details: ${e.message}, ${e.code}, ${e.details}');
      }
      throw Exception('Failed to load rented items: $e');
    }
  }

  Future<void> markAsReturned(int cartId) async {
    try {
      setState(() {
        isLoading = true;
      });
      
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': 7}) // Change status to 7 (Returned)
          .eq('cart_id', cartId);

      await _loadRentedItems();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item marked as returned successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      debugPrint('Error updating cart status: $e');
    }
  }

  Widget _buildItemCard(Map<String, dynamic> item) {
    final cartId = item['cart_id'];
    final itemName = item['tbl_item']['item_name'];
    final itemPhoto = item['tbl_item']['item_photo'];
    final startDate = item['tbl_booking']['start_date'];
    final returnDate = item['tbl_booking']['return_date'];
    final totalPrice = item['tbl_booking']['booking_totalprice'];
    final qty = item['cart_qty'];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with item name
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: Text(
              itemName,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
          ),
          
          // Item details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Image and basic info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: itemPhoto != null 
                          ? Image.network(
                              itemPhoto,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, e, s) => Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Quantity: $qty',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Start: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(startDate))}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Return: ${DateFormat('MMM dd, yyyy').format(DateTime.parse(returnDate))}',
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Total: ₹$totalPrice',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                // Return button
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () => markAsReturned(cartId),
                    icon: const Icon(Icons.check_circle),
                    label: const Text('Mark as Returned'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
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

  Widget _buildContentArea() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(errorMessage!),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadRentedItems,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (rentedItems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shopping_basket_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'No rented items found',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Make sure you have items with status 6 (Rented)',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadRentedItems,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: rentedItems.length,
      itemBuilder: (context, index) => _buildItemCard(rentedItems[index]),
      shrinkWrap: true,
      physics: const AlwaysScrollableScrollPhysics(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildContentArea();
  }
}
