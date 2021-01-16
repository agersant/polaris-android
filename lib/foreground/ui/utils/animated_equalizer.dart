import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class AnimatedEqualizer extends StatefulWidget {
  final Color color;
  final Size size;
  final bool isPlaying;

  AnimatedEqualizer(this.color, this.size, this.isPlaying)
      : assert(color != null),
        assert(size != null),
        assert(isPlaying != null);

  @override
  _AnimatedEqualizerState createState() => _AnimatedEqualizerState();
}

class _AnimatedEqualizerState extends State<AnimatedEqualizer> with SingleTickerProviderStateMixin {
  Animation<double> animation;
  AnimationController controller;
  Tween<double> t = Tween(begin: 0, end: 2 * pi);

  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(seconds: 1),
    );

    animation = t.animate(controller)
      ..addListener(() {
        setState(() {});
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          controller.repeat();
        }
      });

    controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying) {
      controller.forward();
    } else {
      controller.stop();
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size.width,
      height: widget.size.height,
      child: CustomPaint(painter: AnimatedEqualizerPainter(widget.color, animation.value)),
    );
  }
}

class AnimatedEqualizerPainter extends CustomPainter {
  final Color color;
  final double t;

  AnimatedEqualizerPainter(this.color, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final double gutterSize = 1;
    final double numBars = 4;
    final double barWidth = (size.width - max(0, (numBars - 1)) * gutterSize) / numBars;
    final Paint paint = Paint()..color = color;

    for (var i = 0; i < numBars; i++) {
      final o = 2 * i / numBars;
      final s1 = 0.75 + sin(1.0 * t + 1 * o) / 4;
      final s2 = 0.75 + sin(2.5 * t + 2 * o) / 4;
      final s3 = 0.75 + sin(3.5 * t + 3 * o) / 4;
      final h = s1 * s2 * s3;
      final left = i * (barWidth + gutterSize);
      final top = size.height * (1 - h);
      canvas.drawRect(Rect.fromLTWH(left, top, barWidth, h * size.height), paint);
    }
  }

  @override
  bool shouldRepaint(AnimatedEqualizerPainter oldDelegate) {
    return true;
  }
}