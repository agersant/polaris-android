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
  List<Directory> _albums;

  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_albums == null) {
      return Center(child: CircularProgressIndicator());
    }
    return AlbumGrid(_albums, onRefresh: _onRefresh);
  }

  Future _onRefresh() async {
    // TODO handle errors!
    final newAlbums = await getIt<API>().random();
    setState(() {
      _albums = newAlbums;
    });
  }

  @override
  bool get wantKeepAlive => true;
}
