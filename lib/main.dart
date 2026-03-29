import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; // <-- 1. Import Google Fonts

import 'views/home_screen.dart';
import 'viewmodel/admin_inbox_viewmodel.dart';
import 'viewmodel/chat_viewmodel.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart'; // Add this

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env"); // Add this

  await Supabase.initialize(
    url: 'https://tkfspwjyyerynizfmrok.supabase.co',
    anonKey: 'sb_publishable_2h61nZYHjRTDOAzLPzPW2w_0YwtxEGD',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AdminInboxViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel()),
      ],
      child: const NorthCareApp(),
    ),
  );
}

class NorthCareApp extends StatelessWidget {
  const NorthCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NorthCare Concierge',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        scaffoldBackgroundColor: Colors.grey.shade50,
        useMaterial3: true,
        
        // Apply Inter to the entire app's TextTheme
        textTheme: GoogleFonts.interTextTheme(
          Theme.of(context).textTheme,
        ),
        
        appBarTheme: AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 0,
          // Use GoogleFonts.inter() directly for the TextStyle!
          titleTextStyle: GoogleFonts.inter(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}