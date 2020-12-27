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
  final String path;

  AlbumDetails(this.path, {Key key}) : super(key: key);

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
    if (oldWidget.path != widget.path) {
      _fetchData();
    }
  }

  void _fetchData() async {
    setState(() {
      _songs = null;
    });

    final api = getIt<API>();
    // TODO error handling
    final content = await api.browse(widget.path);
    final songs = content.where((f) => f.isSong()).map((f) => f.asSong()).toList();

    setState(() {
      _songs = songs;
    });
  }

  String _getFromAnySong(String Function(dto.Song) prop) {
    if (_songs == null || _songs.isEmpty) {
      return null;
    }
    final song = _songs.firstWhere((s) => prop(s)?.isNotEmpty ?? false, orElse: () => null);
    return song != null ? prop(song) : null;
  }

  Widget _getThumbnail() {
    final artworkPath = _getFromAnySong((s) => s.artwork);
    return artworkPath != null ? Thumbnail(artworkPath) : null;
  }

  String _getAlbumTitle() {
    final title = _getFromAnySong((s) => s.album);
    return title ?? unknownAlbum;
  }

  String _getAlbumArtist() {
    final albumArtist = _getFromAnySong((s) => s.albumArtist);
    final artist = _getFromAnySong((s) => s.artist);
    return albumArtist ?? artist ?? unknownArtist;
  }

  @override
  Widget build(BuildContext context) {
    // TODO back button invisible on light album covers
    return Scaffold(
      body: CustomScrollView(physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), slivers: <Widget>[
        SliverAppBar(
          stretch: true,
          pinned: true, // TODO this looks bad without title when scrolled down
          expandedHeight: 128,
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: <StretchMode>[
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            background: _getThumbnail(),
          ),
        ),
        // TODO loading spinner
        // TODO handle zero songs
        if (_songs != null)
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DefaultTextStyle(style: Theme.of(context).textTheme.headline5, child: Text(_getAlbumTitle())),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(style: Theme.of(context).textTheme.bodyText2, child: Text(_getAlbumArtist())),
                    DefaultTextStyle(style: Theme.of(context).textTheme.caption, child: Text('${_songs.length} songs')),
                  ],
                ),
              ),
            ]),
          ),
        if (_songs != null)
          SliverList(
            delegate: SliverChildListDelegate(_songs.map((song) => Song(song)).toList()),
          ),
      ]),
    );
  }
}

class Song extends StatelessWidget {
  final dto.Song song;

  Song(this.song);

  String getTitle() {
    List<String> components = [];
    if (song.trackNumber != null) {
      components.add('${song.trackNumber}');
    }
    if (song.title != null) {
      components.add(song.title);
    }
    return components.join('. ');
  }

  String getSubtitle() {
    final artist = song.artist ?? song.albumArtist ?? unknownArtist;
    List<String> components = [artist];
    if (song.duration != null) {
      components.add(formatDuration(Duration(seconds: song.duration)));
    }
    return components.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: SizedBox(height: 40, width: 40, child: Thumbnail(song.artwork))),
      title: Text(getTitle(), overflow: TextOverflow.ellipsis),
      subtitle: Text(getSubtitle(), overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert),
    );
  }
}
