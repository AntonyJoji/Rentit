import 'package:flutter/material.dart';
import 'package:user/screen/userProfileSetting.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.person),
            title: Text('Profile'),
            onTap: () {
              Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileSetting (), // Fixed constructor reference
                              ),
                            );
            },
          ),
          
          ListTile(
            leading: Icon(Icons.info),
            title: Text('About App'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
