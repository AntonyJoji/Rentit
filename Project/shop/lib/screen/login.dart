import 'package:flutter/material.dart';
import 'package:shop/screen/shopHome.dart';
import 'package:shop/screen/shopregestration.dart'; // Import your registration page

class ShopLogin extends StatefulWidget {
  const ShopLogin({super.key});

  @override
  State<ShopLogin> createState() => _ShopLoginState();
}

class _ShopLoginState extends State<ShopLogin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration:
            BoxDecoration(color: const Color.fromARGB(255, 242, 241, 241)),
        child: Form(
            child: Center(
          child: Column(
            children: [
              SizedBox(
                height: 50,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Image.asset(
                      'assets/ss.jpg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  Text(
                    'RENTIT',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              SizedBox(
                height: 20,
              ),
              Container(
                width: 300,
                height: 450, // Increased height to accommodate the new link
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: const Color.fromARGB(196, 255, 255, 255),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 20,
                    ),
                    Text(
                      'Login',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(
                      height: 15,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            hintStyle: TextStyle(fontSize: 12),
                            hintText: 'Email',
                            border: UnderlineInputBorder(),
                            prefixIcon: Icon(Icons.email)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: TextFormField(
                        decoration: InputDecoration(
                            hintStyle: TextStyle(fontSize: 12),
                            hintText: 'Password',
                            border: UnderlineInputBorder(),
                            prefixIcon: Icon(Icons.password),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.visibility),
                              onPressed: () {},
                            )),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(15.0),
                          child: Text(
                            'forgot password?',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 27, 150, 250),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 64, 146, 214),
                              padding: EdgeInsets.symmetric(
                                  horizontal: 100, vertical: 18),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5))),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Shophome(),
                              ),
                            );
                          },
                          child: Text(
                            'Login',
                            style: TextStyle(color: Colors.white),
                          )),
                    ),
                    SizedBox(height: 10), // Space between button and link
                    TextButton(
                      onPressed: () {
                        // Navigate to the registration page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ShopRegistration(),
                          ),
                        );
                      },
                      child: Text(
                        'Don\'t have an account? Register here',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            ],
          ),
        )),
      ),
    );
  }
}