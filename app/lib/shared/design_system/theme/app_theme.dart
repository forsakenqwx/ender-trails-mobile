import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Тема приложения.
///
/// Ключевые решения:
/// - Splash/ripple отключены: вместо них блок «вспыхивает» (см. [BlockButton]);
/// - шрифт по умолчанию **не** задаём — Material-текст остаётся системным sans,
///   а пиксельный шрифт подключается точечно через [AppTypography]. Иначе ломается
///   читаемость длинных текстов (docs/design-system.md §7).
abstract final class AppTheme {
  static ThemeData dark() {
    const base = ColorScheme.dark(
      primary: AppColors.mcEnder,
      onPrimary: AppColors.mcText,
      secondary: AppColors.mcPearl,
      surface: AppColors.mcStone,
      onSurface: AppColors.mcText,
      error: AppColors.mcRedstone,
      onError: AppColors.mcText,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: base,
      scaffoldBackgroundColor: AppColors.mcVoid,
      canvasColor: AppColors.mcVoid,
      disabledColor: AppColors.mcTextDim,

      // Пиксельный стиль не терпит размытых ripple
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,

      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.mcDeepslate,
        foregroundColor: AppColors.mcText,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0x14FFFFFF),
        thickness: 1,
        space: 1,
      ),

      // Премиальные скругления в стиле Apple (squircles)
      cardTheme: CardThemeData(
        color: AppColors.mcStone,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: ListTileThemeData(
        textColor: AppColors.mcText,
        iconColor: AppColors.mcText,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.mcStone,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.mcStone,
        contentTextStyle: const TextStyle(color: AppColors.mcText),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.mcDeepslate,
        modalBackgroundColor: AppColors.mcDeepslate,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );
  }
}
