import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/collection/album_widget.dart';
import 'package:polaris/ui/collection/genre_badge.dart';
import 'package:polaris/ui/pages_model.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';

final getIt = GetIt.instance;

class GenreOverview extends StatefulWidget {
  final String genreName;

  const GenreOverview(this.genreName, {Key? key}) : super(key: key);

  @override
  State<GenreOverview> createState() => _GenreOverviewState();
}

class _GenreOverviewState extends State<GenreOverview> {
  dto.Genre? _genre;
  List<dto.ArtistHeader>? _mainArtists;
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
    final client = getIt<AppClient>().apiClient;
    if (client == null) {
      return;
    }
    setState(() {
      _genre = null;
      _mainArtists = null;
      _error = null;
    });
    try {
      final genre = await client.getGenre(widget.genreName);
      setState(() {
        _genre = genre;
        _mainArtists = genre.mainArtists.where((a) => !isFakeArtist(a.name)).toList();
      });
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
      padding: const EdgeInsets.only(top: 24),
      // Layout tricks to scroll if content doesn't fit, evenly space otherwise:
      // See `Sample code: Using SingleChildScrollView with a Column`
      // from https://api.flutter.dev/flutter/widgets/SingleChildScrollView-class.html
      child: LayoutBuilder(builder: (context, viewportConstraints) {
        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: viewportConstraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (genre.relatedGenres.isNotEmpty) relatedGenres(genre),
                if (_mainArtists?.isNotEmpty == true) mainArtists(_mainArtists!),
                if (genre.recentlyAdded.isNotEmpty) recentlyAdded(genre),
                playButtons(),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget relatedGenres(dto.Genre genre) {
    final pagesModel = getIt<PagesModel>();
    final genreNames = genre.relatedGenres.keys.toList();
    genreNames.sort((a, b) => -genre.relatedGenres[a]!.compareTo(genre.relatedGenres[b]!));

    const rowHeight = 32.0;
    const rowSpacing = 8.0;
    final numRows = genreNames.length > 4 ? 2 : 1;
    final height = rowHeight * numRows + rowSpacing * (numRows - 1);

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(genreRelated),
        SizedBox(
          height: height,
          child: MasonryGridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            crossAxisCount: numRows,
            crossAxisSpacing: rowSpacing,
            mainAxisSpacing: 8,
            scrollDirection: Axis.horizontal,
            itemCount: genreNames.length,
            itemBuilder: (context, index) => GenreBadge(
              genreNames[index],
              onTap: () => pagesModel.openGenrePage(genreNames[index]),
            ),
          ),
        ),
      ],
    );
  }

  Widget mainArtists(List<dto.ArtistHeader> mainArtists) {
    final numRows = mainArtists.length > 4 ? 2 : 1;

    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(genreMainArtists),
        SizedBox(
          height: 72.0 * numRows,
          child: MasonryGridView.count(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            scrollDirection: Axis.horizontal,
            crossAxisCount: numRows,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            itemCount: mainArtists.length,
            itemBuilder: (context, index) => artistWidget(mainArtists[index]),
          ),
        )
      ],
    );
  }

  Widget artistWidget(dto.ArtistHeader artist) {
    final pagesModel = getIt<PagesModel>();
    final textTheme = Theme.of(context).textTheme;

    return OutlinedButton(
      onPressed: () => pagesModel.openArtistPage(artist.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          spacing: 20,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).textTheme.labelSmall?.color?.withValues(alpha: 0.1),
              ),
              child: Icon(Icons.person, color: textTheme.bodySmall?.color),
            ),
            Column(
              spacing: 4,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(artist.name, style: textTheme.titleMedium?.copyWith(fontSize: 13.0)),
                Text(nSongs(artist.numSongsByGenre[widget.genreName] ?? 0),
                    style: textTheme.bodyMedium?.copyWith(color: textTheme.bodySmall?.color, fontSize: 12.0)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget recentlyAdded(dto.Genre genre) {
    const double albumSize = 150;
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        sectionTitle(genreRecentlyAdded),
        SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
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

  Widget sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.titleSmall,
      ),
    );
  }

  Widget playButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            onPressed: playAll,
            label: Text(playAllButtonLabel.toUpperCase()),
            icon: const Icon(Icons.play_arrow),
          ),
          OutlinedButton.icon(
            onPressed: queueAll,
            label: Text(queueAllButtonLabel.toUpperCase()),
            icon: const Icon(Icons.playlist_add),
          ),
        ],
      ),
    );
  }

  void playAll() async {
    final songs = await listSongs();
    final playlist = getIt<Playlist>();
    await playlist.clear();
    await playlist.queueLast(songs);
  }

  void queueAll() async {
    final songs = await listSongs();
    await getIt<Playlist>().queueLast(songs);
  }

  Future<List<String>> listSongs() async {
    final client = getIt<AppClient>().apiClient!;
    final songList = await client.getGenreSongs(widget.genreName);
    return songList.paths;
  }
}
