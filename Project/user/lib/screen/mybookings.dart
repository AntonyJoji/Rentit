import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaintpage.dart';
import 'package:intl/intl.dart';

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

      // Update the bucket name for consistency
      final supabaseBucket = 'shop';
      print('Using Supabase storage bucket: $supabaseBucket');

      // Get complete booking data in a single query for debugging
      final rawBookings = await Supabase.instance.client
          .from('tbl_booking')
          .select('*')
          .eq('user_id', user.id)
          .order('booking_date', ascending: false);
          
      print('RAW DATABASE RESPONSE:');
      for (var booking in rawBookings) {
        print('BOOKING ID: ${booking['booking_id']}');
        print('ALL FIELDS: ${booking.keys.toList()}');
        print('ALL VALUES: ${booking.toString()}');
      }
      
      // First just get the booking IDs
      final bookingIds = await Supabase.instance.client
          .from('tbl_booking')
          .select('booking_id')
          .eq('user_id', user.id)
          .order('booking_date', ascending: false);
          
      print('Found ${bookingIds.length} bookings');
      
      // Process each booking individually to ensure we get all fields
      List<Map<String, dynamic>> processedBookings = [];
      
      for (var bookingIdData in bookingIds) {
        final bookingId = bookingIdData['booking_id'];
        
        // Get complete booking data
        final bookingData = await Supabase.instance.client
            .from('tbl_booking')
            .select('*')
            .eq('booking_id', bookingId)
            .single();
            
        print('BOOKING $bookingId - RAW DATA:');
        print(bookingData);
        print('BOOKING $bookingId - TOTAL PRICE: ${bookingData['booking_totalprice']}');
        
        // Get cart items
        final cartItems = await Supabase.instance.client
            .from('tbl_cart')
            .select('*, tbl_item(item_name, item_id, item_rentprice)')
            .eq('booking_id', bookingId);
            
        // Create enriched booking object
        final enrichedBooking = {
          ...bookingData,
          'tbl_cart': cartItems
        };
        
        // Calculate and add total price if not present
        if (!enrichedBooking.containsKey('booking_totalprice') || 
            enrichedBooking['booking_totalprice'] == null || 
            enrichedBooking['booking_totalprice'] == 0) {
          
          int calculatedTotal = calculateTotalPrice(enrichedBooking);
          if (calculatedTotal > 0) {
            enrichedBooking['booking_totalprice'] = calculatedTotal;
            print('Added calculated total price for booking $bookingId: $calculatedTotal');
          }
        }
        
        processedBookings.add(enrichedBooking);
      }
      
      print('Processed ${processedBookings.length} bookings with details');
      
      setState(() {
        bookings = processedBookings;
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

  Future<void> _returnProduct(int bookingId, int itemId) async {
    try {
      // Show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Confirm Return'),
          content: Text('Are you sure you want to return this product?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
              ),
              child: Text('Confirm'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get booking details to check dates and calculate potential refund
      final bookingResponse = await Supabase.instance.client
          .from('tbl_booking')
          .select('*, tbl_cart(*)')
          .eq('booking_id', bookingId)
          .single();
      
      print('Original booking data: $bookingResponse');
      
      // Retrieve the current total price
      int currentTotalPrice = 0;
      if (bookingResponse['booking_totalprice'] != null) {
        // Handle different data types
        if (bookingResponse['booking_totalprice'] is int) {
          currentTotalPrice = bookingResponse['booking_totalprice'];
        } else if (bookingResponse['booking_totalprice'] is double) {
          currentTotalPrice = bookingResponse['booking_totalprice'].round();
        } else if (bookingResponse['booking_totalprice'] is String) {
          currentTotalPrice = double.parse(bookingResponse['booking_totalprice']).round();
        }
      }
      
      print('Current Total Price: $currentTotalPrice');
      
      // Calculate the refund amount if returned early
      // Default to existing total price or 0 if null
      double updatedAmount = currentTotalPrice.toDouble();
      
      print('Original booking total price: $updatedAmount');
      DateTime now = DateTime.now();
      DateTime scheduledReturnDate = DateTime.parse(bookingResponse['return_date'] ?? now.toIso8601String());
      print('Current date: $now');
      print('Scheduled return date: $scheduledReturnDate');
      
      // Check if the return is early
      if (now.isBefore(scheduledReturnDate)) {
        print('Early return detected - calculating refund');
        // Find the specific cart item being returned
        final cartItem = (bookingResponse['tbl_cart'] as List).firstWhere(
          (item) => item['item_id'] == itemId,
          orElse: () => null
        );
        
        if (cartItem != null) {
          // Get the item details
          final itemDetails = await Supabase.instance.client
              .from('tbl_item')
              .select('item_rentprice')
              .eq('item_id', itemId)
              .single();
              
          // Calculate days remaining and potential refund
          int daysRemaining = scheduledReturnDate.difference(now).inDays;
          print('Days remaining in rental period: $daysRemaining');
          
          if (daysRemaining > 0) {
            double dailyRate = 0;
            if (itemDetails != null && itemDetails['item_rentprice'] != null) {
              if (itemDetails['item_rentprice'] is int) {
                dailyRate = itemDetails['item_rentprice'].toDouble();
              } else if (itemDetails['item_rentprice'] is double) {
                dailyRate = itemDetails['item_rentprice'];
              } else if (itemDetails['item_rentprice'] is String) {
                dailyRate = double.parse(itemDetails['item_rentprice']);
              }
            }
            print('Daily rate for this item: $dailyRate');
            
            int itemQuantity = cartItem['cart_qty'] ?? 1;
            print('Item quantity: $itemQuantity');
            
            double potentialRefund = dailyRate * daysRemaining * itemQuantity;
            print('Calculated potential refund: $potentialRefund');
            
            // Update the total amount
            updatedAmount = updatedAmount - potentialRefund;
            if (updatedAmount < 0) updatedAmount = 0;
            print('Updated booking total price after refund: $updatedAmount');
          }
        } else {
          print('Could not find the specific cart item in booking response');
        }
      } else {
        print('Return is not early - no refund needed');
      }

      // Update cart status to 5 (returned)
      await Supabase.instance.client
          .from('tbl_cart')
          .update({'cart_status': 5})
          .eq('booking_id', bookingId)
          .eq('item_id', itemId);
      print('Updated cart_status to 5 for item $itemId in booking $bookingId');

      // Update booking status, return date, and total price
      final nowString = DateTime.now().toIso8601String();
      final int finalPrice = updatedAmount.round();
      print('Final price to update in database: $finalPrice (type: ${finalPrice.runtimeType})');
      
      final updateResponse = await Supabase.instance.client
          .from('tbl_booking')
          .update({
            'booking_status': 3, // Update booking status to returned
            'return_date': nowString,
            'booking_totalprice': finalPrice
          })
          .eq('booking_id', bookingId);
      print('Updated booking with return date, status 3, and total price $finalPrice');
      print('Supabase update response: $updateResponse');

      // Verify the update was successful by fetching the booking again
      final verifyBooking = await Supabase.instance.client
          .from('tbl_booking')
          .select('booking_totalprice, booking_status, return_date')
          .eq('booking_id', bookingId)
          .single();
      print('Verification - Updated booking data: $verifyBooking');
      print('Verification - Updated booking price: ${verifyBooking['booking_totalprice']} (type: ${verifyBooking['booking_totalprice'].runtimeType})');

      // Close loading dialog
      Navigator.pop(context);

      // Show success message with refund information if applicable
      String message = 'Product returned successfully';
      double originalAmount = currentTotalPrice.toDouble();
      if (updatedAmount < originalAmount) {
        double refundAmount = originalAmount - updatedAmount;
        message += '. Refund amount: ₹${refundAmount.toStringAsFixed(2)}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 5),
        ),
      );

      // Refresh bookings list
      await fetchBookings();
    } catch (e) {
      // Close loading dialog if open
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
      
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error returning product: $e'),
          backgroundColor: Colors.red,
        ),
      );
      print('Error returning product: $e');
    }
  }

  // Helper method to get a formatted booking price
  String getFormattedPrice(dynamic price) {
    // Handle null case
    if (price == null) {
      print('Price is NULL');
      return "₹0";
    }
    
    // Print debugging info
    print('Original price: $price (${price.runtimeType})');
    
    // Handle different types
    if (price is int) {
      return "₹$price";
    } else if (price is double) {
      return "₹${price.toStringAsFixed(0)}";
    } else if (price is String) {
      // Try to parse as double first
      try {
        double numPrice = double.parse(price);
        return "₹${numPrice.toStringAsFixed(0)}";
      } catch (e) {
        print('Could not parse price string: $e');
        return "₹$price";
      }
    } else {
      // For any other type, convert to string
      return "₹$price";
    }
  }

  // Helper method to get image URLs from the shop bucket
  String getImageUrl(String path) {
    if (path == null || path.isEmpty) return '';
    
    final storageUrl = Supabase.instance.client.storage.from('shop').getPublicUrl(path);
    print('Generated image URL from shop bucket: $storageUrl for path: $path');
    return storageUrl;
  }

  String _formatDate(String? date) {
    if (date == null) return 'N/A';
    try {
      final parsedDate = DateTime.parse(date);
      return DateFormat('MMM dd, yyyy').format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  // Helper methods for status badges
  Color _getStatusBadgeColor(int status) {
    switch (status) {
      case 5:
        return Colors.green.shade50;
      case 6:
        return Colors.orange.shade50;
      case 7:
        return Colors.blue.shade50;
      default:
        return Colors.grey.shade50;
    }
  }

  Color _getStatusBorderColor(int status) {
    switch (status) {
      case 5:
        return Colors.green.shade200;
      case 6:
        return Colors.orange.shade200;
      case 7:
        return Colors.blue.shade200;
      default:
        return Colors.grey.shade200;
    }
  }

  Color _getStatusTextColor(int status) {
    switch (status) {
      case 5:
        return Colors.green.shade700;
      case 6:
        return Colors.orange.shade700;
      case 7:
        return Colors.blue.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getStatusText(int status) {
    switch (status) {
      case 5:
        return "Returned";
      case 6:
        return "Processed";
      case 7:
        return "Completed";
      default:
        return "Status $status";
    }
  }

  // Calculate total price based on booking data 
  int calculateTotalPrice(Map<String, dynamic> booking) {
    // First check if there's a direct field
    if (booking['booking_totalprice'] != null) {
      try {
        if (booking['booking_totalprice'] is int) {
          return booking['booking_totalprice'];
        } else if (booking['booking_totalprice'] is double) {
          return booking['booking_totalprice'].round();
        } else if (booking['booking_totalprice'] is String) {
          return int.parse(booking['booking_totalprice']);
        }
      } catch (e) {
        print('Error parsing booking_totalprice: $e');
      }
    }
    
    // Try to calculate from cart items if available
    if (booking['tbl_cart'] != null && booking['tbl_cart'] is List && booking['tbl_cart'].isNotEmpty) {
      try {
        int total = 0;
        for (var item in booking['tbl_cart']) {
          int quantity = 1;
          int price = 0;
          
          // Get quantity
          if (item['cart_qty'] != null) {
            quantity = int.parse(item['cart_qty'].toString());
          }
          
          // Get price
          if (item['item_price'] != null) {
            price = int.parse(item['item_price'].toString());
          } else if (item['tbl_item'] != null) {
            var product = item['tbl_item'];
            if (product['item_rentprice'] != null) {
              price = int.parse(product['item_rentprice'].toString());
            }
          }
          
          total += quantity * price;
        }
        return total;
      } catch (e) {
        print('Error calculating total from cart items: $e');
      }
    }
    
    // Default fallback
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    // Debug: Log all booking total prices at build time
    for (var booking in bookings) {
      print('RENDER BOOKING ${booking['booking_id']}:');
      print('  - booking_totalprice: ${booking['booking_totalprice']}');
      print('  - All booking keys: ${booking.keys.toList()}');
    }
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "My Bookings",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.blueAccent,
              ),
            )
          : bookings.isEmpty
              ? _buildEmptyBookings()
              : RefreshIndicator(
                  onRefresh: fetchBookings,
                  color: Colors.blueAccent,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      var booking = bookings[index];
                      // Debug: Print this booking's price
                      print('Building booking ${booking['booking_id']} with price: ${booking['booking_totalprice']}');
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Booking Header
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withOpacity(0.1),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  topRight: Radius.circular(16),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Booking #${booking['booking_id']}",
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
                                    ),
                                  ),
                                  Text(
                                    _formatDate(booking['booking_date']),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Items List
                            ListView.separated(
                              padding: const EdgeInsets.all(16),
                              separatorBuilder: (context, index) => const Divider(height: 24),
                              itemCount: booking['tbl_cart'].length,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                var cartItem = booking['tbl_cart'][index];
                                return Row(
                                  children: [
                                    // Add item image display
                                    if (cartItem['tbl_item'] != null && 
                                       cartItem['tbl_item']['item_image'] != null &&
                                       cartItem['tbl_item']['item_image'].toString().isNotEmpty)
                                    Container(
                                      width: 60,
                                      height: 60,
                                      margin: const EdgeInsets.only(right: 12),
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey.shade200),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          getImageUrl(cartItem['tbl_item']['item_image']),
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading image: $error');
                                            return Icon(Icons.image_not_supported, color: Colors.grey);
                                          },
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            cartItem['tbl_item']['item_name'],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "Quantity: ${cartItem['cart_qty']}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          // Add price display
                                          Text(
                                            "Unit Price: ${getFormattedPrice(cartItem['tbl_item']['item_rentprice'])}",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                          // Show status badge if item has special status
                                          if (cartItem['cart_status'] > 4)
                                            Container(
                                              margin: EdgeInsets.only(top: 4),
                                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: _getStatusBadgeColor(cartItem['cart_status']),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: _getStatusBorderColor(cartItem['cart_status'])),
                                              ),
                                              child: Text(
                                                _getStatusText(cartItem['cart_status']),
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: _getStatusTextColor(cartItem['cart_status']),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    // Action buttons
                                    cartItem['cart_status'] > 4
                                    ? // Already returned or other final status - show nothing
                                      Container()
                                    : // Active item - show action buttons  
                                      Row(
                                        children: [
                                          ElevatedButton(
                                            onPressed: () => _returnProduct(booking['booking_id'], cartItem['tbl_item']['item_id']),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              "Return",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ElevatedButton(
                                            onPressed: () => _submitComplaint(cartItem['tbl_item']['item_id']),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.redAccent,
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 8,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                            ),
                                            child: const Text(
                                              "Complaint",
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                  ],
                                );
                              },
                            ),
                            // Booking Summary
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: const BorderRadius.only(
                                  bottomLeft: Radius.circular(16),
                                  bottomRight: Radius.circular(16),
                                ),
                              ),
                              child: Builder(
                                builder: (context) {
                                  print('Building summary for booking ${booking['booking_id']}');
                                  print('Available fields: ${booking.keys.toList().join(', ')}');
                                  
                                  // Check if booking_totalprice is available
                                  final hasTotalPrice = booking.containsKey('booking_totalprice');
                                  print('Has booking_totalprice field: $hasTotalPrice');
                                  
                                  // Alternative field names to check
                                  final possiblePriceFields = [
                                    'booking_totalprice', 
                                    'bookingTotalPrice', 
                                    'total_price', 
                                    'totalPrice', 
                                    'price',
                                    'amount',
                                    'total_amount',
                                    'totalAmount'
                                  ];
                                  
                                  // Look for any price field
                                  dynamic price = 0;
                                  for (var field in possiblePriceFields) {
                                    if (booking.containsKey(field) && booking[field] != null) {
                                      price = booking[field];
                                      print('Found price in field "$field": $price');
                                      break;
                                    }
                                  }
                                  
                                  // If we didn't find a price, try calculating it from cart items
                                  if (price == 0 && booking['tbl_cart'] != null && booking['tbl_cart'].isNotEmpty) {
                                    print('No price field found, attempting to calculate from cart items');
                                    try {
                                      int calculatedTotal = 0;
                                      for (var item in booking['tbl_cart']) {
                                        int quantity = item['cart_qty'] ?? 1;
                                        int itemPrice = 0;
                                        if (item['item_price'] != null) {
                                          itemPrice = int.parse(item['item_price'].toString());
                                        } else if (item['tbl_item'] != null && item['tbl_item']['item_rentprice'] != null) {
                                          itemPrice = int.parse(item['tbl_item']['item_rentprice'].toString());
                                        }
                                        calculatedTotal += quantity * itemPrice;
                                      }
                                      
                                      if (calculatedTotal > 0) {
                                        price = calculatedTotal;
                                        print('Calculated price from cart items: $price');
                                      }
                                    } catch (e) {
                                      print('Error calculating price from cart items: $e');
                                    }
                                  }
                                  
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Total Price",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            "₹$price",
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blueAccent,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            "Return Date",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          Text(
                                            _formatDate(booking['return_date']),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  );
                                }
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
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
