import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Your color palette
const Color primaryPandaColor = Color(0xFF2d2d2d); // Dark charcoal
const Color secondaryPenguinColor = Color(0xFFFFA726); // Warm orange
const Color lightBackgroundColor = Color(0xFFF0F4F8); // Very light blue-gray
const Color cardBackgroundColor = Colors.white;

// Your text theme using Google Fonts
final TextTheme customTextTheme = TextTheme(
  displayLarge: GoogleFonts.quicksand(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryPandaColor,
  ),
  headlineLarge: GoogleFonts.quicksand(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: primaryPandaColor,
  ),
  titleLarge: GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: primaryPandaColor,
  ),
  bodyLarge: GoogleFonts.poppins(
    fontSize: 16,
    color: primaryPandaColor,
  ),
  bodyMedium: GoogleFonts.nunito(
    fontSize: 14,
    color: primaryPandaColor,
  ),
);

// Your App's Theme Data
final ThemeData appTheme = ThemeData(
  primaryColor: primaryPandaColor,
  scaffoldBackgroundColor: lightBackgroundColor,
  colorScheme: ColorScheme.fromSwatch(
    primarySwatch: Colors.grey,
  ).copyWith(
    primary: primaryPandaColor,
    secondary: secondaryPenguinColor,
  ),
  textTheme: customTextTheme,
  cardTheme: CardThemeData(
    color: cardBackgroundColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    elevation: 4,
    shadowColor: Colors.black.withOpacity(0.1),
  ),
  buttonTheme: ButtonThemeData(
    buttonColor: secondaryPenguinColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    textTheme: ButtonTextTheme.primary,
  ),
);