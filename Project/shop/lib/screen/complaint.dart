import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'complaint_details_page.dart'; // Import the new page

class ComplaintPage extends StatefulWidget {
  const ComplaintPage({super.key});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  List<dynamic> complaints = [];

  @override
  void initState() {
    super.initState();
    fetchComplaints();
  }

  Future<void> fetchComplaints() async {
    try {
      final response = await Supabase.instance.client.from('tbl_complaint').select(
          'complaint_id, complaint_title, complaint_status, tbl_item!inner(item_name)');

      setState(() {
        complaints = response;
      });
    } catch (error) {
      print('Error fetching complaints: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: complaints.length,
            itemBuilder: (context, index) {
              final complaint = complaints[index];
              final itemName =
                  complaint['tbl_item']['item_name'] ?? 'No Item Name';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text(itemName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(complaint['complaint_title'] ?? 'No Title'),
                      const SizedBox(height: 5),
                      Text(
                          'Status: ${complaint['complaint_status'] ?? 'Unknown'}'),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailsPage(
                            itemName: itemName,
                            complaintTitle:
                                complaint['complaint_title'] ?? 'No Title',
                            complaintStatus: int.tryParse(
                                    complaint['complaint_status'].toString()) ??
                                0,
                            complaintId: int.tryParse(
                                    complaint['complaint_id'].toString()) ??
                                0, // Ensure ID is converted
                          ),
                        ),
                      );
                    },
                    child: const Text('Reply'),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
