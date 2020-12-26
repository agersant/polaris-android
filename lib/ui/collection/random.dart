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

class _RandomAlbumsState extends State<RandomAlbums> {
  Future<List<Directory>> futureContent;

  @override
  void initState() {
    super.initState();
    futureContent = getIt<API>().random();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Directory>>(
      future: futureContent,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // TODO better error messages
          return Text("error ${snapshot.error}");
        } else if (snapshot.hasData) {
          final directories = snapshot.data;
          if (directories.length == 0) {
            // TODO empty results, handle within Album Grod
            return Text('no albums');
          }
          return AlbumGrid(directories);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
