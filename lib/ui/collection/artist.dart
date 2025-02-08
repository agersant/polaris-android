import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/collection/genre_badge.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

enum ArtistTab {
  mainReleases,
  otherReleases,
  genres,
}

class Artist extends StatefulWidget {
  final String artistName;

  const Artist(this.artistName, {Key? key}) : super(key: key);

  @override
  State<Artist> createState() => _ArtistState();
}

class _ArtistState extends State<Artist> with TickerProviderStateMixin {
  late TabController _tabController;
  dto.Artist? _artist;
  APIError? _error;

  @override
  void initState() {
    _tabController = TabController(vsync: this, length: 0);
    super.initState();
    fetchArtist();
  }

  @override
  void didUpdateWidget(Artist oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artistName != widget.artistName) {
      fetchArtist();
    }
  }

  void fetchArtist() async {
    final client = getIt<AppClient>();
    setState(() {
      _artist = null;
      _error = null;
      _tabController = TabController(vsync: this, length: 0);
    });
    try {
      final artist = await client.apiClient?.getArtist(widget.artistName);
      setState(() {
        _artist = artist;
        _tabController = TabController(vsync: this, length: getApplicableTabs().length);
      });
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  (List<dto.ArtistAlbum>, List<dto.ArtistAlbum>) _splitReleases(List<dto.ArtistAlbum> allReleases) {
    final List<dto.ArtistAlbum> mainReleases = [];
    final List<dto.ArtistAlbum> otherReleases = [];
    for (final release in allReleases) {
      final isMainArtist = release.mainArtists.contains(widget.artistName);
      final numContributions = release.contributions.where((c) => c.composer || c.lyricist || c.performer).length;
      final isMajorContributor = numContributions >= release.contributions.length / 2;
      if (isMainArtist || isMajorContributor) {
        mainReleases.add(release);
      } else {
        otherReleases.add(release);
      }
    }
    return (mainReleases, otherReleases);
  }

  Future<List<String>> listSongs(List<dto.ArtistAlbum> albums) async {
    final client = getIt<AppClient>().apiClient!;
    final songsByAlbum = await Future.wait(
        albums.map((a) => client.getAlbum(a.name, a.mainArtists).then((a) => a.songs.map((s) => s.path))));
    return songsByAlbum.expand((i) => i).toList();
  }

  void playAlbums(List<dto.ArtistAlbum> albums) async {
    final songs = await listSongs(albums);
    final playlist = getIt<Playlist>();
    await playlist.clear();
    await playlist.queueLast(songs);
  }

  void queueAlbums(List<dto.ArtistAlbum> albums) async {
    final songs = await listSongs(albums);
    await getIt<Playlist>().queueLast(songs);
  }

  List<ArtistTab> getApplicableTabs() {
    final artist = _artist;
    if (artist == null) {
      return [];
    }
    final (mainReleases, otherReleases) = _splitReleases(artist.albums);
    return [
      if (mainReleases.isNotEmpty) ArtistTab.mainReleases,
      if (otherReleases.isNotEmpty) ArtistTab.otherReleases,
      if (artist.numSongsByGenre.isNotEmpty) ArtistTab.genres,
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.artistName),
        bottom: TabBar(
          tabs: getApplicableTabs()
              .map((t) => Tab(
                      text: switch (t) {
                    ArtistTab.mainReleases => artistMainAlbums,
                    ArtistTab.otherReleases => artistOtherAlbums,
                    ArtistTab.genres => artistGenres,
                  }
                          .toUpperCase()))
              .toList(),
          controller: _tabController,
        ),
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return ErrorMessage(
        artistError,
        action: fetchArtist,
        actionLabel: retryButtonLabel,
      );
    }

    final artist = _artist;
    if (artist == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final (mainReleases, otherReleases) = _splitReleases(artist.albums);

    return TabBarView(
      controller: _tabController,
      children: getApplicableTabs()
          .map((t) => switch (t) {
                ArtistTab.mainReleases => buildAlbumSection(mainReleases, isMainAlbums: true),
                ArtistTab.otherReleases => buildAlbumSection(otherReleases, isMainAlbums: false),
                ArtistTab.genres => buildGenreSection(artist.numSongsByGenre),
              })
          .toList(),
    );
  }

  Widget buildAlbumSection(List<dto.ArtistAlbum> albums, {required bool isMainAlbums}) {
    final showArtistNames = !isMainAlbums;
    final showReleaseDates = isMainAlbums;

    return OrientationBuilder(builder: (context, orientation) {
      return SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        padding: const EdgeInsets.all(24),
        child: Column(
          spacing: 24,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  onPressed: () => playAlbums(albums),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(playAllButtonLabel.toUpperCase()),
                ),
                OutlinedButton.icon(
                  onPressed: () => queueAlbums(albums),
                  icon: const Icon(Icons.playlist_add),
                  label: Text(queueAllButtonLabel.toUpperCase()),
                ),
              ],
            ),
            AlbumGrid(
              albums,
              null,
              shrinkWrap: true,
              orientation: orientation,
              showArtistNames: showArtistNames,
              showReleaseDates: showReleaseDates,
            ),
          ],
        ),
      );
    });
  }

  Widget buildGenreSection(Map<String, int> genres) {
    final genreNames = genres.keys.toList();
    genreNames.sort((a, b) => -genres[a]!.compareTo(genres[b]!));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 24),
      child: Wrap(
        spacing: 8,
        runSpacing: -4,
        children: genreNames.map((genre) => GenreBadge(genre)).toList(),
      ),
    );
  }
}
