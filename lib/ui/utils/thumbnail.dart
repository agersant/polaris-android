import 'package:get_it/get_it.dart';
import 'package:flutter/cupertino.dart';
import 'package:polaris/collection/interface.dart' as collection;

final getIt = GetIt.instance;

class Thumbnail extends StatefulWidget {
  final String path;

  Thumbnail(this.path, {Key key}) : super(key: key);

  @override
  _ThumbnailState createState() => _ThumbnailState();
}

class _ThumbnailState extends State<Thumbnail> {
  Future<ImageProvider> _imageProvider;

  @override
  void initState() {
    super.initState();
    final interface = getIt<collection.Interface>();
    _imageProvider = interface.getImage(widget.path);
  }

  @override
  void didUpdateWidget(Thumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final interface = getIt<collection.Interface>();
    if (oldWidget.path != widget.path) {
      setState(() {
        _imageProvider = interface.getImage(widget.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _imageProvider,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }
        if (_imageProvider == null || snapshot.hasError || snapshot.data == null) {
          return Container(); // TODO stripes https://medium.com/@baobao1996mn/flutter-draw-striped-objects-with-custompainter-4955f5014706
        }
        assert(snapshot.hasData);
        return Image(
          image: snapshot.data,
          fit: BoxFit.cover,
        );
      },
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
