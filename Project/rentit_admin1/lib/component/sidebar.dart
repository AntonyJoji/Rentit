import 'package:flutter/material.dart';

class SideBar extends StatefulWidget {
  final Function(int) onItemSelected;
  const SideBar({super.key, required this.onItemSelected});

  @override
  State<SideBar> createState() => _SideBarState();
}

class _SideBarState extends State<SideBar> {
  final List<String> pages = [
    "Admin Dashboard",
    "manageplace",
    "Complaint",
    "manageshop",
    "managedistrict",
    "category",
    "subcategory",
    
  ];
  final List<IconData> icons = [
    Icons.home,
    Icons.map,
    Icons.fact_check, 
    Icons.storefront, 
    Icons.location_city,
    Icons.category,
    Icons.category,
    
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(colors: [
        const Color.fromARGB(255, 210, 155, 155),
        const Color.fromARGB(255, 141, 132, 132)
      ], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Add Dashboard Heading
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  "Dashboard",
                  style: TextStyle(
                    color: const Color.fromARGB(255, 74, 73, 73),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              // ListView for Sidebar Items
              ListView.builder(
                  shrinkWrap: true,
                  itemCount: pages.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      onTap: () {
                        widget.onItemSelected(index);
                      },
                      leading: Icon(icons[index], color: Colors.white),
                      title: Text(pages[index],
                          style: TextStyle(color: Colors.white)),
                    );
                  }),
            ],
          ),
          // Logout Section
          ListTile(
            leading: Icon(Icons.logout_outlined, color: Colors.white),
            title: Text(
              "Logout",
              style: TextStyle(color: Colors.white),
            ),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}
