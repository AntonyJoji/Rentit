import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/login.dart';


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
    return const MaterialApp(
      home:UserLoginPage() ,
    );
  }
}