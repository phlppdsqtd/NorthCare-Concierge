import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase using your project details
  await Supabase.initialize(
    url: 'https://tkfspwjyyerynizfmrok.supabase.co',
    anonKey: 'sb_publishable_2h61nZYHjRTDOAzLPzPW2w_0YwtxEGD',
  );

  runApp(const NorthCareApp());
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
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}