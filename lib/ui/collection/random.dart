import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';

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

  Widget _buildAlbumGrid(List<Directory> directories) {
    assert(directories.length > 0);
    return GridView.builder(
      itemCount: directories.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2), // TODO support landscape mode
      itemBuilder: (context, index) {
        return GridTile(
            child: Container(
              color: Color.fromARGB(255, 255, 150, 20),
            ),
            footer: GridTileBar(
              title: Text(directories[index].album),
              subtitle: Text(directories[index].artist),
            ));
      },
    );
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
            // TODO empty results
            return Text('no albums');
          }
          return _buildAlbumGrid(directories);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
