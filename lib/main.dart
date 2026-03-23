import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/home_screen.dart';
import 'package:provider/provider.dart';
import 'viewmodel/admin_inbox_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://tkfspwjyyerynizfmrok.supabase.co',
    anonKey: 'sb_publishable_2h61nZYHjRTDOAzLPzPW2w_0YwtxEGD',
  );

  // We are just wrapping your app in the MultiProvider here!
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AdminInboxViewModel())],
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
