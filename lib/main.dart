// main.dart

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'views/home_screen.dart';
import 'viewmodel/admin_inbox_viewmodel.dart';
import 'viewmodel/chat_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}