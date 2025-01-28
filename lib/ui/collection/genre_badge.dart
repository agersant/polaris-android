import 'package:flutter/material.dart';

class GenreBadge extends StatelessWidget {
  final String name;

  // Tailwind palette
  static const List<Color> palette = [
    Color(0xFFef4444),
    Color(0xFFf97316),
    Color(0xFFf59e0b),
    Color(0xFFeab308),
    Color(0xFF84cc16),
    Color(0xFF22c55e),
    Color(0xFF10b981),
    Color(0xFF14b8a6),
    Color(0xFF06b6d4),
    Color(0xFF0ea5e9),
    Color(0xFF3b82f6),
    Color(0xFF6366f1),
    Color(0xFF8b5cf6),
    Color(0xFFa855f7),
    Color(0xFFd946ef),
    Color(0xFFec4899),
    Color(0xFFf43f5e),
  ];
  static final lut = List.generate(256, (i) => i);

  const GenreBadge(this.name, {Key? key}) : super(key: key);

  static Color pickColor(String s) {
    final initialValue = s.length % (lut.length - 1);
    final hashed = s.codeUnits.fold(initialValue, (int hash, int codeUnit) {
      return lut[(hash + codeUnit) % (lut.length - 1)];
    });
    return palette[hashed % palette.length];
  }

  @override
  Widget build(BuildContext context) {
    final acentColor = pickColor(name);
    final borderColor = Theme.of(context).colorScheme.onSurface.withValues(alpha: .2);

    return Chip(
      padding: EdgeInsets.zero,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 0.5),
        borderRadius: BorderRadius.circular(4),
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        spacing: 8,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: acentColor, shape: BoxShape.circle),
          ),
          Text(name, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}
