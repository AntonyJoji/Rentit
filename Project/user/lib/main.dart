import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:user/screen/login.dart';
import 'package:user/screen/userhomepage.dart';
import 'package:google_fonts/google_fonts.dart';

// Define theme colors
class RentItTheme {
  // Primary colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF64B5F6);
  static const Color darkBlue = Color(0xFF0D47A1);
  
  // Background colors
  static const Color background = Colors.white;
  static const Color secondaryBackground = Color(0xFFF5F8FF);
  
  // Accent colors
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningRed = Color(0xFFE53935);
  
  // Text colors
  static const Color textDark = Color(0xFF212121);
  static const Color textLight = Color(0xFF757575);
  
  // Create blue gradient
  static const Gradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [lightBlue, darkBlue],
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'RentIt',
      theme: ThemeData(
        // Basic theme settings
        scaffoldBackgroundColor: RentItTheme.background,
        primaryColor: RentItTheme.primaryBlue,
        colorScheme: ColorScheme.light(
          primary: RentItTheme.primaryBlue,
          secondary: RentItTheme.accentBlue,
          surface: RentItTheme.background,
          background: RentItTheme.background,
          error: RentItTheme.warningRed,
        ),
        
        // Text theme using Google Fonts
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: RentItTheme.textDark,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: RentItTheme.textDark,
          ),
          titleLarge: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: RentItTheme.textDark,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: RentItTheme.textDark,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: RentItTheme.textDark,
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: RentItTheme.primaryBlue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            elevation: 1,
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: RentItTheme.primaryBlue),
          ),
          hintStyle: GoogleFonts.poppins(color: RentItTheme.textLight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: RentItTheme.textDark,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: RentItTheme.primaryBlue),
          centerTitle: true,
        ),

        // Card theme
        cardTheme: CardTheme(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
        ),
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final session = supabase.auth.currentSession;
    
    // Check if user is logged in
    return session != null ? const UserHomePage() : const UserLoginPage();
  }
}