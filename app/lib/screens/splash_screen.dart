import 'package:app/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:app/utils/database_helper.dart';
import 'time_line_screen.dart';
import 'character_selection_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNextScreen();
  }

  void _navigateToNextScreen() async {
    await Future.delayed(
      Duration(seconds: 3),
    ); // Show splash screen for 3 seconds

    final dbHelper = DatabaseHelper();
    final characterChoice = await dbHelper.getCharacterChoice();

    // Navigate to the appropriate screen
    if (characterChoice != null) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (context) => MainScreen()));
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => CharacterSelectionScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/splash_screen.png',
            ), // Your splash screen image
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
