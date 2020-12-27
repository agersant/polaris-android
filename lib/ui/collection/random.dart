import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/collection/album_grid.dart';

final getIt = GetIt.instance;

class RandomAlbums extends StatefulWidget {
  @override
  _RandomAlbumsState createState() => _RandomAlbumsState();
}

class _RandomAlbumsState extends State<RandomAlbums> with AutomaticKeepAliveClientMixin {
  Future<List<Directory>> futureContent;

  @override
  void initState() {
    super.initState();
    futureContent = getIt<API>().random();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<List<Directory>>(
      future: futureContent,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // TODO better looking error messages
          return Text("error ${snapshot.error}");
        } else if (snapshot.hasData) {
          return AlbumGrid(snapshot.data);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }

  @override
  bool get wantKeepAlive => true;
}
