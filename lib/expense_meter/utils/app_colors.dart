import 'package:flutter/material.dart';

class AppColors {
  static const Color mainPink = Color(0xFF7B0041);
  static const Color lightBackground = Color(0xFFFCF7F3);
  static const Color borderPink = Color(0xFFDEC9CB);
  static const Color black = Color.fromRGBO(18, 18, 18, 1);
  static const Color xpenseMain = Color.fromRGBO(106, 21, 55, 1);
  static const Color lightPink = Color.fromRGBO(194, 24, 91, 1);

  // Common UI colors
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  // Status colors
  static const Color green = Color(0xFF00C853);
  static const Color red = Color(0xFFF44336);
  static const Color brown = Color(0xFFB08B72);

  // Platform brand colors (Spend by Platform / Set Budget).
  // Grokly uses `green` above; these two are dedicated so they don't
  // collide with `lightPink`, which is already the app's general accent.
  static const Color swadishttPink = Color(0xFFE91E63);

  // Grey shades
  static const Color lightGrey = Color(0xFFF3F1F4);
  static const Color grey = Color(0xFF8D8992);
  static const Color darkGrey = Color(0xFF252525);
  static const Color sliderGrey = Color(0xFFD7D3DA);
  static const Color divider = Color(0x1AFFFFFF);
}
