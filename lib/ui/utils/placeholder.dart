import 'package:flutter/material.dart';

class Placeholder extends StatelessWidget {
  final double width;
  final double height;
  final Color color;

  const Placeholder({
    Key? key,
    required this.width,
    required this.height,
    required this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        color: color,
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
    );
  }
}
