import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/ui/collection/album_widget.dart';
import 'package:polaris/ui/collection/genre_badge.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class GenreOverview extends StatefulWidget {
  final String genreName;

  const GenreOverview(this.genreName, {Key? key}) : super(key: key);

  @override
  State<GenreOverview> createState() => _GenreOverviewState();
}

class _GenreOverviewState extends State<GenreOverview> {
  dto.Genre? _genre;
  APIError? _error;

  @override
  void didUpdateWidget(covariant GenreOverview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.genreName != widget.genreName) {
      fetchGenre();
    }
  }

  @override
  void initState() {
    super.initState();
    fetchGenre();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void fetchGenre() async {
    final client = getIt<AppClient>();
    setState(() {
      _genre = null;
      _error = null;
    });
    try {
      final genre = await client.apiClient?.getGenre(widget.genreName);
      setState(() => _genre = genre);
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return ErrorMessage(
        genreError,
        action: fetchGenre,
        actionLabel: retryButtonLabel,
      );
    }

    final genre = _genre;
    if (genre == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 32,
          children: [
            if (genre.relatedGenres.isNotEmpty) _relatedGenres(genre),
            if (genre.mainArtists.isNotEmpty) _mainArtists(genre),
            if (genre.recentlyAdded.isNotEmpty) _recentlyAdded(genre),
          ],
        ),
      ),
    );
  }

  Widget _relatedGenres(dto.Genre genre) {
    final pagesModel = getIt<PagesModel>();
    final genreNames = genre.relatedGenres.keys.toList();
    genreNames.sort((a, b) => -genre.relatedGenres[a]!.compareTo(genre.relatedGenres[b]!));

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          genreRelated.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: genreNames
                .map((name) => GenreBadge(
                      name,
                      onTap: () => pagesModel.openGenrePage(name),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _mainArtists(dto.Genre genre) {
    final pagesModel = getIt<PagesModel>();

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          genreMainArtists.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: genre.mainArtists
                .map((artist) => OutlinedButton(
                      onPressed: () => pagesModel.openArtistPage(artist.name),
                      child: SizedBox(
                        width: 120,
                        child: ListTile(
                          title: Text(artist.name),
                          subtitle: Text(nSongs(artist.numSongsByGenre[genre.name] ?? 0)),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }

  Widget _recentlyAdded(dto.Genre genre) {
    const double albumSize = 150;
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          genreRecentlyAdded.toUpperCase(),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          scrollDirection: Axis.horizontal,
          child: Row(
            spacing: 8,
            children: genre.recentlyAdded
                .map((album) => SizedBox(
                    width: albumSize,
                    height: AlbumWidget.computeHeightForWidth(context, albumSize),
                    child: AlbumWidget(album, showArtistNames: true, showReleaseDate: false)))
                .toList(),
          ),
        ),
      ],
    );
  }
}
