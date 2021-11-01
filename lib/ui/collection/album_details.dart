import 'package:dartz/dartz.dart' as dartz;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/playlist.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/ui/collection/context_menu.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/error_message.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class AlbumDetails extends StatefulWidget {
  final dto.Directory album;

  const AlbumDetails(this.album, {Key? key}) : super(key: key);

  @override
  _AlbumDetailsState createState() => _AlbumDetailsState();
}

class _AlbumDetailsState extends State<AlbumDetails> {
  List<dto.Song>? _songs;
  polaris.APIError? _error;

  @override
  initState() {
    super.initState();
    _fetchData();
  }

  @override
  void didUpdateWidget(AlbumDetails oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.album.path != widget.album.path) {
      _fetchData();
    }
  }

  void _fetchData() async {
    setState(() {
      _songs = null;
      _error = null;
    });
    try {
      final files = await getIt<polaris.Client>().browse(widget.album.path);
      final songs = files.where((f) => f.isSong()).map((f) => f.asSong()).toList();
      setState(() {
        _songs = songs;
      });
    } on polaris.APIError catch (e) {
      setState(() {
        _error = e;
      });
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

  List<Widget> _getMainContent() {
    List<dto.Song>? songs = _songs;
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
              albumArtwork: widget.album.artwork,
            ))
        .toList();
  }

  Widget _getPortraitLayout() {
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
        background: Thumbnail(widget.album.artwork),
      ),
    ));

    slivers.add(SliverToBoxAdapter(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            widget.album.album ?? unknownAlbum,
            style: Theme.of(context).textTheme.headline5,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.album.artist ?? unknownArtist,
                style: Theme.of(context).textTheme.bodyText2,
              ),
              Text(
                widget.album.year?.toString() ?? '',
                style: Theme.of(context).textTheme.caption,
              ),
            ],
          ),
        ),
      ],
    )));

    if (_songs == null && _error == null) {
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
          child: LargeThumbnail(widget.album.artwork),
        ),
        Text(widget.album.formatName(), style: Theme.of(context).textTheme.bodyText1),
        Text(widget.album.formatArtist(), style: Theme.of(context).textTheme.caption),
      ],
    );

    Widget rightColumn;
    if (_songs == null && _error == null) {
      rightColumn = const Center(child: CircularProgressIndicator());
    } else {
      rightColumn = Padding(
        padding: const EdgeInsets.only(left: 24),
        // TODO ideally this would line up with the artwork on the right,
        // but the top padding built-in the ListTile makes it difficult
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: _getMainContent(),
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
      appBar: AppBar(title: Text(widget.album.formatName())),
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
                style: Theme.of(context).textTheme.bodyText2,
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

  String getSubtitle() {
    final artist = song.formatArtist();
    List<String> components = [artist];
    int? duration = song.duration;
    if (duration != null) {
      components.add(formatDuration(Duration(seconds: duration)));
    }
    return components.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      child: InkWell(
        onTap: () => getIt<Playlist>().queueLast([song]),
        child: ListTile(
          leading: ListThumbnail(albumArtwork ?? song.artwork),
          title: Text(song.formatTrackNumberAndTitle(), overflow: TextOverflow.ellipsis),
          subtitle: Text(getSubtitle(), overflow: TextOverflow.ellipsis),
          trailing: CollectionFileContextMenuButton(file: dto.CollectionFile(dartz.Left(song))),
          dense: true,
        ),
      ),
    );
  }
}
