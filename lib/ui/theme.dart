import 'package:flutter/material.dart';

/// Jetons de couleur de la spec 10 : le seul endroit où ils sont écrits.
abstract final class Palette {
  static const background = Color(0xFF0B0F17);
  static const bar = Color(0xFF0E1420);
  static const surface = Color(0xFF131A26);
  static const line = Color(0xFF233046);

  static const text = Color(0xFFE6EDF7);
  static const textSecondary = Color(0xFFA3B2C9);
  static const textTertiary = Color(0xFF8A9BB4);

  static const action = Color(0xFFF2A93B);
  static const onAction = Color(0xFF1A1206);
  static const inProgress = Color(0xFF1A1408);
  static const inProgressLine = Color(0xFF5A4116);
  static const inProgressTrack = Color(0xFF33270F);

  static const free = Color(0xFF66BB6A);

  /// Bandeau opaque du hero : jamais de texte sur l'image nue.
  static const heroScrim = Color(0xD10B0F17);
}

const _display = 'SpaceGrotesk';
const _body = 'Inter';
const _numbers = 'JetBrainsMono';

/// Chiffres : JetBrains Mono, largeur fixe pour que les stocks ne dansent pas.
TextStyle? mono(TextStyle? base) =>
    base?.copyWith(fontFamily: _numbers, fontWeight: FontWeight.w500);

ThemeData buildTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: const Color(0xFFF5C451),
        brightness: Brightness.dark,
      ).copyWith(
        primary: Palette.action,
        onPrimary: Palette.onAction,
        surface: Palette.surface,
        onSurface: Palette.text,
        onSurfaceVariant: Palette.textSecondary,
        outline: Palette.line,
        outlineVariant: Palette.line,
      );
  final base = ThemeData(colorScheme: scheme, fontFamily: _body);
  final text = base.textTheme;
  final buttons = RoundedRectangleBorder(borderRadius: BorderRadius.circular(10));
  return base.copyWith(
    scaffoldBackgroundColor: Palette.background,
    textTheme: text.copyWith(
      titleLarge: text.titleLarge?.copyWith(fontFamily: _display, fontWeight: FontWeight.w700),
      titleMedium: text.titleMedium?.copyWith(fontFamily: _display, fontWeight: FontWeight.w500),
      titleSmall: text.titleSmall?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
    ),
    cardTheme: CardThemeData(
      color: Palette.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: Palette.line, space: 1),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.surface,
      surfaceTintColor: Colors.transparent,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Palette.bar,
      surfaceTintColor: Colors.transparent,
      height: 64,
      indicatorColor: Palette.inProgress,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          color: s.contains(WidgetState.selected) ? Palette.action : Palette.textSecondary,
        ),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => text.labelSmall?.copyWith(
          fontWeight: FontWeight.w500,
          color: s.contains(WidgetState.selected) ? Palette.action : Palette.textSecondary,
        ),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(minimumSize: const Size(48, 48), shape: buttons),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48), shape: buttons),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(linearTrackColor: Palette.line),
  );
}
