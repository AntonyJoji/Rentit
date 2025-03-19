import 'package:flutter/material.dart';
import 'package:rentit_admin1/component/appbar.dart';
import 'package:rentit_admin1/component/sidebar.dart';
import 'package:rentit_admin1/screen/dashboard.dart';
import 'package:rentit_admin1/screen/manageDeliveryBoy.dart';
import 'package:rentit_admin1/screen/managecategory.dart';
import 'package:rentit_admin1/screen/managedistrict.dart';
import 'package:rentit_admin1/screen/manageshop.dart';
import 'package:rentit_admin1/screen/complaint.dart';
import 'package:rentit_admin1/screen/manageplace.dart';
import 'package:rentit_admin1/screen/managesubcategory.dart';



class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    AdminDashboard(),
   Manageplace(),
   ComplaintPage(),
   Manageshop(),
   Managedistrict(),
   category(),
   subCategory(),
   deliveryboy(),
    const Center(child: Text('Settings Content')),
  ];

  void onSidebarItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Color(0xFFFFFFFF),
        body: Row(
          children: [
            Expanded(
                flex: 1,
                child: SideBar(
                  onItemSelected: onSidebarItemTapped,
                )),
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Appbar1(),
                  _pages[_selectedIndex],
                ],
              ),
            )
          ],
        ));
  }
}