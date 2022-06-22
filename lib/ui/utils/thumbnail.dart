import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/ui/utils/fallback_artwork.dart';

final getIt = GetIt.instance;

class Thumbnail extends StatefulWidget {
  final String? path;

  const Thumbnail(this.path, {Key? key}) : super(key: key);

  @override
  State<Thumbnail> createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  Future<Uint8List?>? futureImage;

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
      futureImage = getIt<polaris.Client>().getImage(path);
    } else {
      futureImage = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: futureImage,
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
            return const FallbackArtwork();
          case ConnectionState.waiting:
          case ConnectionState.active:
            return Container();
          case ConnectionState.done:
            if (!snapshot.hasData || snapshot.data == null) {
              return const FallbackArtwork();
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

  const LargeThumbnail(this.path, {Key? key}) : super(key: key);

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

  const ListThumbnail(this.path, {Key? key}) : super(key: key);

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
