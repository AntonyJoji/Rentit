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
              final itemName = complaint['tbl_item']['item_name'] ?? 'No Item Name';
              final complaintTitle = complaint['complaint_title'] ?? 'No Title';
              final complaintStatus = complaint['complaint_status'] != null
                  ? int.tryParse(complaint['complaint_status'].toString()) ?? 0
                  : 0; // Ensuring complaint_status is treated as an integer

              // Skip complaints with status 1 (Replied)
              if (complaintStatus == 1) {
                return SizedBox.shrink(); // Return an empty widget for replied complaints
              }

              return Card(
                elevation: 5,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Icon(
                    Icons.report_problem,
                    color: Colors.orangeAccent,
                    size: 30,
                  ),
                  title: Text(
                    itemName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaintTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Status: Pending',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.orangeAccent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ComplaintDetailsPage(
                            itemName: itemName,
                            complaintTitle: complaintTitle,
                            complaintStatus: complaintStatus,
                            complaintId: int.tryParse(complaint['complaint_id'].toString()) ?? 0,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    ),
                    child: const Text(
                      'Reply',
                      style: TextStyle(fontSize: 14),
                    ),
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
