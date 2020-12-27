import 'package:get_it/get_it.dart';
import 'package:flutter/cupertino.dart';
import 'package:polaris/collection/interface.dart' as collection;

final getIt = GetIt.instance;

class Thumbnail extends StatelessWidget {
  final String path;

  Thumbnail(this.path, {Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final interface = getIt<collection.Interface>();
    final imageProvider = interface.getImage(path);

    return FutureBuilder(
      future: imageProvider,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Container();
        }
        if (imageProvider == null || snapshot.hasError || snapshot.data == null) {
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
