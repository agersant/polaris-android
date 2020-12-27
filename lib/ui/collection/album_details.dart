import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

final getIt = GetIt.instance;

class AlbumDetails extends StatefulWidget {
  final String path;

  AlbumDetails(this.path, {Key key}) : super(key: key);

  @override
  _AlbumDetailsState createState() => _AlbumDetailsState();
}

class _AlbumDetailsState extends State<AlbumDetails> {
  List<Song> _songs;

  Thumbnail _getThumbnail() {
    if (_songs == null || _songs.isEmpty) {
      return null;
    }
    final artworkPath = _songs.firstWhere((song) => song.artwork?.isNotEmpty ?? false).artwork;
    return Thumbnail(artworkPath);
    // final song = this.widget.songs.firstWhere((song) => song.artwork?.isNotEmpty ?? false, orElse: () => null);
    // return song?.artwork;
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()), slivers: <Widget>[
        SliverAppBar(
          stretch: true,
          pinned: true,
          expandedHeight: 128,
          flexibleSpace: FlexibleSpaceBar(
            title: Text('TODO TITLE'),
            stretchModes: <StretchMode>[
              StretchMode.zoomBackground,
              StretchMode.fadeTitle,
            ],
            background: _getThumbnail(),
          ),
        ),
        // TODO loading spinner
        if (_songs != null)
          SliverList(
            delegate: SliverChildListDelegate(_songs.map((song) => Text(song.title)).toList()),
          ),
      ]),
    );
  }
}
