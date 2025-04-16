import 'package:flutter/material.dart';
import 'package:shop/component/appbar.dart';
import 'package:shop/component/sidebar.dart';
import 'package:shop/screen/complaint.dart';
import 'package:shop/screen/dashboard.dart';
import 'package:shop/screen/deleveryboy.dart';
import 'package:shop/screen/manageBooking.dart';
import 'package:shop/screen/addProduct.dart';
import 'package:shop/screen/manageProduct.dart';
import 'package:shop/screen/ShopRentedItemsPage.dart';





class Shophome extends StatefulWidget {
  const Shophome({super.key});

  @override
  State<Shophome> createState() => _ShopHomeState();
}

class _ShopHomeState extends State<Shophome> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    Dashboard(),
    ManageBookingsPage(),
    addProduct(),
    ManageProductsPage(),
    ComplaintPage(),
    deliregistration(),
    ShopRentedItemsPage(),
  
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
              child: ListView(
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