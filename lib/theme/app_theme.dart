import 'package:flutter/material.dart';

/// Central place for app-wide styling and the per-template look used both
/// in-app (template picker) and in the generated PDF.
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorSchemeSeed: const Color(0xFF1B4965),
      scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}

/// Defines the look of each resume template.
/// id: 1 = Classic, 2 = Modern, 3 = Minimal
class TemplateStyle {
  final int id;
  final String name;
  final String description;
  final Color primaryColor;
  final Color accentColor;

  const TemplateStyle({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
  });

  static const List<TemplateStyle> all = [
    TemplateStyle(
      id: 1,
      name: 'Classic',
      description: 'Traditional centered layout, ideal for corporate & government roles',
      primaryColor: Color(0xFF1B2A41),
      accentColor: Color(0xFF1B2A41),
    ),
    TemplateStyle(
      id: 2,
      name: 'Modern',
      description: 'Two-column layout with a color accent, great for tech & startups',
      primaryColor: Color(0xFF1B4965),
      accentColor: Color(0xFF5FA8D3),
    ),
    TemplateStyle(
      id: 3,
      name: 'Minimal',
      description: 'Grayscale, generous whitespace, single column, ATS-friendly',
      primaryColor: Color(0xFF222222),
      accentColor: Color(0xFF666666),
    ),
  ];

  static TemplateStyle byId(int id) =>
      all.firstWhere((t) => t.id == id, orElse: () => all.first);
}
