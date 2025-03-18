import 'package:flutter/material.dart';
import 'package:shop/screen/login.dart';
import 'package:shop/screen/shopHome.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await Supabase.initialize(
    url: 'https://arixvhqgapwaxuycshaa.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFyaXh2aHFnYXB3YXh1eWNzaGFhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzQzNDYzNjUsImV4cCI6MjA0OTkyMjM2NX0.dRr9mK8ug9UeIif_0UskxKuXsNh8pDoBTST4ShPzTnA',
  );
  runApp(const MainApp());
}

final supabase = Supabase.instance.client;

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;

    if (session != null) {
      // If session exists, navigate to Home
      return const Shophome();
    } else {
      // If no session, navigate to Login
      return const ShopLogin();
    }
  }
}
