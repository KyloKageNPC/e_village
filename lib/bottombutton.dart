import 'package:flutter/material.dart';

class MyBottomButton extends StatelessWidget {
  final Color color;
  final Size size;
  final Icon icon;
  const MyBottomButton({super.key, required this.color, required this.size, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            color.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(40),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            offset: Offset(0, 4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.2),
            offset: Offset(-2, -2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      height: size.height,
      width: size.width,
      child: Center(
        child: IconTheme(
          data: IconThemeData(
            color: Colors.white,
            size: icon.size ?? 24,
          ),
          child: icon,
        ),
      ),
    );
  }
}
