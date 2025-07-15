import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_screen.dart';
import 'home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://ktnkphddnnaytjxwauip.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imt0bmtwaGRkbm5heXRqeHdhdWlwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTI2MDY5MDgsImV4cCI6MjA2ODE4MjkwOH0.R_hzpgIY09NGUcxpys8g7wp4iRBmfu1w_I8CdKrdajQ',
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthScreen(),
        '/home': (context) => const HomeScreen(),
        '/add': (context) => const AddVisitorScreen(),
      },
    );
  }
}

// ... Pantallas y widgets se implementarán aquí ...
