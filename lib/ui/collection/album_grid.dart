import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/ui/collection/album_widget.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class GridMetrics {}

class AlbumGrid extends StatelessWidget {
  final List<dto.AlbumHeader> albums;
  final ScrollController? scrollController;
  final bool shrinkWrap;
  final Orientation? orientation;
  final bool showArtistNames;
  final bool showReleaseDates;
  final EdgeInsets? padding;

  const AlbumGrid(
    this.albums,
    this.scrollController, {
    required this.shrinkWrap,
    this.orientation,
    this.padding,
    this.showArtistNames = true,
    this.showReleaseDates = false,
    Key? key,
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
            final crossAxisCount = (this.orientation ?? orientation) == Orientation.portrait ? 2 : 4;
            const mainAxisSpacing = 24.0;
            const crossAxisSpacing = 16.0;

            final childWidth = (screenWidth - max(0, crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;
            final childHeight = AlbumWidget.computeHeightForWidth(context, childWidth);
            final childAspectRatio = childWidth / childHeight;

            final gridView = GridView.builder(
              padding: padding,
              physics: shrinkWrap
                  ? const NeverScrollableScrollPhysics()
                  : const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
              shrinkWrap: shrinkWrap,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: mainAxisSpacing,
                crossAxisSpacing: crossAxisSpacing,
              ),
              controller: scrollController,
              itemCount: albums.length,
              itemBuilder: (context, index) => AlbumWidget(
                albums[index],
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
