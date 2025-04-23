import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ComplaintDetailsPage extends StatefulWidget {
  final String itemName;
  final String complaintTitle;
  final int? complaintStatus;
  final int complaintId;

  const ComplaintDetailsPage({
    super.key,
    required this.itemName,
    required this.complaintTitle,
    required this.complaintStatus,
    required this.complaintId,
  });

  @override
  State<ComplaintDetailsPage> createState() => _ComplaintDetailsPageState();
}

class _ComplaintDetailsPageState extends State<ComplaintDetailsPage> {
  final TextEditingController _replyController = TextEditingController();
  bool _isLoading = false; // New loading state

  String getStatusText(int? status) {
    if (status == 0) return 'Pending';
    if (status == 1) return 'Replied';
    return 'Unknown';
  }

  Future<void> sendReply() async {
    final replyText = _replyController.text.trim();

    if (replyText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reply')),
      );
      return;
    }

    setState(() => _isLoading = true); // Disable button while submitting

    try {
      await Supabase.instance.client
          .from('tbl_complaint')
          .update({
            'complaint_replay': replyText,
            'complaint_status': 1,
          })
          .eq('complaint_id', widget.complaintId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reply sent successfully')),
        );

        // Clear text field and return to previous screen
        _replyController.clear();
        Navigator.pop(context);
      }
    } catch (error) {
      print('❌ Error sending reply: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false); // Re-enable button after completion
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Complaint Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Item Name: ${widget.itemName}', 
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Complaint Title: ${widget.complaintTitle}', 
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 10),
            Text('Status: ${getStatusText(widget.complaintStatus)}', 
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 20),

            TextField(
              controller: _replyController,
              decoration: const InputDecoration(
                labelText: 'Enter Reply',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: _isLoading ? null : sendReply,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isLoading ? Colors.grey : Colors.blue,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Send Reply'),
            ),
          ],
        ),
      ),
    );
  }
}
