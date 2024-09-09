import 'package:flutter/material.dart';

class LanguageSwitcher extends StatelessWidget {
  final Color? iconColor;
  final Color? backgroundColor;
  final double iconSize;
  final double width;
  final double height;
  final double radius;
  final VoidCallback onTap;

  const LanguageSwitcher({
    super.key,
    required this.iconColor,
    required this.backgroundColor,
    this.iconSize = 30,
    this.width = 50,
    this.height = 30,
    this.radius = 10,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: width,
        height: height,
        child: Center(
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Icon(Icons.arrow_left, size: iconSize, color: iconColor),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Icon(Icons.arrow_right, size: iconSize, color: iconColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
