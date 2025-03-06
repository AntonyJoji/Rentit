import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  @override
  void initState() {
    super.initState();
    fetchStockHistory();
    priceController.text =
        (widget.product['item_rentprice'] ?? '0.00').toString();
    detailsController.text =
        widget.product['item_details'] ?? 'No details available';
  }

  Future<void> fetchStockHistory() async {
    final supabase = Supabase.instance.client;

    final response = await supabase
        .from('tbl_stock')
        .select('stock_quantity, stock_date')
        .eq('item_id', widget.product['item_id'])
        .order('stock_date', ascending: false);

    List<Map<String, dynamic>> fetchedStock =
        List<Map<String, dynamic>>.from(response);
    int calculatedTotalStock = fetchedStock.fold(
        0, (sum, stock) => sum + (stock['stock_quantity'] as int));

    setState(() {
      stockHistory = fetchedStock;
      totalStock = calculatedTotalStock;
    });
  }

  Future<void> addStock() async {
    try {
      int itemId = widget.product['item_id'];
      int newStock = int.tryParse(stockController.text) ?? 0;
      String stockDate = DateTime.now().toIso8601String();

      final supabase = Supabase.instance.client;

      await supabase.from('tbl_stock').insert({
        'item_id': itemId,
        'stock_quantity': newStock,
        'stock_date': stockDate,
      });

      fetchStockHistory();
    } catch (e) {
      print("Error adding stock: $e");
    }
  }

  Future<void> updateProduct() async {
    try {
      final supabase = Supabase.instance.client;

      // Update product detail
      await supabase.from('tbl_item').update({
        'item_rentprice': double.parse(priceController.text),
        'item_detail': detailsController.text, // Ensure this column exists
      }).eq('item_id', widget.product['item_id']);

      // Fetch the updated product data
      final updatedProduct = await supabase
          .from('tbl_item')
          .select()
          .eq('item_id', widget.product['item_id'])
          .single();

      setState(() {
        widget.product['item_rentprice'] = updatedProduct['item_rentprice'];
        widget.product['item_detail'] = updatedProduct['item_detail'];
      });
    } catch (e) {
      print("Error updating product: $e");
    }
  }

  void showStockDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Stock'),
          content: TextField(
            controller: stockController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: "Enter stock quantity"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
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
          title: const Text('Edit Product'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: "Enter rent price"),
              ),
              TextField(
                controller: detailsController,
                decoration: const InputDecoration(hintText: "Enter details"),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: showEditDialog,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.product['item_photo'] ??
                        'https://via.placeholder.com/150',
                    height: 200,
                    width: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Icon(Icons.broken_image, size: 50));
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.product['item_name'] ?? 'No Name',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Rent Price: \$${widget.product['item_rentprice'] ?? '0.00'}",
              style: const TextStyle(fontSize: 18, color: Colors.green),
            ),
            const SizedBox(height: 8),
            Text(
              widget.product['item_detail'] ?? 'No details available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              "Total Stock: $totalStock",
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue),
            ),
            const SizedBox(height: 16),
            const Text(
              "Stock History:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            stockHistory.isEmpty
                ? const Text("No stock history available.")
                : Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: stockHistory.length,
                      itemBuilder: (context, index) {
                        final stock = stockHistory[index];
                        return ListTile(
                          leading:
                              const Icon(Icons.history, color: Colors.blue),
                          title: Text("Added: ${stock['stock_quantity']}"),
                          subtitle: Text(
                            "Date: ${DateTime.parse(stock['stock_date']).toLocal()}",
                          ),
                        );
                      },
                    ),
                  ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: showStockDialog,
        label: const Text('Add Stock'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
