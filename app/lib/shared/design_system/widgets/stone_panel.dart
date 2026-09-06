import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'block_box.dart';

/// Панель-«камень»: карточка, в которую складывается контент.
class StonePanel extends StatelessWidget {
  const StonePanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.fill = AppColors.mcStone,
    this.width,
    this.borderRadius,
  });

  final Widget child;
  final EdgeInsets padding;
  final Color fill;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) => BlockBox(
        width: width,
        fill: fill,
        padding: padding,
        borderRadius: borderRadius ?? BorderRadius.circular(22),
        child: child,
      );
}
