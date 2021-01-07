import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:polaris/shared/dto.dart';
import 'package:polaris/foreground/ui/collection/album_details.dart';
import 'package:polaris/foreground/ui/strings.dart';
import 'package:polaris/foreground/ui/utils/error_message.dart';
import 'package:polaris/foreground/ui/utils/thumbnail.dart';

class GridMetrics {}

const double _detailsSpacing = 8.0;

class AlbumGrid extends StatelessWidget {
  final List<Directory> albums;
  final Future<void> Function() onRefresh;

  AlbumGrid(this.albums, {this.onRefresh, Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (albums.length == 0) {
      return ErrorMessage(emptyAlbumList);
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
            final mainAxisSpacing = 24.0;
            final crossAxisSpacing = 16.0;
            final padding = 24.0;

            final titleStyle = Theme.of(context).textTheme.bodyText1;
            final artistStyle = Theme.of(context).textTheme.caption;
            final titleStrutStyle = StrutStyle(forceStrutHeight: true, fontSize: titleStyle.fontSize);
            final artistStrutStyle = StrutStyle(forceStrutHeight: true, fontSize: artistStyle.fontSize);

            final TextPainter titlePainter = TextPainter(
              maxLines: 1,
              textDirection: TextDirection.ltr,
              text: TextSpan(text: '', style: titleStyle),
              strutStyle: titleStrutStyle,
            )..layout(minWidth: 0, maxWidth: double.infinity);

            final TextPainter artistPainter = TextPainter(
              maxLines: 1,
              textDirection: TextDirection.ltr,
              text: TextSpan(text: '', style: artistStyle),
              strutStyle: artistStrutStyle,
            )..layout(minWidth: 0, maxWidth: double.infinity);

            final titleHeight = titlePainter.size.height;
            final artistHeight = artistPainter.size.height;

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
                return Album(
                  album,
                  titleStyle: titleStyle,
                  artistStyle: artistStyle,
                  titleStrutStyle: titleStrutStyle,
                  artistStrutStyle: artistStrutStyle,
                );
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
  final StrutStyle titleStrutStyle;
  final StrutStyle artistStrutStyle;

  Album(this.album, {this.titleStyle, this.artistStyle, this.titleStrutStyle, this.artistStrutStyle, Key key})
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
          child: Material(
            child: InkWell(
              onTap: action,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(bottom: _detailsSpacing),
                    child: LargeThumbnail(album.artwork),
                  ),
                  Text(
                    album.album ?? unknownAlbum,
                    strutStyle: titleStrutStyle,
                    style: titleStyle,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                  Text(
                    album.artist ?? unknownArtist,
                    strutStyle: artistStrutStyle,
                    style: artistStyle,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}