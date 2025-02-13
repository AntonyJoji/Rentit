import 'package:flutter/material.dart';
import 'package:user/screen/ChangePassword.dart';
import 'package:user/screen/editProfile.dart';

class UserProfileSetting extends StatelessWidget {
  const UserProfileSetting({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey.shade300,
              child: Icon(Icons.person, size: 60, color: Colors.grey.shade700),
            ),
            SizedBox(height: 20),
            Text('Name: John Doe', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Email: johndoe@example.com', style: TextStyle(fontSize: 18)),
            SizedBox(height: 10),
            Text('Phone: +1 234 567 890', style: TextStyle(fontSize: 18)),
            Divider(height: 40, thickness: 2),
            Center(
              child: Column(
                children: [
                  ElevatedButton(
                    onPressed: () {
                       Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage (), // Fixed constructor reference
                              ),
                            );
                    },
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                    child: Text('Edit Profile', style: TextStyle(fontSize: 16)),
                  ),
                  SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ChangePasswordPage (), // Fixed constructor reference
                              ),
                            );
                    },
                    
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12)),
                    child: Text('Change Password', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
