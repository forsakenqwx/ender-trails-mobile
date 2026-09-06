import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Элегантный индикатор загрузки в стиле Apple.
class FurnaceLoader extends StatelessWidget {
  const FurnaceLoader({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading...',
      child: Center(
        child: SizedBox(
          width: size,
          height: size,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.mcEnder),
            backgroundColor: Color(0x22FFFFFF),
          ),
        ),
      ),
    );
  }
}
