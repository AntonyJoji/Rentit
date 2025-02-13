import 'package:flutter/material.dart';

class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email)),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone)),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Save Changes', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
