import 'package:flutter/material.dart';

/// Global utility functions and constants for the app

/// Check if the current screen width is less than 440px (mobile device)
bool isMobile(BuildContext context) {
  return MediaQuery.of(context).size.width < 440;
}

bool isWide(BuildContext context) {
  return MediaQuery.of(context).size.width >= 900;
}

/// App color constants
class AppColors {
  // Primary colors
  static const Color primary = Color.fromRGBO(94, 107, 160, 1); // Header blue
  static const Color secondary = Color(0xFFEEF3F3); // Light gray background
  static const Color tertiary = Colors.amber; // Amber/yellow accent
  static const Color soka = Color.fromRGBO(
    26,
    35,
    126,
    1,
  ); // Blue institutional SGIAR

  // Basic colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color black87 = Colors.black87;
  static const Color black54 = Colors.black54;
  static const Color grey = Colors.grey;

  // Semantic colors
  static const Color blue = Colors.blue;
  static const Color amber = Colors.amber;
  static const Color amberLight = Color(0xFFFFF8E1); // Light amber background

  // Background colors
  static const Color backgroundLight = Color(
    0xFFEEF3F3,
  ); // Light gray background
  static const Color backgroundOutsideDay = Color.fromRGBO(
    249,
    250,
    252,
    0.15,
  ); // Outside day background

  // Text colors
  static const Color textDark = Color.fromARGB(255, 16, 17, 27); // Dark text
  static const Color textLight = Colors.white;

  // Gradient colors
  static const Color gradient1 = Color(0xFFEEAECA); // rgba(238, 174, 202, 1)
  static const Color gradient2 = Color(0xFF94BBE9); // rgba(148, 187, 233, 1)

  // Error colors
  static const Color error = Color(0xFFF44336);
  // Private constructor to prevent instantiation
  AppColors._();
}
