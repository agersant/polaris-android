import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class RandomAlbums extends StatefulWidget {
  @override
  _RandomAlbumsState createState() => _RandomAlbumsState();
}

class _RandomAlbumsState extends State<RandomAlbums> with AutomaticKeepAliveClientMixin {
  List<Directory> _albums;
  APIError _error;

  @override
  void initState() {
    super.initState();
    _onRefresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_error != null) {
      return ErrorMessage(
        randomError,
        action: _onRefresh,
        actionLabel: retryButtonLabel,
      );
    }
    if (_albums == null) {
      return Center(child: CircularProgressIndicator());
    }
    // TODO consider animating in
    return AlbumGrid(_albums, onRefresh: _onRefresh);
  }

  Future _onRefresh() async {
    setState(() {
      _error = null;
    });
    try {
      final albums = await getIt<API>().random();
      setState(() {
        _albums = albums;
      });
    } on APIError catch (e) {
      setState(() {
        _albums = null;
        _error = e;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
