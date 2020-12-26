import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polaris/platform/dto.dart';

class GridMetrics {}

class AlbumGrid extends StatelessWidget {
  final List<Directory> _albums;

  AlbumGrid(this._albums);

  Widget _buildAlbumTile(Directory album, titleStyle, artistStyle) {
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Image.network(
              'https://f4.bcbits.com/img/a0959935152_16.jpg', // TMP
              fit: BoxFit.cover,
            ),
          ),
          DefaultTextStyle(
            style: titleStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: Text(album.album),
          ),
          DefaultTextStyle(
            style: artistStyle,
            softWrap: false,
            overflow: TextOverflow.ellipsis,
            child: Text(album.artist),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(_albums.length > 0); // TODO handle

    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final titleStyle = Theme.of(context).textTheme.subtitle1;
            final artistStyle = Theme.of(context).textTheme.subtitle2;

            final screenWidth = constraints.maxWidth;
            final crossAxisCount = 2; // TODO landscape mode
            final crossAxisSpacing = 16.0; // TODO landscape mode
            final padding = 16.0; // TODO landscape mode

            final TextPainter titlePainter =
                TextPainter(text: TextSpan(text: '', style: titleStyle), maxLines: 1, textDirection: TextDirection.ltr)
                  ..layout(minWidth: 0, maxWidth: double.infinity);
            final TextPainter artistPainter =
                TextPainter(text: TextSpan(text: '', style: artistStyle), maxLines: 1, textDirection: TextDirection.ltr)
                  ..layout(minWidth: 0, maxWidth: double.infinity);

            final titleHeight = titlePainter.size.height;
            final artistHeight = artistPainter.size.height;

            final childWidth =
                ((screenWidth - 2 * padding) - max(0, crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
            final childHeight = childWidth + titleHeight + artistHeight;
            final childAspectRatio = childWidth / childHeight;

            return GridView.count(
              crossAxisCount: crossAxisCount,
              padding: EdgeInsets.all(padding),
              mainAxisSpacing: 24.0,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
              children: _albums.map((album) => _buildAlbumTile(album, titleStyle, artistStyle)).toList(),
            );
          },
        );
      },
    );
  }
}
