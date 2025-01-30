import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/ui/collection/genre_badge.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/artist_links.dart';
import 'package:polaris/ui/utils/context_menu.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class AlbumDetails extends StatefulWidget {
  final dto.AlbumHeader albumHeader;

  const AlbumDetails(this.albumHeader, {Key? key}) : super(key: key);

  @override
  State<AlbumDetails> createState() => _AlbumDetailsState();
}

class _AlbumDetailsState extends State<AlbumDetails> {
  dto.Album? _album;
  APIError? _error;

  @override
  initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(AlbumDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.albumHeader.name != widget.albumHeader.name ||
        !listEquals(oldWidget.albumHeader.mainArtists, widget.albumHeader.mainArtists)) {
      _fetchData();
    }
  }

  void _fetchData({bool useCache = true}) async {
    setState(() {
      _album = null;
      _error = null;
    });
    try {
      final client = getIt<AppClient>();
      final album = await client.apiClient?.getAlbum(widget.albumHeader.name, widget.albumHeader.mainArtists);
      setState(() => _album = album);
    } on APIError catch (e) {
      setState(() => _error = e);
    }
  }

  List<DiscData> _splitIntoDiscs(List<dto.Song> songs) {
    return songs.fold(<DiscData>[], (discs, song) {
      if (discs.isEmpty || discs.last.discNumber != song.discNumber) {
        discs.add(DiscData(song.discNumber, []));
      }
      discs.last.songs.add(song);
      return discs;
    });
  }

  List<String> _getGenres() {
    final songs = _album?.songs;
    if (songs == null) {
      return [];
    }
    final Map<String, int> counts = {};
    for (final song in songs) {
      for (final genre in song.genres) {
        counts.putIfAbsent(genre, () => 0);
        counts[genre] = counts[genre]! + 1;
      }
    }
    final names = counts.keys.toList();
    names.sort((a, b) => -(counts[a] ?? 0).compareTo(counts[b] ?? 0));
    return names;
  }

  Widget _getGenresWidget(List<String> genres) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      physics: const BouncingScrollPhysics(),
      child: Row(
        spacing: 8,
        children: genres.map((g) => GenreBadge(g)).toList(),
      ),
    );
  }

  List<Widget> _getMainContent() {
    List<dto.Song>? songs = _album?.songs;
    if (_error != null || songs == null) {
      return [
        Padding(
            padding: const EdgeInsets.only(top: 64),
            child: ErrorMessage(
              albumDetailsError,
              action: _fetchData,
              actionLabel: retryButtonLabel,
            ))
      ];
    }

    final discs = _splitIntoDiscs(songs);
    if (discs.isEmpty) {
      return [
        Padding(
            padding: const EdgeInsets.only(top: 64),
            child: ErrorMessage(
              emptyAlbum,
              actionLabel: goBackButtonLabel,
              action: () => Navigator.pop(context),
            ))
      ];
    }

    return discs
        .map((discData) => Disc(
              discData,
              discCount: discs.length,
              albumArtwork: widget.albumHeader.artwork,
            ))
        .toList();
  }

  Widget _getPortraitLayout() {
    final genres = _getGenres();
    var slivers = <Widget>[];

    slivers.add(SliverAppBar(
      stretch: true,
      expandedHeight: 128,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const <StretchMode>[
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Thumbnail(widget.albumHeader.artwork, ArtworkSize.small),
      ),
    ));

    slivers.add(
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.albumHeader.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                            softWrap: true,
                          ),
                        ),
                        AlbumContextMenuButton(
                          name: widget.albumHeader.name,
                          mainArtists: widget.albumHeader.mainArtists,
                          actions: const [
                            AlbumAction.queueLast,
                            AlbumAction.queueNext,
                            AlbumAction.togglePin,
                          ],
                          songs: _album?.songs,
                          icon: Icons.menu,
                        ),
                      ],
                    ),
                  ),
                  if (genres.isNotEmpty) _getGenresWidget(genres),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ArtistLinks(widget.albumHeader.mainArtists),
                  Text(
                    widget.albumHeader.year?.toString() ?? '',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (_album == null && _error == null) {
      slivers.add(const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ));
    } else {
      slivers.add(SliverList(delegate: SliverChildListDelegate(_getMainContent())));
    }

    return Scaffold(
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: slivers,
      ),
    );
  }

  Widget _getLandscapeLayout() {
    final Widget leftColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: LargeThumbnail(widget.albumHeader.artwork),
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.albumHeader.name,
                    style: Theme.of(context).textTheme.bodyLarge,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  ArtistLinks(widget.albumHeader.mainArtists),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: AlbumContextMenuButton(
                name: widget.albumHeader.name,
                mainArtists: widget.albumHeader.mainArtists,
                actions: const [
                  AlbumAction.queueLast,
                  AlbumAction.queueNext,
                  AlbumAction.togglePin,
                ],
                songs: _album?.songs,
                icon: Icons.menu,
              ),
            ),
          ],
        ),
      ],
    );

    final genres = _getGenres();
    Widget rightColumn;
    if (_album == null && _error == null) {
      rightColumn = const Center(child: CircularProgressIndicator());
    } else {
      rightColumn = Padding(
        padding: const EdgeInsets.only(left: 24),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: [
            if (genres.isNotEmpty) _getGenresWidget(genres),
            ..._getMainContent(),
          ],
        ),
      );
    }

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 0, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 20, child: leftColumn),
          Expanded(flex: 80, child: rightColumn),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(widget.albumHeader.name)),
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) {
        if (orientation == Orientation.portrait) {
          return _getPortraitLayout();
        } else {
          return _getLandscapeLayout();
        }
      },
    );
  }
}

class DiscData {
  final int? discNumber;
  final List<dto.Song> songs;
  DiscData(this.discNumber, this.songs);
}

class Disc extends StatelessWidget {
  final DiscData discData;
  final int discCount;
  final String? albumArtwork;

  const Disc(this.discData, {required this.discCount, this.albumArtwork, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[];

    if (discCount > 1) {
      final discNumberLabel = discData.discNumber?.toString() ?? '?';
      final isFirstDisc = discData.discNumber == 1;
      children.add(
        Padding(
          padding: EdgeInsets.fromLTRB(16, isFirstDisc ? 8 : 24, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Disc $discNumberLabel',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const Divider(),
            ],
          ),
        ),
      );
    }

    children.addAll(discData.songs.map((song) => Song(song, albumArtwork)));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class Song extends StatelessWidget {
  final String? albumArtwork;
  final dto.Song song;

  const Song(this.song, this.albumArtwork, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () => getIt<Playlist>().queueLast([song.path]),
        child: ListTile(
          leading: ListThumbnail(albumArtwork ?? song.artwork),
          title: Text(song.formatTrackNumberAndTitle(), overflow: TextOverflow.ellipsis),
          subtitle: Text(song.formatArtistsAndDuration(), overflow: TextOverflow.ellipsis),
          trailing: SongContextMenuButton(
            path: song.path,
            actions: const [
              SongAction.queueLast,
              SongAction.queueNext,
              SongAction.togglePin,
              SongAction.songInfo,
            ],
          ),
          dense: true,
        ),
      ),
    );
  }
}
