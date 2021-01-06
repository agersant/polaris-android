import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/shared/polaris.dart' as polaris;
import 'package:polaris/shared/dto.dart';
import 'package:polaris/foreground/ui/strings.dart';
import 'package:polaris/foreground/ui/collection/album_grid.dart';
import 'package:polaris/foreground/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class RandomAlbums extends StatefulWidget {
  @override
  _RandomAlbumsState createState() => _RandomAlbumsState();
}

class _RandomAlbumsState extends State<RandomAlbums> with AutomaticKeepAliveClientMixin {
  List<Directory> _albums;
  polaris.APIError _error;

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
    return AlbumGrid(_albums, onRefresh: _onRefresh);
  }

  Future _onRefresh() async {
    setState(() {
      _error = null;
    });
    try {
      final albums = await getIt<polaris.API>().random();
      setState(() {
        _albums = albums;
      });
    } on polaris.APIError catch (e) {
      setState(() {
        _albums = null;
        _error = e;
      });
    }
  }

  @override
  bool get wantKeepAlive => true;
}
