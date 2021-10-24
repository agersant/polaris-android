import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/utils/fallback_artwork.dart';

final getIt = GetIt.instance;

class Thumbnail extends StatefulWidget {
  final String? path;

  Thumbnail(this.path, {Key? key}) : super(key: key);

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  Future<Uint8List>? futureImage;

  @override
  void initState() {
    super.initState();
    _fetchImage();
  }

  @override
  void didUpdateWidget(Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      setState(() {
        _fetchImage();
      });
    }
  }

  void _fetchImage() {
    String? path = widget.path;
    if (path != null) {
      final completer = Completer<Uint8List>();
      final sink = ByteConversionSink.withCallback((bytes) => completer.complete(Uint8List.fromList(bytes)));
      final byteStreamFuture = getIt<polaris.Client>().getImage(path);
      byteStreamFuture.then((byteStream) {
        if (byteStream != null) {
          byteStream.listen(sink.add, onError: completer.completeError, onDone: sink.close, cancelOnError: true);
        } else {
          completer.completeError("No image byte stream available");
        }
      });
      futureImage = completer.future;
    } else {
      futureImage = null;
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
              snapshot.data!,
              fit: BoxFit.cover,
            );
        }
      },
    );
  }
}

class LargeThumbnail extends StatelessWidget {
  final String? path;

  LargeThumbnail(this.path, {Key? key}) : super(key: key);

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
  final String? path;

  ListThumbnail(this.path, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4.0),
      child: SizedBox(
        width: 44,
        height: 44,
        child: Thumbnail(path),
      ),
    );
  }
}
