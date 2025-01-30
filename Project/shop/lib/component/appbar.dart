import 'package:flutter/material.dart';

class Appbar1 extends StatelessWidget {
  const Appbar1({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: 50,
        decoration: BoxDecoration(color: const Color.fromARGB(253, 189, 158, 158)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(
              Icons.person,
              color: Colors.amber,
            ),
            SizedBox(
              width: 10,
            ),
            Text(
              "Admin",
              style: TextStyle(color: Colors.black),
            ),
            SizedBox(
              width: 40,
            )
          ],
        ));
  }
}