import 'package:delivery/screen/deliHomePage.dart';
import 'package:delivery/screen/deliregistration.dart';
import 'package:flutter/material.dart';


class deliLoginPage extends StatefulWidget {
  const deliLoginPage({super.key});

  @override
  _deliLoginPageState createState() => _deliLoginPageState();
}

class _deliLoginPageState extends State<deliLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Login",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: "Email",
                  prefixIcon: Icon(Icons.email),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                   Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const DeliveryBoyHomePage(),
                              ),
                            );
                }, // Add login functionality
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text("Login", style: TextStyle(fontSize: 18)),
              ),
              SizedBox(height: 10),
              TextButton(
                onPressed: () {}, // Add forgot password functionality
                child: Text("Forgot Password?"),
              ),
              TextButton(
                onPressed: () {
                   Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const deliregistration(),
                          ),
                        );
                }, // Navigate to Registration Page
                child: Text("Don't have an account? Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}