import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/format.dart';

final getIt = GetIt.instance;

class ArtistLinks extends StatelessWidget {
  final List<String> artists;
  final TextStyle? style;

  const ArtistLinks(
    this.artists, {
    this.style,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (artists.isEmpty) {
      return const Text(unknownArtist);
    }

    final defaultStyle =
        style ?? Theme.of(context).textTheme.bodyMedium!.copyWith(color: Theme.of(context).textTheme.bodySmall!.color);
    final tappableStyle = defaultStyle.copyWith(
      color: Theme.of(context).colorScheme.primary,
      decoration: TextDecoration.underline,
    );

    final pagesModel = getIt<PagesModel>();
    return RichText(
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      text: TextSpan(
        style: defaultStyle,
        children: artists
            .map((artist) => TextSpan(
                  text: artist,
                  style: isFakeArtist(artist) ? null : tappableStyle,
                  recognizer: isFakeArtist(artist)
                      ? null
                      : (TapGestureRecognizer()
                        ..onTap = () {
                          pagesModel.openArtistPage(artist);
                        }),
                ))
            .expand((span) => [span, const TextSpan(text: ', ')])
            .toList()
          ..removeLast(),
      ),
    );
  }
}
