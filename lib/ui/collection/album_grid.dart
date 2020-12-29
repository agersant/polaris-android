import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/collection/album_details.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

class GridMetrics {}

const double _detailsSpacing = 8.0;

class AlbumGrid extends StatelessWidget {
  final List<Directory> albums;
  final Future<void> Function() onRefresh;

  AlbumGrid(this.albums, {this.onRefresh, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    assert(albums.length > 0); // TODO handle empty album list

    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final titleStyle = Theme.of(context).textTheme.bodyText1;
            final artistStyle = Theme.of(context).textTheme.caption;

            final screenWidth = constraints.maxWidth;
            final crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
            final mainAxisSpacing = 24.0;
            final crossAxisSpacing = 16.0;
            final padding = 24.0;

            final TextPainter titlePainter =
                TextPainter(text: TextSpan(text: '', style: titleStyle), maxLines: 1, textDirection: TextDirection.ltr)
                  ..layout(minWidth: 0, maxWidth: double.infinity);
            final TextPainter artistPainter =
                TextPainter(text: TextSpan(text: '', style: artistStyle), maxLines: 1, textDirection: TextDirection.ltr)
                  ..layout(minWidth: 0, maxWidth: double.infinity);

            final titleHeight = titlePainter.size.height;
            final artistHeight = artistPainter.size.height;
            // TODO the heights above are incorrect for some items
            // eg. KI SE KI by Be For U

            final childWidth =
                ((screenWidth - 2 * padding) - max(0, crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
            final childHeight = childWidth + _detailsSpacing + titleHeight + artistHeight;
            final childAspectRatio = childWidth / childHeight;

            final gridView = GridView.count(
              physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              crossAxisCount: crossAxisCount,
              padding: EdgeInsets.all(padding),
              mainAxisSpacing: mainAxisSpacing,
              crossAxisSpacing: crossAxisSpacing,
              childAspectRatio: childAspectRatio,
              children: albums.map((album) {
                return Album(album, titleStyle: titleStyle, artistStyle: artistStyle);
              }).toList(),
            );

            if (onRefresh == null) {
              return gridView;
            } else {
              // TODO add some refresh functionality at the bottom?
              return RefreshIndicator(
                onRefresh: onRefresh,
                child: gridView,
              );
            }
          },
        );
      },
    );
  }
}

class Album extends StatelessWidget {
  final Directory album;
  final TextStyle titleStyle;
  final TextStyle artistStyle;

  Album(this.album, {this.titleStyle, this.artistStyle, Key key})
      : assert(titleStyle != null),
        assert(artistStyle != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    return OpenContainer(
      closedElevation: 0,
      useRootNavigator: true,
      transitionType: ContainerTransitionType.fade,
      closedColor: Theme.of(context).scaffoldBackgroundColor,
      openColor: Theme.of(context).scaffoldBackgroundColor,
      openBuilder: (context, action) {
        return AlbumDetails(album);
      },
      closedBuilder: (context, action) {
        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: _detailsSpacing),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: GestureDetector(child: Thumbnail(album.artwork)),
                  ),
                ),
              ),
              DefaultTextStyle(
                style: titleStyle,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: Text(album.album ?? unknownAlbum),
              ),
              DefaultTextStyle(
                style: artistStyle,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: Text(album.artist ?? unknownArtist),
              ),
            ],
          ),
        );
      },
    );
  }
}
