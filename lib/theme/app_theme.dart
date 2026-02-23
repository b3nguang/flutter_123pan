import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: CatppuccinLatte.blue,
        onPrimary: Colors.white,
        secondary: CatppuccinLatte.teal,
        onSecondary: Colors.white,
        surface: CatppuccinLatte.base,
        onSurface: CatppuccinLatte.text,
        error: CatppuccinLatte.red,
        onError: Colors.white,
        surfaceContainerHighest: CatppuccinLatte.mantle,
        outline: CatppuccinLatte.surface0,
      ),
      scaffoldBackgroundColor: CatppuccinLatte.base,
      cardColor: Colors.white,
      dividerColor: CatppuccinLatte.surface0,
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: CatppuccinLatte.text),
        bodySmall: TextStyle(color: CatppuccinLatte.subtext0),
        titleMedium: TextStyle(color: CatppuccinLatte.text, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: CatppuccinLatte.text, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinLatte.surface1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinLatte.surface1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinLatte.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CatppuccinLatte.blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CatppuccinLatte.blue,
          side: const BorderSide(color: CatppuccinLatte.surface1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: CatppuccinLatte.mantle,
        selectedIconTheme: IconThemeData(color: CatppuccinLatte.blue),
        unselectedIconTheme: IconThemeData(color: CatppuccinLatte.subtext0),
        selectedLabelTextStyle: TextStyle(color: CatppuccinLatte.blue, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: CatppuccinLatte.subtext0),
        indicatorColor: Color(0x331E66F5),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(CatppuccinLatte.mantle),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x331E66F5);
          }
          if (states.contains(WidgetState.hovered)) {
            return CatppuccinLatte.crust;
          }
          return Colors.transparent;
        }),
        dividerThickness: 0.5,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CatppuccinLatte.surface0,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: CatppuccinLatte.text, fontSize: 12),
      ),
    );
  }

  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: CatppuccinMocha.blue,
        onPrimary: CatppuccinMocha.base,
        secondary: CatppuccinMocha.teal,
        onSecondary: CatppuccinMocha.base,
        surface: CatppuccinMocha.base,
        onSurface: CatppuccinMocha.text,
        error: CatppuccinMocha.red,
        onError: CatppuccinMocha.base,
        surfaceContainerHighest: CatppuccinMocha.surface0,
        outline: CatppuccinMocha.surface1,
      ),
      scaffoldBackgroundColor: CatppuccinMocha.base,
      cardColor: CatppuccinMocha.surface0,
      dividerColor: CatppuccinMocha.surface1,
      fontFamily: 'Segoe UI',
      textTheme: const TextTheme(
        bodyMedium: TextStyle(color: CatppuccinMocha.text),
        bodySmall: TextStyle(color: CatppuccinMocha.subtext0),
        titleMedium: TextStyle(color: CatppuccinMocha.text, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(color: CatppuccinMocha.text, fontWeight: FontWeight.bold),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: CatppuccinMocha.surface0,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.surface1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: CatppuccinMocha.blue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: CatppuccinMocha.blue,
          foregroundColor: CatppuccinMocha.base,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: CatppuccinMocha.blue,
          side: const BorderSide(color: CatppuccinMocha.surface1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        ),
      ),
      navigationRailTheme: const NavigationRailThemeData(
        backgroundColor: CatppuccinMocha.mantle,
        selectedIconTheme: IconThemeData(color: CatppuccinMocha.blue),
        unselectedIconTheme: IconThemeData(color: CatppuccinMocha.subtext0),
        selectedLabelTextStyle: TextStyle(color: CatppuccinMocha.blue, fontWeight: FontWeight.w600),
        unselectedLabelTextStyle: TextStyle(color: CatppuccinMocha.subtext0),
        indicatorColor: Color(0x3389B4FA),
      ),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(CatppuccinMocha.mantle),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0x3389B4FA);
          }
          if (states.contains(WidgetState.hovered)) {
            return CatppuccinMocha.surface1;
          }
          return Colors.transparent;
        }),
        dividerThickness: 0.5,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: CatppuccinMocha.surface0,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: const TextStyle(color: CatppuccinMocha.text, fontSize: 12),
      ),
    );
  }
}
