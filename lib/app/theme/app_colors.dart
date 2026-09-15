import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ============ BACKGROUND ============
  static const Color background = Color(0xFFF0F4F8);
  static const Color surface    = Colors.white;
  static const Color inputFill  = Colors.white;
  static const Color divider    = Color(0xFFE5E7EB);

  // ============ PRIMARY (BIRU) ============
  static const Color primary      = Color(0xFF1E40AF);  // biru utama
  static const Color primaryDark  = Color(0xFF1E3A8A);  // biru lebih gelap
  static const Color primaryLight = Color(0xFFBFDBFE);  // biru muda

  // ============ ACTION (SUCCESS / HIJAU) ============
  // "action" dipakai untuk tombol utama & status sukses
  static const Color action      = Color(0xFF10B981);  // hijau
  static const Color actionDark  = Color(0xFF059669);
  static const Color actionLight = Color(0xFFD1FAE5);  // hijau muda
  static const Color actionText  = Color(0xFF047857);

  // ============ STATUS WARNA ============
  static const Color error   = Color(0xFFEF4444);  // merah
  static const Color warning = Color(0xFFF97316);  // orange
  static const Color success = Color(0xFF10B981);  // hijau (= action)

  // ============ TEXT ============
  static const Color textPrimary   = Color(0xFF000000);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textLight     = Colors.white;

  // ============ BORDER & SHADOW (Neo-brutalism) ============
  static const Color border = Color(0xFF000000);
  static const Color shadow = Color(0xFF000000);

  // ============ ALIAS (untuk kompatibilitas) ============
  static const Color accent    = Color(0xFFFBBF24);
  static const Color accentAlt = Color(0xFF22D3EE);
  static const Color danger    = Color(0xFFEF4444);
}
