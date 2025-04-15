import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PurchasedItemsPage extends StatefulWidget {
  @override
  _PurchasedItemsPageState createState() => _PurchasedItemsPageState();
}

class _PurchasedItemsPageState extends State<PurchasedItemsPage> {
  late Future<List<dynamic>> purchasedItems;

  // Fetch purchased items along with return dates
  Future<List<dynamic>> fetchPurchasedItems() async {
    try {
      final response = await Supabase.instance.client
          .from('tbl_booking')
          .select('booking_id, start_date, return_date, tbl_item(item_name, item_photo)')
          .eq('booking_status', 4)
          .order('start_date', ascending: false)
          .limit(100);

      return List<Map<String, dynamic>>.from(response); // Cast to List<Map<String, dynamic>>
    } catch (e) {
      debugPrint('Error fetching purchased items: $e');
      return [];
    }
  }

  @override
  void initState() {
    super.initState();
    purchasedItems = fetchPurchasedItems(); // Fetch purchased items
  }

  @override
@override
Widget build(BuildContext context) {
  return FutureBuilder<List<Map<String, dynamic>>>(
    future: purchasedItems,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator());
      } else if (snapshot.hasError) {
        return Center(child: Text('Error: ${snapshot.error}'));
      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(child: Text('No purchased items found.'));
      } else {
        final items = snapshot.data!;
        return SingleChildScrollView(
          child: Column(
            children: items.map((item) {
              final itemName = item['tbl_item']['item_name'];
              final itemPhoto = item['tbl_item']['item_photo'];
              final startDate = item['tbl_booking']['start_date'];
              final returnDate = item['tbl_booking']['return_date'] ?? 'N/A';

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                child: ListTile(
                  leading: itemPhoto != null
                      ? Image.network(itemPhoto, width: 50, height: 50, fit: BoxFit.cover)
                      : Icon(Icons.image_not_supported),
                  title: Text(itemName, style: TextStyle(fontSize: 18)),
                  subtitle: Text('Start: $startDate\nReturn: $returnDate'),
                ),
              );
            }).toList(),
          ),
        );
      }
    },
  );
}
  }
