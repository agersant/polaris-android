import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class Artist extends StatefulWidget {
  final String artistName;

  const Artist(this.artistName, {Key? key}) : super(key: key);

  @override
  State<Artist> createState() => _ArtistState();
}

class _ArtistState extends State<Artist> {
  dto.Artist? _artist;
  APIError? _error;

  @override
  void initState() {
    super.initState();
    fetchArtist();
  }

  void fetchArtist() async {
    final client = getIt<AppClient>();
    setState(() {
      _artist = null;
      _error = null;
    });
    try {
      final artist = await client.apiClient?.getArtist(widget.artistName);
      setState(() => _artist = artist);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.artistName)),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        child: Column(
          spacing: 16,
          children: [
            // TODO v8 add genres
            if (mainReleases.isNotEmpty) buildAlbumSection(mainAlbumsSectionTitle, mainReleases),
            if (otherReleases.isNotEmpty) buildAlbumSection(otherAlbumsSectionTitle, otherReleases),
          ],
        ),
      ),
    );
  }

  Widget buildAlbumSection(String title, List<dto.ArtistAlbum> albums) {
    return Builder(builder: (context) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title.toUpperCase(),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Row(
                spacing: 16,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => playAlbums(albums),
                    icon: const Icon(Icons.play_arrow),
                    label: Text(playButtonLabel.toUpperCase()),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => queueAlbums(albums),
                    icon: const Icon(Icons.playlist_add),
                    label: Text(queueButtonLabel.toUpperCase()),
                  ),
                ],
              ),
            ],
          ),
          // TODO v8 show year instead of artists for main releases
          // TODO v8 landscape mode should switch to 4 columns
          AlbumGrid(albums, null),
        ],
      );
    });
  }
}
