import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/main.dart';

class ComplaintPage extends StatefulWidget {
  final int bookingId;
  const ComplaintPage({super.key, required this.bookingId});

  @override
  State<ComplaintPage> createState() => _ComplaintPageState();
}

class _ComplaintPageState extends State<ComplaintPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  Future<void> _submitComplaint() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields.")),
      );
      return;
    }

    try {
      await submitComplaint(
        complaintTitle: title,
        complaintContent: content,
        bookingId: widget.bookingId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint submitted successfully.")),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Submit Complaint"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Complaint Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(
                labelText: "Complaint Content",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submitComplaint,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
              child: const Text("Submit Complaint"),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> submitComplaint({
  required String complaintTitle,
  required String complaintContent,
  required int bookingId,
}) async {

  try {
    // Insert the complaint into `tbl_complaint`
    await supabase.from('tbl_complaint').insert({
      'complaint_title': complaintTitle,
      'complaint_content': complaintContent,
      'item_id': bookingId,
      'complaint_status': 0, // Set initial status as pending
    });

    print('Complaint submitted successfully.');
  } catch (error) {
    print('Error submitting complaint: $error');
  }
}
