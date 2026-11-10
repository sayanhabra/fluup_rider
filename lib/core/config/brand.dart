// lib/core/theme/brand.dart

import 'package:flutter/material.dart';

class Brand {
  Brand._();

  // ─────────────────────────────────────────────────────────────
  // CORE PALETTE — Velvet Courier / Dashboard Theme
  // ─────────────────────────────────────────────────────────────
  static const Color red = Color(0xFFE52535);
  static const Color redLight = Color(0xFFFDEDEF);
  static const Color redBorder = Color(0xFFFFD1D5);
  static const Color topBlush = Color(0xFFFDEDEF);

  static const Color green = Color(0xFF10B981);
  static const Color greenLight = Color(0xFFECFDF5);
  static const Color greenDark = Color(0xFF065F46);
  static const Color greenDarker = Color(0xFF047857);

  static const Color textDark = Color(0xFF0F172A);
  static const Color subtext = Color(0xFF64748B);
  static const Color muted = Color(0xFF94A3B8);
  static const Color border = Color(0xFFF1F5F9);
  static const Color bgSoft = Color(0xFFF8FAFC);
  static const Color bgApp = Color(0xFFFAFAFA);
  static const Color danger = Color(0xFFEF4444);
  static const Color backgroundLight = Color(0xFFF7F5F0);
  // static const Color abc = Color(0xFFEF4444);

  // ─────────────────────────────────────────────────────────────
  // EXTENDED PALETTE (newly added)
  // ─────────────────────────────────────────────────────────────

  // Warning / Orange (pending, review, store)
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFFB45309);
  static const Color orange = Color(0xFFF97316);
  static const Color orangeLight = Color(0xFFFFEDD5);

  // Info / Blue (addresses, contact)
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // Purple (notifications, inventory, deepPurple)
  static const Color purple = Color(0xFF8B5CF6);
  static const Color purpleLight = Color(0xFFEDE9FE);
  static const Color deepPurple = Color(0xFF6D28D9);

  // Teal (support, orders)
  static const Color teal = Color(0xFF14B8A6);
  static const Color tealLight = Color(0xFFCCFBF1);

  // Indigo (bank, appearance)
  static const Color indigo = Color(0xFF4F46E5);
  static const Color indigoLight = Color(0xFFE0E7FF);

  // Cyan (delivery settings)
  static const Color cyan = Color(0xFF06B6D4);
  static const Color cyanLight = Color(0xFFCFFAFE);

  // Pink (wishlist)
  static const Color pink = Color(0xFFEC4899);
  static const Color pinkLight = Color(0xFFFCE7F3);

  // Amber (offers & coupons)
  static const Color amber = Color(0xFFD97706);
  static const Color amberLight = Color(0xFFFEF3C7);

  // Grey (blocked / muted states)
  static const Color grey = Color(0xFF64748B);
  static const Color greyDark = Color(0xFF334155);
  static const Color greyLight = Color(0xFFF1F5F9);

  // Blue-grey (language)
  static const Color blueGrey = Color(0xFF546E7A);

  // ─────────────────────────────────────────────────────────────
  // DARK MODE SURFACES
  // ─────────────────────────────────────────────────────────────
  static const Color darkBg = Color(0xFF1E1E1E);
  static const Color darkSurface = Color(0xFF2A2A2A);
  static const Color darkBorder = Color(0xFF3A3A3A);

  // Profile header gradients
  static const LinearGradient headerGradientLight = LinearGradient(
    colors: [Color(0xFFE52535), Color(0xFFFF4D5E)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradientDark = LinearGradient(
    colors: [Color(0xFF45151C), Color(0xFF241014)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Savings / business gradient
  static const LinearGradient savingsGradient = LinearGradient(
    colors: [greenDark, greenDarker],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
