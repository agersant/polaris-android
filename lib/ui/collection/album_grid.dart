import 'dart:math';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/ui/collection/album_details.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class GridMetrics {}

const double _detailsSpacing = 8.0;

class AlbumGrid extends StatelessWidget {
  final List<dto.AlbumHeader> albums;
  final ScrollController? scrollController;
  final bool showArtistNames;
  final bool showReleaseDates;

  const AlbumGrid(
    this.albums,
    this.scrollController, {
    Key? key,
    this.showArtistNames = true,
    this.showReleaseDates = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const ErrorMessage(emptyAlbumList);
    }

    return OrientationBuilder(
      builder: (context, orientation) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final screenWidth = constraints.maxWidth;
            final crossAxisCount = orientation == Orientation.portrait ? 2 : 4;
            const mainAxisSpacing = 24.0;
            const crossAxisSpacing = 16.0;

            final titleStyle = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
            final artistStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
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

            final childWidth = (screenWidth - max(0, crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
            final childHeight = childWidth + _detailsSpacing + titleHeight + artistHeight;
            final childAspectRatio = childWidth / childHeight;

            final gridView = GridView.builder(
              physics: scrollController != null
                  ? const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics())
                  : const NeverScrollableScrollPhysics(),
              shrinkWrap: scrollController == null,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
              ),
              controller: scrollController,
              itemCount: albums.length,
              itemBuilder: (context, index) => Album(
                albums[index],
                titleStyle: titleStyle,
                artistStyle: artistStyle,
                titleStrutStyle: titleStrutStyle,
                artistStrutStyle: artistStrutStyle,
                showArtistNames: showArtistNames,
                showReleaseDate: showReleaseDates,
              ),
            );

            return gridView;
          },
        );
      },
    );
  }
}

class Album extends StatelessWidget {
  final dto.AlbumHeader album;
  final TextStyle titleStyle;
  final TextStyle artistStyle;
  final StrutStyle titleStrutStyle;
  final StrutStyle artistStrutStyle;
  final bool showArtistNames;
  final bool showReleaseDate;

  const Album(this.album,
      {required this.titleStyle,
      required this.artistStyle,
      required this.titleStrutStyle,
      required this.artistStrutStyle,
      required this.showArtistNames,
      required this.showReleaseDate,
      Key? key})
      : super(key: key);

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
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.name,
                              strutStyle: titleStrutStyle,
                              style: titleStyle,
                              overflow: TextOverflow.ellipsis,
                              softWrap: false,
                            ),
                            if (showArtistNames)
                              Text(
                                album.mainArtists.isEmpty ? unknownArtist : album.mainArtists.join(', '),
                                strutStyle: artistStrutStyle,
                                style: artistStyle,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                            if (showReleaseDate && album.year != null)
                              Text(
                                album.year!.toString(),
                                strutStyle: artistStrutStyle,
                                style: artistStyle,
                                overflow: TextOverflow.ellipsis,
                                softWrap: false,
                              ),
                          ],
                        ),
                      ),
                      AlbumContextMenuButton(
                        name: album.name,
                        mainArtists: album.mainArtists,
                        actions: const [
                          AlbumAction.queueLast,
                          AlbumAction.queueNext,
                          AlbumAction.togglePin,
                        ],
                        compact: true,
                      ),
                    ],
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
