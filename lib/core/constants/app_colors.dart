import 'package:flutter/material.dart';

/// Figma Make design system colors for LIKH AI
/// Source of Truth: Figma Make (https://www.figma.com/make/1uqdnsTRE4PgbXk0gQQlA4/Create-LIKH-AI-logo)
class AppColors {
  // Brand Accents
  static const Color primary = Color(0xFFDF6729); // Signature LIKH Coral / Orange
  static const Color primaryLight = Color(0xFFF97316); // Energetic Coral Light
  static const Color primaryDark = Color(0xFFC2541C); // Deep Burnt Orange
  static const Color secondary = Color(0xFFF59E0B); // Warm Amber
  static const Color brandNavy = Color(0xFF101D2D); // Deep Obsidian Navy from Figma Mark

  // Canvas / Backgrounds
  static const Color bgLight = Color(0xFFF2EFE7); // Warm Parchment Cream Canvas
  static const Color bgDark = Color(0xFF0A121D); // Obsidian Midnight Canvas
  static const Color bgLightHero = Color(0xFFFCFAF6); // Paper White Hero Card Background
  static const Color bgDarkHero = Color(0xFF0F1A28); // Elevated Dark Navy Hero Background

  // Surfaces & Cards
  static const Color surfaceLight = Color(0xFFFCFAF6); // Pure Paper White Card
  static const Color surfaceDark = Color(0xFF101D2D); // Figma Make Dark Card Surface
  static const Color cardLight = Color(0xFFFCFAF6);
  static const Color cardDark = Color(0xFF101D2D);
  static const Color cardLightSecondary = Color(0xFFF3F0E8);
  static const Color cardDarkSecondary = Color(0xFF16263A);

  // Borders & Dividers
  static const Color borderLight = Color(0xFFE4DFD3); // Delicate Warm Border
  static const Color borderDark = Color(0xFF1E2D42); // Subtle Dark Navy Border
  static const Color borderLightSubtle = Color(0xFFEFECE5);
  static const Color borderDarkSubtle = Color(0xFF172435);

  // Typography
  static const Color textLight = Color(0xFF101D2D); // Deep Obsidian Black
  static const Color textDark = Color(0xFFF8F6F0); // Warm Cream White
  static const Color textMutedLight = Color(0xFF6B7280); // Refined Gray
  static const Color textMutedDark = Color(0xFF94A3B8); // Slate Light Muted
  static const Color textSubtleLight = Color(0xFF9CA3AF);
  static const Color textSubtleDark = Color(0xFF64748B);

  // Status & Feedback
  static const Color success = Color(0xFF10B981); // Emerald Green
  static const Color warning = Color(0xFFF59E0B); // Amber Warning
  static const Color error = Color(0xFFEF4444); // Crimson Error
  static const Color info = Color(0xFF3B82F6); // Blue Info

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFDF6729), Color(0xFFF97316)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroLightGradient = LinearGradient(
    colors: [Color(0xFFFCFAF6), Color(0xFFF6F3EC)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient heroDarkGradient = LinearGradient(
    colors: [Color(0xFF101D2D), Color(0xFF0B1420)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient markDarkGradient = LinearGradient(
    colors: [Color(0xFF132235), Color(0xFF0D1724)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
