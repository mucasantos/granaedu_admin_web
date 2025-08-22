import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({Key? key, this.height, this.width, required this.imageString}) : super(key: key);

  final double? height;
  final double? width;
  final String imageString;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      imageString,
      height: height ?? 60,
      width: width ?? 140,
    );
  }
}
