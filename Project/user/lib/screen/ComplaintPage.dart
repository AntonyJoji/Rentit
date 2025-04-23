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
  bool isLoading = false;

  Future<void> _submitComplaint() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await submitComplaint(
        complaintTitle: title,
        complaintContent: content,
        bookingId: widget.bookingId,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaint submitted successfully."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString()}"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Submit Complaint",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.redAccent.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Report an Issue",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.redAccent,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Please provide details about your complaint. We'll review it and get back to you soon.",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Complaint Form
              Container(
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
                  children: [
                    _buildTextField(
                      controller: _titleController,
                      label: "Complaint Title",
                      hint: "Enter a brief title for your complaint",
                      icon: Icons.title,
                    ),
                    const Divider(height: 1),
                    _buildTextField(
                      controller: _contentController,
                      label: "Complaint Details",
                      hint: "Describe your complaint in detail",
                      icon: Icons.description,
                      maxLines: 5,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submitComplaint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Submit Complaint",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(
            icon,
            color: Colors.redAccent,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
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
    rethrow;
  }
}