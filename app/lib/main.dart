import 'package:app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/memory_provider.dart';
import 'screens/home_screen.dart'; // We'll create this

void main() {
  // Make sure you initialize Firebase here
  WidgetsFlutterBinding.ensureInitialized();
  // await Firebase.initializeApp(); // Uncomment this after setup

  runApp(
    ChangeNotifierProvider(
      create: (context) => MemoryProvider(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Little World',
      theme: appTheme,
      home: SplashScreen(), // We'll create this
      debugShowCheckedModeBanner: false,
    );
  }
}
