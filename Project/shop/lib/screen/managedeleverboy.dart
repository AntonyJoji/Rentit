import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'deleveryboy.dart';

class managedeleverboy extends StatefulWidget {
  const managedeleverboy({super.key});

  @override
  State<managedeleverboy> createState() => _managedeleverboyState();
}

class _managedeleverboyState extends State<managedeleverboy> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> deliveryBoys = [];
  bool isLoading = true;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchDeliveryBoys();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contactController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> fetchDeliveryBoys() async {
    try {
      final shopId = supabase.auth.currentUser?.id;
      if (shopId == null) return;

      final response = await supabase
          .from('tbl_deliveryboy')
          .select()
          .eq('shop_id', shopId);

      setState(() {
        deliveryBoys = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching delivery boys: $e');
      setState(() => isLoading = false);
    }
  }

  Future<bool> hasAssociatedOrders(String boyId) async {
    try {
      final response = await supabase
          .from('tbl_cart')
          .select('cart_id')
          .eq('boy_id', boyId)
          .limit(1);
      
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking associated orders: $e');
      return true;
    }
  }

  Future<void> toggleDeliveryBoyStatus(Map<String, dynamic> boy) async {
    try {
      final currentStatus = boy['boy_status'] ?? 1; // Default to active (1) if status is null
      final newStatus = currentStatus == 1 ? 2 : 1; // Toggle between 1 (active) and 2 (inactive)
      
      final title = newStatus == 1 ? 'Activate Account' : 'Deactivate Account';
      final message = newStatus == 1
          ? 'Are you sure you want to activate this delivery boy\'s account?'
          : 'Are you sure you want to deactivate this delivery boy\'s account?';
      
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(
                foregroundColor: newStatus == 1 ? Colors.green : Colors.red,
              ),
              child: Text(newStatus == 1 ? 'Activate' : 'Deactivate'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      // Update the status in the database
      await supabase
          .from('tbl_deliveryboy')
          .update({'boy_status': newStatus})
          .eq('boy_id', boy['boy_id']);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus == 1
                  ? 'Delivery boy account activated successfully'
                  : 'Delivery boy account deactivated successfully'
            ),
            backgroundColor: newStatus == 1 ? Colors.green : Colors.orange,
          ),
        );
      }

      // Refresh the list
      await fetchDeliveryBoys();
    } catch (e) {
      print('Error toggling delivery boy status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating delivery boy status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> deleteDeliveryBoy(String boyId) async {
    try {
      // Check for associated orders
      bool hasOrders = await hasAssociatedOrders(boyId);
      
      if (hasOrders) {
        if (!mounted) return;
        
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cannot Delete'),
            content: const Text(
              'This delivery boy has associated orders and cannot be deleted. '
              'Please use the deactivate option from the menu instead.'
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // If no orders, show confirmation dialog
      bool confirm = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Confirm Delete'),
          content: const Text('Are you sure you want to delete this delivery boy?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        ),
      ) ?? false;

      if (!confirm) return;

      // Delete from database
      await supabase
          .from('tbl_deliveryboy')
          .delete()
          .eq('boy_id', boyId);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery boy deleted successfully')),
        );
      }

      // Refresh the list
      await fetchDeliveryBoys();
    } catch (e) {
      print('Error deleting delivery boy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot delete delivery boy with associated orders'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> editDeliveryBoy(Map<String, dynamic> boy) async {
    // Set initial values
    _nameController.text = boy['boy_name'] ?? '';
    _contactController.text = boy['boy_contact'] ?? '';
    _emailController.text = boy['boy_email'] ?? '';
    _addressController.text = boy['boy_address'] ?? '';

    // Show edit dialog
    bool? result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Delivery Boy'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _contactController,
                decoration: const InputDecoration(labelText: 'Contact'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                enabled: false, // Email cannot be edited
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != true) return;

    try {
      // Update in database
      await supabase
          .from('tbl_deliveryboy')
          .update({
            'boy_name': _nameController.text,
            'boy_contact': _contactController.text,
            'boy_address': _addressController.text,
          })
          .eq('boy_id', boy['boy_id']);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delivery boy updated successfully')),
        );
      }

      // Refresh the list
      await fetchDeliveryBoys();
    } catch (e) {
      print('Error updating delivery boy: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating delivery boy: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (deliveryBoys.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No delivery boys found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add delivery boys to manage deliveries',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: deliveryBoys.length,
        itemBuilder: (context, index) {
          final boy = deliveryBoys[index];
          final isActive = (boy['boy_status'] ?? 1) == 1; // Check if status is 1 (active)

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Stack(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey[200],
                    backgroundImage: boy['boy_photo'] != null
                        ? NetworkImage(boy['boy_photo'])
                        : null,
                    child: boy['boy_photo'] == null
                        ? Icon(Icons.person, color: Colors.grey[400])
                        : null,
                  ),
                  if (!isActive)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.block,
                          color: Colors.white,
                          size: 12,
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      boy['boy_name'] ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green[100] : Colors.red[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: isActive ? Colors.green[700] : Colors.red[700],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    boy['boy_contact'] ?? 'No contact',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    boy['boy_email'] ?? 'No email',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      editDeliveryBoy(boy);
                      break;
                    case 'toggle_status':
                      toggleDeliveryBoyStatus(boy);
                      break;
                    case 'delete':
                      deleteDeliveryBoy(boy['boy_id']);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Edit Details'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_status',
                    child: Row(
                      children: [
                        Icon(
                          isActive ? Icons.block : Icons.check_circle,
                          color: isActive ? Colors.red : Colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isActive ? 'Deactivate' : 'Activate',
                          style: TextStyle(
                            color: isActive ? Colors.red : Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}