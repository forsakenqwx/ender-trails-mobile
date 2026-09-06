import 'package:flutter/material.dart';

/// Элегантный круглый светодиодный индикатор статуса в стиле Apple.
class RedstoneLamp extends StatelessWidget {
  const RedstoneLamp({
    super.key,
    required this.color,
    this.size = 12,
    this.lit = true,
  });

  final Color color;
  final double size;
  final bool lit;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: lit ? color : const Color(0x33FFFFFF),
        boxShadow: lit
            ? [
                BoxShadow(
                  color: color.withOpacity(0.65),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ]
            : [],
      ),
    );
  }
}
