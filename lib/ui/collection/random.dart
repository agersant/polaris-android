import 'dart:math';

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

  Widget _buildAlbumGrid(BuildContext context, List<Directory> directories) {
    assert(directories.length > 0);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = 2; // TODO landscape mode
    final crossAxisSpacing = 16.0; // TODO landscape mode
    final padding = 16.0; // TODO landscape mode
    final childWidth = ((screenWidth - 2 * padding) - max(0, crossAxisCount - 1) * crossAxisSpacing) / crossAxisCount;

    final titleStyle = Theme.of(context).textTheme.subtitle1;
    final TextPainter titlePainter =
        TextPainter(text: TextSpan(text: '', style: titleStyle), maxLines: 1, textDirection: TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: double.infinity);
    final titleHeight = titlePainter.size.height;

    final artistStyle = Theme.of(context).textTheme.subtitle2;
    final TextPainter artistPainter =
        TextPainter(text: TextSpan(text: '', style: artistStyle), maxLines: 1, textDirection: TextDirection.ltr)
          ..layout(minWidth: 0, maxWidth: double.infinity);
    final artistHeight = artistPainter.size.height;

    final childHeight = childWidth + titleHeight + artistHeight;
    final childAspectRatio = childWidth / childHeight;
    return GridView.count(
      crossAxisCount: crossAxisCount,
      padding: EdgeInsets.all(padding),
      mainAxisSpacing: 24.0,
      crossAxisSpacing: crossAxisSpacing,
      childAspectRatio: childAspectRatio,
      children: directories.map((directory) {
        return Align(
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1.0,
                child: Image.network(
                  'https://f4.bcbits.com/img/a0959935152_16.jpg', // TMP
                  fit: BoxFit.cover,
                ),
              ),
              DefaultTextStyle(
                style: titleStyle,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: Text(directory.album),
              ),
              DefaultTextStyle(
                style: artistStyle,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                child: Text(directory.artist),
              ),
            ],
          ),
        );
      }).toList(),
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
          return _buildAlbumGrid(context, directories);
        }

        return Center(child: CircularProgressIndicator());
      },
    );
  }
}
