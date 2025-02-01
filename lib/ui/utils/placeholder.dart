import 'package:flutter/material.dart';

class Placeholder extends StatelessWidget {
  final double width;
  final double height;

  const Placeholder({
    Key? key,
    required this.width,
    required this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.all(Radius.circular(6.0)),
      ),
    );
  }
}
