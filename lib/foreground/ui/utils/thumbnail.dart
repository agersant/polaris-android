import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/foreground/ui/utils/fallback_artwork.dart';

final getIt = GetIt.instance;

class Thumbnail extends StatefulWidget {
  final String path;

  Thumbnail(this.path, {Key key}) : super(key: key);

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  Future<Uint8List> futureImage;

  @override
  void initState() {
    super.initState();
    _updateURL();
  }

  @override
  void didUpdateWidget(Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      setState(() {
        _updateURL();
      });
    }
  }

  void _updateURL() {
    if (widget.path != null) {
      futureImage = getIt<polaris.API>().downloadImage(widget.path).then((r) => r.stream.toBytes());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: futureImage,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return FallbackArtwork();
          case ConnectionState.waiting:
          case ConnectionState.active:
            return Container();
          case ConnectionState.done:
            if (!snapshot.hasData) {
              return FallbackArtwork();
            }
            return Image.memory(
              snapshot.data,
              fit: BoxFit.cover,
            );
        }
        return FallbackArtwork();
      },
    );
  }
}

class LargeThumbnail extends StatelessWidget {
  final String path;

  LargeThumbnail(this.path, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Thumbnail(path),
      ),
    );
  }
}

class ListThumbnail extends StatelessWidget {
  final String path;

  ListThumbnail(this.path, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
        width: 40,
        height: 40,
        child: Thumbnail(path),
      ),
    );
  }
}
