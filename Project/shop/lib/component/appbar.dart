import 'package:flutter/material.dart';

class Appbar1 extends StatelessWidget {
  const Appbar1({super.key});

 @override
Widget build(BuildContext context) {
  return Container(
    height: 60, // Adjusted height for better balance
    decoration: const BoxDecoration(
      color: Color(0xFF4092D6), // RentIt theme color
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(20),
        bottomRight: Radius.circular(20),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Icon(
                Icons.person,
                color: Colors.white, // Profile icon color
              ),
              const SizedBox(width: 10),
              const Text(
                "Shop",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 20),
            ],
          ),
        ),
      ],
    ),
  );
}
}