import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class AlbumWidget extends StatelessWidget {
  static const double _detailsSpacing = 8.0;

  final dto.AlbumHeader album;
  final bool showArtistNames;
  final bool showReleaseDate;

  const AlbumWidget(
    this.album, {
    required this.showArtistNames,
    required this.showReleaseDate,
    Key? key,
  }) : super(key: key);

  static double computeHeightForWidth(BuildContext context, double width) {
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

    return width + _detailsSpacing + titleHeight + artistHeight;
  }

  @override
  Widget build(BuildContext context) {
    final pagesModel = getIt<PagesModel>();

    final titleStyle = Theme.of(context).textTheme.bodyLarge ?? const TextStyle();
    final artistStyle = Theme.of(context).textTheme.bodySmall ?? const TextStyle();
    final titleStrutStyle = StrutStyle(forceStrutHeight: true, fontSize: titleStyle.fontSize);
    final artistStrutStyle = StrutStyle(forceStrutHeight: true, fontSize: artistStyle.fontSize);

    final contextMenuButton = AlbumContextMenuButton(
      name: album.name,
      mainArtists: album.mainArtists,
      actions: const [
        AlbumAction.queueLast,
        AlbumAction.queueNext,
        AlbumAction.togglePin,
      ],
      compact: true,
    );

    return Align(
      alignment: Alignment.topCenter,
      child: Material(
        child: InkWell(
          onTap: () => pagesModel.openAlbumPage(album),
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
                  contextMenuButton
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
