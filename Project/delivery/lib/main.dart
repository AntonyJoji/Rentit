import 'package:delivery/screen/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:delivery/screen/deliHomePage.dart';
import 'package:google_fonts/google_fonts.dart';

// Define theme colors
class DeliveryTheme {
  // Primary colors
  static const Color primaryTeal = Color(0xFF009688);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color darkTeal = Color(0xFF00796B);
  
  // Accent colors
  static const Color accentOrange = Color(0xFFFF5722);
  static const Color accentYellow = Color(0xFFFFB74D);
  
  // Background colors
  static const Color scaffoldBg = Color(0xFFF5F5F5);
  static const Color cardBg = Colors.white;
  
  // Text colors
  static const Color textDark = Color(0xFF333333);
  static const Color textMedium = Color(0xFF666666);
  static const Color textLight = Color(0xFF999999);
  static const Color textWhite = Colors.white;
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
      title: 'Delivery App',
      theme: ThemeData(
        // Basic theme settings
        scaffoldBackgroundColor: DeliveryTheme.scaffoldBg,
        primaryColor: DeliveryTheme.primaryTeal,
        colorScheme: ColorScheme.light(
          primary: DeliveryTheme.primaryTeal,
          secondary: DeliveryTheme.accentOrange,
          surface: DeliveryTheme.cardBg,
          background: DeliveryTheme.scaffoldBg,
        ),
        
        // Text theme using Google Fonts
        textTheme: TextTheme(
          displayLarge: GoogleFonts.poppins(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: DeliveryTheme.textDark,
          ),
          displayMedium: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: DeliveryTheme.textDark,
          ),
          bodyLarge: GoogleFonts.poppins(
            fontSize: 16,
            color: DeliveryTheme.textDark,
          ),
          bodyMedium: GoogleFonts.poppins(
            fontSize: 14,
            color: DeliveryTheme.textMedium,
          ),
        ),
        
        // Button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: DeliveryTheme.primaryTeal,
            foregroundColor: DeliveryTheme.textWhite,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: DeliveryTheme.lightTeal),
          ),
          hintStyle: GoogleFonts.poppins(color: DeliveryTheme.textLight),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: GoogleFonts.poppins(
            color: DeliveryTheme.textDark,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          iconTheme: IconThemeData(color: DeliveryTheme.textDark),
        ),
      ),
      home: const AuthWrapper(), // Use AuthWrapper to check authentication state
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  String? _boyId;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final session = supabase.auth.currentSession;
      
      if (session != null) {
        final user = session.user;
        // Check if email exists
        if (user.email == null) {
          print('User email is null');
          setState(() => _isLoading = false);
          return;
        }
        
        // Get boy_id from the database
        final deliveryBoy = await supabase
            .from('tbl_deliveryboy')
            .select('boy_id')
            .eq('boy_email', user.email!)
            .maybeSingle();

        if (deliveryBoy != null && deliveryBoy['boy_id'] != null) {
          setState(() {
            _boyId = deliveryBoy['boy_id'].toString();
            _isLoading = false;
          });
          return;
        }
      }
    } catch (e) {
      print('Error checking auth state: $e');
    }
    
    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    if (_boyId != null) {
      return DeliveryBoyHomePage(boyId: _boyId!);
    } else {
      return const deliLoginPage();
    }
  }
}