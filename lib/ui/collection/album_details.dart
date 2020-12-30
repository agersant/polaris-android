import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart' as dto;
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/utils/format.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class AlbumDetails extends StatefulWidget {
  final dto.Directory album;

  AlbumDetails(this.album, {Key key}) : super(key: key);

  @override
  _AlbumDetailsState createState() => _AlbumDetailsState();
}

class _AlbumDetailsState extends State<AlbumDetails> {
  List<dto.Song> _songs;

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
    });

    final api = getIt<API>();
    // TODO error handling
    final content = await api.browse(widget.album.path);
    final songs = content.where((f) => f.isSong()).map((f) => f.asSong()).toList();

    setState(() {
      _songs = songs;
    });
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

  @override
  Widget build(BuildContext context) {
    // TODO landscape mode

    var slivers = <Widget>[];

    // App bar
    slivers.add(SliverAppBar(
      stretch: true,
      expandedHeight: 128,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: <StretchMode>[
          StretchMode.zoomBackground,
          StretchMode.fadeTitle,
        ],
        background: Thumbnail(widget.album.artwork),
      ),
    ));

    // TODO loading spinner
    // TODO handle zero songs
    // TODO animate in

    // Header
    slivers.add(SliverList(
      delegate: SliverChildListDelegate([
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
      ]),
    ));

    // Content
    if (_songs != null) {
      final discs = _splitIntoDiscs(_songs);
      for (var disc in discs) {
        slivers.add(SliverList(
          delegate: SliverChildListDelegate([
            Disc(
              disc,
              discCount: discs.length,
              albumArtwork: widget.album.artwork,
            )
          ]),
        ));
      }
    }

    return Scaffold(
      body: CustomScrollView(
        physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: slivers,
      ),
    );
  }
}

class DiscData {
  final int discNumber;
  final List<dto.Song> songs;
  DiscData(this.discNumber, this.songs) : assert(songs != null);
}

class Disc extends StatelessWidget {
  final DiscData discData;
  final int discCount;
  final String albumArtwork;

  Disc(this.discData, {this.discCount, this.albumArtwork, Key key})
      : assert(discData != null),
        assert(discCount != null),
        super(key: key);

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
              Divider(),
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
  final String albumArtwork;
  final dto.Song song;

  Song(this.song, this.albumArtwork, {Key key})
      : assert(song != null),
        super(key: key);

  String getSubtitle() {
    final artist = song.formatArtist();
    List<String> components = [artist];
    if (song.duration != null) {
      components.add(formatDuration(Duration(seconds: song.duration)));
    }
    return components.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ListThumbnail(albumArtwork ?? song.artwork),
      title: Text(song.formatTrackNumberAndTitle(), overflow: TextOverflow.ellipsis),
      subtitle: Text(getSubtitle(), overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert),
      dense: true,
    );
  }
}
