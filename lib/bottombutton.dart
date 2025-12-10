import 'package:flutter/material.dart';

class MyBottomButton extends StatelessWidget {
  final Color color;
  final Size size;
  final Icon icon;
  const MyBottomButton({super.key, required this.color, required this.size, required this.icon });

  @override
  Widget build(BuildContext context) {
    return Container(
       decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(40),
        ),
        height: size.height,
        width: size.width,
        child: icon,
    );
  }
}