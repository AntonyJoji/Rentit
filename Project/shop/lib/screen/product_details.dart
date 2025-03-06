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
  int stockQuantity = 0;

  @override
  void initState() {
    super.initState();
    fetchStock();
  }

  Future<void> fetchStock() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('tbl_stock')
        .select('stock_quantity')
        .eq('item_id', widget.product['item_id'])
        .maybeSingle();

    if (response != null) {
      setState(() {
        stockQuantity = response['stock_quantity'] ?? 0;
      });
    }
  }


 Future<void> addStock() async {
  try {
    int itemId = widget.product['item_id'];
    int newStock = int.tryParse(stockController.text) ?? 0;

    final supabase = Supabase.instance.client;
    
    // Check if stock entry exists
    final existingStock = await supabase
        .from('tbl_stock')
        .select('stock_quantity')
        .eq('item_id', itemId)
        .maybeSingle();

    if (existingStock != null) {
      // If stock exists, update it
      await supabase
          .from('tbl_stock')
          .update({
            'stock_quantity': existingStock['stock_quantity'] + newStock,
            'stock_date': DateTime.now().toIso8601String(),
          })
          .eq('item_id', itemId);
      
      setState(() {
        stockQuantity += newStock;
      });
      print("Stock updated for item ID: $itemId");
    } else {
      // If stock does not exist, insert a new record
      await supabase
          .from('tbl_stock')
          .insert({
            'item_id': itemId,
            'stock_quantity': newStock,
            'stock_date': DateTime.now().toIso8601String(),
          });

      setState(() {
        stockQuantity = newStock;
      });
      print("New stock entry created for item ID: $itemId");
    }
  } catch (e) {
    print("Error adding stock: $e");
  }
}


  void showStock() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product['item_name']),
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
                    widget.product['item_photo'] ?? 'https://via.placeholder.com/150',
                    height: 200,
                    width: 300,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(child: Icon(Icons.broken_image, size: 50));
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
              widget.product['item_details'] ?? 'No details available.',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              "Stock: $stockQuantity",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: showStock,
        tooltip: 'Add Stock',
        child: const Icon(Icons.add),
      ),
    );
  }
}
