import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/utils/thumbnail.dart';

class AlbumDetails extends StatelessWidget {
  final List<Song> songs;

  AlbumDetails(this.songs, {Key key}) : super(key: key);

  String getArtworkPath() {
    final song = this.songs.firstWhere((song) => song.artwork?.isNotEmpty ?? false, orElse: () => null);
    return song?.artwork;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(physics: BouncingScrollPhysics(), slivers: <Widget>[
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
            background: Thumbnail(getArtworkPath()),
          ),
        ),
        SliverList(
          delegate: SliverChildListDelegate(songs.map((song) => Text(song.title)).toList()),
        ),
      ]),
    );
  }
}
