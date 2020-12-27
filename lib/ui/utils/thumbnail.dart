import 'package:get_it/get_it.dart';
import 'package:flutter/cupertino.dart';
import 'package:polaris/collection/interface.dart' as collection;

final getIt = GetIt.instance;

class Thumbnail extends StatefulWidget {
  final String _path;

  Thumbnail(this._path);

  @override
  _ThumbnailState createState() => _ThumbnailState(this._path);
}

class _ThumbnailState extends State<Thumbnail> {
  final String _path;
  Future<ImageProvider> _imageProvider;

  _ThumbnailState(this._path);

  @override
  void initState() {
    super.initState();
    final interface = getIt<collection.Interface>();
    _imageProvider = interface.getImage(_path);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _imageProvider,
      builder: (context, snapshot) {
        if (snapshot.hasError || _imageProvider == null) {
          return Container(); // TODO stripes https://medium.com/@baobao1996mn/flutter-draw-striped-objects-with-custompainter-4955f5014706
        }
        if (!snapshot.hasData) {
          return Container();
        }
        return Image(
          image: snapshot.data,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
