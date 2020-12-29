import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class FallbackArtwork extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final stripeColor = Theme.of(context).dividerColor;
    final iconColor = Theme.of(context).dividerColor;
    return CustomPaint(painter: FallbackArtworkPainter(backgroundColor, stripeColor, iconColor));
  }
}

class FallbackArtworkPainter extends CustomPainter {
  final Color backgroundColor;
  final Color stripeColor;
  final Color iconColor;

  FallbackArtworkPainter(this.backgroundColor, this.stripeColor, this.iconColor);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double thickness = math.min(8.0, math.min(w, h) / 8);
    final double thickness2 = 2.0 * thickness;
    final double s2 = 1 / h * math.max(w, h) * math.sqrt(2);

    final double iconRadius = 24.0;
    final bool drawIcon = math.min(w, h) > (iconRadius * 2 + 16.0);

    final Path rectPath = Path()..addRect(Rect.fromLTWH(0, 0, w, h));
    final Path circlePath = Path()..addOval(Rect.fromCircle(radius: iconRadius, center: Offset(w / 2, h / 2)));
    final Path clipPath = Path.combine(PathOperation.difference, rectPath, circlePath);

    // Draw background
    final Paint backgroundPaint = Paint()..color = backgroundColor;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), backgroundPaint);

    // Draw stripes
    {
      canvas.save();

      if (drawIcon) {
        canvas.clipPath(clipPath);
      }
      canvas.translate(w / 2, h / 2);
      canvas.rotate(45.0 * math.pi / 180.0);

      final stripePaint = Paint()
        ..strokeWidth = thickness
        ..color = stripeColor;

      final xStart = thickness2 * ((-w * s2 / 2) / (thickness2)).floor();
      for (var x = xStart; x < w * s2 / 2; x += thickness2) {
        final p1 = Offset(x, -h * s2 / 2);
        final p2 = Offset(x + thickness, h * s2 / 2);
        canvas.drawLine(p1, p2, stripePaint);
      }

      canvas.restore();
    }

    // Draw error icon
    if (drawIcon) {
      final IconData icon = Icons.error;
      final TextSpan span = new TextSpan(
          text: String.fromCharCode(icon.codePoint),
          style: TextStyle(fontFamily: icon.fontFamily, fontSize: 2 * iconRadius, color: iconColor));
      final TextPainter textPainter =
          new TextPainter(text: span, textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout();
      textPainter.paint(canvas, new Offset((w - textPainter.size.width) / 2, (h - textPainter.size.height) / 2));
    }
  }

  @override
  bool shouldRepaint(FallbackArtworkPainter oldDelegate) {
    return backgroundColor != oldDelegate.backgroundColor ||
        stripeColor != oldDelegate.stripeColor ||
        iconColor != oldDelegate.iconColor;
  }
}
