import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  _ChangePasswordPageState createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> updatePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('New passwords do not match!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw "User not found!";
      }

      // Re-authenticate user using the current password
      final response = await supabase.auth.signInWithPassword(
        email: currentUser.email!,
        password: _currentPasswordController.text,
      );

      if (response.user == null) {
        throw "Incorrect current password!";
      }

      // If password is correct, update the password in Supabase auth
      await supabase.auth.updateUser(
        UserAttributes(password: _newPasswordController.text),
      );

      // Update the password in your custom 'tbl_user' table
      await supabase.from('tbl_user').update({
        'password': _newPasswordController.text, // Replace with the correct column name
      }).eq('user_id', currentUser.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password updated successfully!')),
      );

      // Navigate back to UserProfileSetting page after successful update
      Navigator.pop(context);
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Current Password', prefixIcon: Icon(Icons.lock)),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'New Password', prefixIcon: Icon(Icons.lock_outline)),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Confirm New Password', prefixIcon: Icon(Icons.lock_reset)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : updatePassword,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Update Password', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
