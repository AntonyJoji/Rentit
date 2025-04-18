import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop/screen/login.dart';

class SideBar extends StatefulWidget {
  final Function(int) onItemSelected;
  const SideBar({super.key, required this.onItemSelected});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final List<String> pages = [
    "Dashboard",
    "Manage Booking",
    "ADD Product",
    "Manage Product",
    "Complaints",
    "deleveryboy",
    "ShopRentedItemsPage"
  ];
  final List<IconData> icons = [
    Icons.map,
    Icons.fact_check,
    Icons.storefront,
    Icons.production_quantity_limits,
    Icons.report,
    Icons.local_shipping,
    Icons.local_shipping
  ];

  Future<void> logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ShopLogin()),
      (route) => false,
    );
  }

 @override
Widget build(BuildContext context) {
  return Container(
    width: 250,
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        colors: [Color(0xFF4092D6), Color(0xFF3A6EA5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Text(
                "Dashboard",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: Icon(icons[index], color: Colors.white),
                  title: Text(
                    pages[index],
                    style: const TextStyle(color: Colors.white),
                  ),
                  hoverColor: Colors.white12, // for web
                  onTap: () {
                    widget.onItemSelected(index);
                  },
                );
              },
            ),
          ],
        ),
        const Divider(color: Colors.white24, thickness: 1),
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
          leading: const Icon(Icons.logout_outlined, color: Colors.white),
          title: const Text(
            "Logout",
            style: TextStyle(color: Colors.white),
          ),
          onTap: () => logout(context),
        ),
        const SizedBox(height: 20),
      ],
    ),
  );
}
}