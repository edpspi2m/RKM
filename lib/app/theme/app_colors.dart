import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0D47A1);
  static const Color primaryDark = Color(0xFF08306B);
  static const Color primaryLight = Color(0xFF5472D3);

  static const Color action = Color(0xFF00A876); // hijau segar, lebih hidup dari sebelumnya
  static const Color actionDark = Color(0xFF00754F);

  static const Color background = Color(0xFFF4F7FA);
  static const Color surface = Colors.white;
  static const Color inputFill = Color(0xFFF0F3F8);
  static const Color divider = Color(0xFFE3E8EF);

  static const Color textPrimary = Color(0xFF1A2233);
  static const Color textSecondary = Color(0xFF7C8798);

  static const Color error = Color(0xFFE5484D);
  static const Color warning = Color(0xFFF5A623);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient actionGradient = LinearGradient(
    colors: [action, Color(0xFF00C896)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
