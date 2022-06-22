import 'dart:math' as math;
import 'package:flutter/material.dart';

class FallbackArtwork extends StatelessWidget {
  const FallbackArtwork({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final fillColor = Theme.of(context).dividerColor;
    final iconColor = Theme.of(context).scaffoldBackgroundColor;
    return CustomPaint(painter: FallbackArtworkPainter(backgroundColor, fillColor, iconColor));
  }
}

class FallbackArtworkPainter extends CustomPainter {
  final Color backgroundColor;
  final Color fillColor;
  final Color iconColor;

  FallbackArtworkPainter(this.backgroundColor, this.fillColor, this.iconColor);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final double iconRadius = math.min(24.0, math.min(w, h) / 2 - 8.0);
    final bool drawIcon = iconRadius > 4.0;

    // Draw background
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), backgroundPaint);

    // Draw fill
    {
      final fillPaint = Paint()..color = fillColor;
      canvas.save();
      canvas.drawRect(Rect.fromLTWH(0, 0, w, h), fillPaint);
      canvas.restore();
    }

    // Draw error icon
    if (drawIcon) {
      const IconData icon = Icons.error;
      final TextSpan span = TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, fontSize: 2 * iconRadius, color: iconColor));
      final TextPainter textPainter =
          TextPainter(text: span, textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
      textPainter.paint(canvas, Offset((w - textPainter.size.width) / 2, (h - textPainter.size.height) / 2));
    }
  }

  @override
  bool shouldRepaint(FallbackArtworkPainter oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor ||
        fillColor != oldDelegate.fillColor ||
        iconColor != oldDelegate.iconColor;
  }
}
