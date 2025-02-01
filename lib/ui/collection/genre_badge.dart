import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/pages_model.dart';

final getIt = GetIt.instance;

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
    final pagesModel = getIt<PagesModel>();
    final connectionManager = getIt<connection.Manager>();
    final hasLink = (connectionManager.apiVersion ?? 0) >= 8;

    final accentColor = pickColor(name);
    return OutlinedButton.icon(
      style: const ButtonStyle(visualDensity: VisualDensity.compact),
      onPressed: hasLink ? () => pagesModel.openGenrePage(name) : null,
      icon: Container(
        width: 7,
        height: 7,
        decoration: BoxDecoration(color: accentColor, shape: BoxShape.circle),
      ),
      label: Text(
        name,
        style: Theme.of(context).textTheme.bodyMedium,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
