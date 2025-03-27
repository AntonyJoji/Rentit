import 'package:flutter/material.dart';
import 'package:shop/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shop/screen/shopHome.dart';
import 'package:shop/screen/shopregestration.dart';

class ShopLogin extends StatefulWidget {
  const ShopLogin({super.key});

  @override
  State<ShopLogin> createState() => _ShopLoginState();
}

class _ShopLoginState extends State<ShopLogin> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final SupabaseClient supabase = Supabase.instance.client;
   final AuthService _authService = AuthService();

  Future<void> _login() async {
    try {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    await _authService.storeCredentials(
          _emailController.text, _passwordController.text);
    final auth = await supabase.auth.signInWithPassword(password: password, email: email);

    
      final response = await supabase
          .from('tbl_shop')
          .select()
          .eq('shop_id', auth.user!.id)
          .single();
      if(response.isNotEmpty){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Shophome(),));
      }
      else{
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid Credentials')),
      );
      }
     
    } catch (e) {
      print("Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Color(0xFFF2F1F1)),
        child: Center(
          child: Column(
            children: [
              SizedBox(height: 50),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(15),
                    child: Image.asset(
                      'assets/ss.jpg',
                      width: 40,
                      height: 40,
                    ),
                  ),
                  Text(
                    'RENTIT',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 20),
              Container(
                width: 300,
                height: 450,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.white,
                ),
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    Text('Login', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    SizedBox(height: 15),
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          border: UnderlineInputBorder(),
                          prefixIcon: Icon(Icons.email),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(20.0),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          border: UnderlineInputBorder(),
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: Icon(Icons.visibility),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(10.0),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF4092D6),
                          padding: EdgeInsets.symmetric(horizontal: 100, vertical: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
                        ),
                        onPressed: _login,
                        child: Text('Login', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ShopRegistration()),
                        );
                      },
                      child: Text(
                        "Don't have an account? Register here",
                        style: TextStyle(color: Colors.blue, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
