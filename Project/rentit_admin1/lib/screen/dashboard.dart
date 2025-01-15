import 'package:flutter/material.dart';

class AdminDashBoard extends StatefulWidget {
  const AdminDashBoard({super.key});

  @override
  State<AdminDashBoard> createState() => _AdminDashBoardState();
}

class _AdminDashBoardState extends State<AdminDashBoard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 1150,
            height: 50,
            decoration: BoxDecoration(color: Colors.blue),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset(
                    'assets/Profile.jpg',
                    width: 30,
                    height: 30,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Text(
                    'Admin',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                SizedBox(
                  width: 50,
                )
              ],
            ),
          ),
          Container(
            width: 240,
            height: 535,
            decoration: BoxDecoration(color: const Color.fromARGB(255, 214, 219, 223)),
            child: Column(
              children: [
                Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 17),
                ),
                SizedBox(
                  height: 10,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 132, 187, 232),
                            padding: EdgeInsets.symmetric(
                                horizontal: 80, vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5))),
                        onPressed: () {},
                        child: Text(
                          'District',
                          style: TextStyle(color: const Color.fromARGB(255, 14, 3, 3)),
                        )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 143, 184, 218),
                            padding: EdgeInsets.symmetric(
                                horizontal: 80, vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5))),
                        onPressed: () {},
                        child: Text(
                          'Place',
                          style: TextStyle(
                              color: const Color.fromARGB(255, 7, 0, 0)),
                        )),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30), // Rounded corners
                    child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                const Color.fromARGB(255, 152, 186, 214),
                            padding: EdgeInsets.symmetric(
                                horizontal: 80, vertical: 18),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5))),
                        onPressed: () {},
                        child: Text(
                          'Shop',
                          style: TextStyle(color: const Color.fromARGB(255, 27, 2, 2)),
                        )),
                  ),
                ),
                SizedBox(
                  height: 250,
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 116, 154, 186),
                          padding: EdgeInsets.symmetric(
                              horizontal: 80, vertical: 18),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5))),
                      onPressed: () {},
                      child: Text(
                        'Logout',
                        style: TextStyle(color: const Color.fromARGB(255, 39, 1, 1)),
                      )),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
