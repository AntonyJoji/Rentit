import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ProductDetails extends StatefulWidget {
  final Map<String, dynamic> product;
  const ProductDetails({super.key, required this.product});

  @override
  State<ProductDetails> createState() => _ProductDetailsState();
}

class _ProductDetailsState extends State<ProductDetails> {
  final TextEditingController stockController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController detailsController = TextEditingController();
  List<Map<String, dynamic>> stockHistory = [];
  int totalStock = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchStockHistory();
    priceController.text = (widget.product['item_rentprice'] ?? '0.00').toString();
    detailsController.text = widget.product['item_details'] ?? 'No details available';
  }

  Future<void> fetchStockHistory() async {
    try {
      final supabase = Supabase.instance.client;

      final response = await supabase
          .from('tbl_stock')
          .select('stock_quantity, stock_date')
          .eq('item_id', widget.product['item_id'])
          .order('stock_date', ascending: false);

      List<Map<String, dynamic>> fetchedStock = List<Map<String, dynamic>>.from(response);
      int calculatedTotalStock = fetchedStock.fold(0, (sum, stock) => sum + (stock['stock_quantity'] as int));

      setState(() {
        stockHistory = fetchedStock;
        totalStock = calculatedTotalStock;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching stock history: $e')),
        );
      }
    }
  }

  Future<void> addStock() async {
    try {
      if (stockController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid quantity')),
        );
        return;
      }

      int itemId = widget.product['item_id'];
      int newStock = int.tryParse(stockController.text) ?? 0;
      String stockDate = DateTime.now().toIso8601String();

      final supabase = Supabase.instance.client;

      await supabase.from('tbl_stock').insert({
        'item_id': itemId,
        'stock_quantity': newStock,
        'stock_date': stockDate,
      });

      stockController.clear();
      fetchStockHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding stock: $e')),
        );
      }
    }
  }

  Future<void> updateProduct() async {
    try {
      if (priceController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid price')),
        );
        return;
      }

      final supabase = Supabase.instance.client;

      await supabase.from('tbl_item').update({
        'item_rentprice': double.parse(priceController.text),
        'item_detail': detailsController.text,
      }).eq('item_id', widget.product['item_id']);

      final updatedProduct = await supabase
          .from('tbl_item')
          .select()
          .eq('item_id', widget.product['item_id'])
          .single();

      setState(() {
        widget.product['item_rentprice'] = updatedProduct['item_rentprice'];
        widget.product['item_detail'] = updatedProduct['item_detail'];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating product: $e')),
        );
      }
    }
  }

  void showStockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.add_box_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Add Stock'),
            ],
          ),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: "Enter stock quantity",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.inventory),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Add'),
              onPressed: () {
                addStock();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void showEditDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: const [
              Icon(Icons.edit_outlined, color: Colors.blue),
              SizedBox(width: 8),
              Text('Edit Product'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: "Enter rent price",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.currency_rupee),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: detailsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Enter details",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () {
                updateProduct();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['item_name']),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditDialog,
            tooltip: 'Edit Product',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Hero Image Section with constrained width
                  Center(
                    child: Container(
                      height: 200, // Reduced from 300
                      width: 200,  // Fixed width
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.all(16),
                      child: Hero(
                        tag: 'product-${widget.product['item_id']}',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            widget.product['item_photo'] ?? 'https://via.placeholder.com/200',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Product Details Section with constrained width
                  Container(
                    constraints: const BoxConstraints(maxWidth: 600),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                widget.product['item_name'] ?? 'No Name',
                                style: const TextStyle(
                                  fontSize: 20, // Reduced from 24
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                              decoration: BoxDecoration(
                                color: Colors.blue[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                "₹${widget.product['item_rentprice'] ?? '0.00'}/day",
                                style: TextStyle(
                                  fontSize: 14, // Reduced from 18
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12), // Reduced from 16

                        // Stock Information
                        Card(
                          elevation: 1, // Reduced elevation
                          child: Padding(
                            padding: const EdgeInsets.all(12), // Reduced from 16
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      "Current Stock",
                                      style: TextStyle(
                                        fontSize: 16, // Reduced from 18
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Reduced padding
                                      decoration: BoxDecoration(
                                        color: totalStock > 0 ? Colors.green[100] : Colors.red[100],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        "$totalStock units",
                                        style: TextStyle(
                                          fontSize: 14, // Reduced from 16
                                          fontWeight: FontWeight.bold,
                                          color: totalStock > 0 ? Colors.green[900] : Colors.red[900],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Reduced from 16

                        // Product Description
                        Card(
                          elevation: 1, // Reduced elevation
                          child: Padding(
                            padding: const EdgeInsets.all(12), // Reduced from 16
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Description",
                                  style: TextStyle(
                                    fontSize: 16, // Reduced from 18
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6), // Reduced from 8
                                Text(
                                  widget.product['item_detail'] ?? 'No details available.',
                                  style: TextStyle(
                                    fontSize: 14, // Reduced from 16
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12), // Reduced from 16

                        // Stock History
                        Card(
                          elevation: 1, // Reduced elevation
                          child: Padding(
                            padding: const EdgeInsets.all(12), // Reduced from 16
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "Stock History",
                                  style: TextStyle(
                                    fontSize: 16, // Reduced from 18
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6), // Reduced from 8
                                if (stockHistory.isEmpty)
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(12), // Reduced from 16
                                      child: Text(
                                        "No stock history available",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: stockHistory.length,
                                    itemBuilder: (context, index) {
                                      final stock = stockHistory[index];
                                      return ListTile(
                                        dense: true, // Makes the ListTile more compact
                                        leading: Container(
                                          padding: const EdgeInsets.all(6), // Reduced from 8
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Icon(Icons.inventory, 
                                            color: Colors.blue,
                                            size: 18, // Reduced from default size
                                          ),
                                        ),
                                        title: Text(
                                          "+${stock['stock_quantity']} units",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w500,
                                            fontSize: 14, // Added smaller font size
                                          ),
                                        ),
                                        subtitle: Text(
                                          DateFormat('MMM dd, yyyy HH:mm').format(
                                            DateTime.parse(stock['stock_date']).toLocal(),
                                          ),
                                          style: const TextStyle(fontSize: 12), // Added smaller font size
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showStockDialog,
        label: const Text('Add Stock'),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }
}