import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/polaris.dart' as polaris;
import 'package:polaris/core/dto.dart';
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

class RecentAlbums extends StatefulWidget {
  const RecentAlbums({Key? key}) : super(key: key);

  @override
  State<RecentAlbums> createState() => _RecentAlbumsState();
}

class _RecentAlbumsState extends State<RecentAlbums> with AutomaticKeepAliveClientMixin {
  List<Directory>? _albums;
  polaris.APIError? _error;

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
        recentError,
        action: _onRefresh,
        actionLabel: retryButtonLabel,
      );
    }
    List<Directory>? albums = _albums;
    if (albums == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return AlbumGrid(albums, onRefresh: _onRefresh);
  }

  Future _onRefresh() async {
    setState(() {
      _error = null;
    });
    try {
      final polaris.HttpClient? client = getIt<polaris.Client>().httpClient;
      if (client != null) {
        final albums = await client.recent();
        setState(() {
          _albums = albums;
        });
      }
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
