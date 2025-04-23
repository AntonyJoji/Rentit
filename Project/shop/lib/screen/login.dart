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
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      
      await _authService.storeCredentials(email, password);
      
      final auth = await supabase.auth.signInWithPassword(
        password: password, 
        email: email
      );

      final response = await supabase
          .from('tbl_shop')
          .select()
          .eq('shop_id', auth.user!.id)
          .single();
          
      if(response.isNotEmpty){
        // Check shop verification status
        final dynamic shopStatus = response['shop_vstatus'] ?? '0';
        
        // Handle different shop statuses
        if (shopStatus == '1') {
          // Status 1: Approved shop - proceed to dashboard
          if (mounted) {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => const Shophome())
            );
          }
        } else if (shopStatus == '0') {
          // Status 0: Pending approval
          if (mounted) {
            // Sign out as we don't want pending shops to be logged in
            await supabase.auth.signOut();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your shop is awaiting admin approval. Please check back later.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else if (shopStatus == '2') {
          // Status 2: Rejected
          if (mounted) {
            // Sign out as rejected shops shouldn't be logged in
            await supabase.auth.signOut();
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Your shop registration has been rejected. Please contact support for more information.'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 5),
              ),
            );
          }
        } else {
          // Unknown status
          if (mounted) {
            await supabase.auth.signOut();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Unknown shop status: $shopStatus. Please contact support.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Invalid Credentials'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
     
    } catch (e) {
      print("Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login failed: ${e.toString().split(']').last}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade700,
              Colors.indigo.shade800,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo and Title
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(
                          'assets/ss.jpg',
                          width: 50,
                          height: 50,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 15),
                        const Text(
                          'RENTIT',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Color.fromRGBO(0, 0, 0, 0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 50),
                  
                  // Login Card
                  Container(
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Welcome Header
                        const Text(
                          'Welcome Back!',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Sign in to continue to your shop dashboard',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        // Email Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Email',
                            hintText: 'Enter your email',
                            prefixIcon: Icon(Icons.email_outlined, color: Colors.blue.shade700),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        const SizedBox(height: 20),
                        
                        // Password Field
                        TextField(
                          controller: _passwordController,
                          obscureText: !_isPasswordVisible,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock_outline, color: Colors.blue.shade700),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                                color: Colors.grey,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey.shade300),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue.shade700, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                            contentPadding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                        
                        // Remember Me / Forgot Password
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                // Implement forgot password
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                alignment: Alignment.centerRight,
                              ),
                              child: const Text('Forgot Password?'),
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 24),
                        
                        // Login Button
                        SizedBox(
                          height: 55,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade700,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              textStyle: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Sign In'),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Register Link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account?",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const ShopRegistration()),
                                );
                              },
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.blue.shade700,
                                padding: const EdgeInsets.symmetric(horizontal: 6),
                                minimumSize: const Size(50, 30),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                "Register",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}