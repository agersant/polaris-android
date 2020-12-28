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

  Widget _getThumbnail() {
    final artworkPath = widget.album.artwork;
    return artworkPath != null ? Thumbnail(artworkPath) : null;
  }

  @override
  Widget build(BuildContext context) {
    // TODO landscape mode
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
        // TODO animate in
        if (_songs != null)
          SliverList(
            delegate: SliverChildListDelegate([
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: DefaultTextStyle(
                    style: Theme.of(context).textTheme.headline5, child: Text(widget.album.album ?? unknownAlbum)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DefaultTextStyle(
                        style: Theme.of(context).textTheme.bodyText2,
                        child: Text(widget.album.artist ?? unknownArtist)),
                    DefaultTextStyle(
                        style: Theme.of(context).textTheme.caption, child: Text(widget.album.year?.toString() ?? '')),
                  ],
                ),
              ),
            ]),
          ),
        if (_songs != null)
          SliverList(
            delegate: SliverChildListDelegate(_songs.map((song) => Song(song, widget.album.artwork)).toList()),
          ),
      ]),
    );
  }
}

class Song extends StatelessWidget {
  final String albumArtwork;
  final dto.Song song;

  Song(this.song, this.albumArtwork) : assert(song != null);

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
          child: SizedBox(height: 40, width: 40, child: Thumbnail(albumArtwork ?? song.artwork))),
      title: Text(getTitle(), overflow: TextOverflow.ellipsis),
      subtitle: Text(getSubtitle(), overflow: TextOverflow.ellipsis),
      trailing: Icon(Icons.more_vert),
    );
  }
}
