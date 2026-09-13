import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF6D4AFF);
  static const primarySoft = Color(0xFFEDE8FF);
  static const primarySurface = Color(0xFFF4F0FF);

  static const lightBackground = Color(0xFFFFFBF7);
  static const lightSurface = Colors.white;
  static const darkBackground = Color(0xFF101014);
  static const darkSurface = Color(0xFF1A1A20);
  static const darkSurfaceAlt = Color(0xFF23232B);

  static const danger = Color(0xFFE05252);
  static const warning = Color(0xFFFFB84D);
  static const success = Color(0xFF38BFA0);
  static const info = Color(0xFF4D8DFF);

  // Shift status colors. Current position is deliberately separate from state.
  static const currentMarker = Color(0xFFFF5A5F);
  static const shiftWork = Color(0xFFFFC857);
  static const shiftRest = Color(0xFF42C89A);
  static const shiftOff = Color(0xFF5B8DEF);
}
