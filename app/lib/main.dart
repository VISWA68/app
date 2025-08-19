import 'package:app/firebase_options.dart';
import 'package:app/providers/auth_provider.dart';
import 'package:app/providers/bobby_chat_provider.dart';
import 'package:app/providers/daily_prompt_provider.dart';
import 'package:app/providers/map_provider.dart';
import 'package:app/providers/quiz_provider.dart';
import 'package:app/screens/splash_screen.dart';
import 'package:app/utils/database_helper.dart';
import 'services/notification_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/memory_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService().initialize();
  final role = await DatabaseHelper().getCharacterChoice();
  // Set OneSignal external user ID for push notification targeting
  if (role != null) {
    await NotificationService().setExternalUserId(role);
  }
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MemoryProvider()),
        ChangeNotifierProvider(create: (context) => DailyPromptProvider()),
        ChangeNotifierProvider(create: (context) => MapProvider()),
        ChangeNotifierProvider(create: (context) => BobbyChatProvider(role!)),
        ChangeNotifierProvider(create: (context) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Our Little World',
      theme: appTheme,
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
