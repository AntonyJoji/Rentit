import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/ChangePassword.dart';
import 'package:user/screen/editProfile.dart';

class UserProfileSetting extends StatefulWidget {
  const UserProfileSetting({super.key});

  @override
  _UserProfileSettingState createState() => _UserProfileSettingState();
}

class _UserProfileSettingState extends State<UserProfileSetting> {
  final supabase = Supabase.instance.client;
  String name = "Loading...";
  String email = "Loading...";
  String phone = "Loading...";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        setState(() {
          name = "User not found";
          email = "N/A";
          phone = "N/A";
          isLoading = false;
        });
        return;
      }

      final response = await supabase
          .from('tbl_user') // Updated table name
          .select('user_name, user_email, user_contact')
          .eq('user_id', user.id) // Updated user ID column name
          .maybeSingle(); // Prevents error if no record is found

      if (response == null) {
        setState(() {
          name = "User not found";
          email = "N/A";
          phone = "N/A";
          isLoading = false;
        });
        return;
      }

      setState(() {
        name = response['user_name'] ?? "No Name";
        email = response['user_email'] ?? "No Email";
        phone = response['user_contact'] ?? "No Phone";
        isLoading = false;
      });
    } catch (error) {
      setState(() {
        name = "Error fetching data";
        email = "Error";
        phone = "Error";
        isLoading = false;
      });
      print("Error fetching user data: $error");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('User Profile',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey.shade300,
                    child: Icon(Icons.person,
                        size: 60, color: Colors.grey.shade700),
                  ),
                  SizedBox(height: 20),
                  Text('Name: $name', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  Text('Email: $email', style: TextStyle(fontSize: 18)),
                  SizedBox(height: 10),
                  Text('Phone: $phone', style: TextStyle(fontSize: 18)),
                  Divider(height: 40, thickness: 2),
                  Center(
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfilePage(),
                              ),
                            );
                            if (result == true) {
                              fetchUserData(); // Refresh profile data after returning
                            }
                          },
                          child: Text('Edit Profile'),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ChangePasswordPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 12)),
                          child: Text('Change Password',
                              style: TextStyle(fontSize: 16)),
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
