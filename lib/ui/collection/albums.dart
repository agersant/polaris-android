import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart';
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/ui/strings.dart';
import 'package:polaris/ui/collection/album_grid.dart';
import 'package:polaris/ui/utils/error_message.dart';

final getIt = GetIt.instance;

enum SortMode {
  random,
  recent,
}

class Albums extends StatefulWidget {
  const Albums({Key? key}) : super(key: key);

  @override
  State<Albums> createState() => _AlbumsState();
}

class _AlbumsState extends State<Albums> with AutomaticKeepAliveClientMixin {
  SortMode sortMode = SortMode.random;
  int seed = 0;
  List<AlbumHeader>? _albums;
  APIError? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    seed = Random().nextInt(1 << 32);
    _scrollController.addListener(onScroll);
    _fetchAlbums();
  }

  @override
  void dispose() {
    super.dispose();
    _scrollController.removeListener(onScroll);
  }

  void setSortMode(SortMode newMode) {
    if (newMode == sortMode) {
      return;
    }
    seed = Random().nextInt(1 << 32);
    _scrollController.jumpTo(0.0);
    setState(() {
      sortMode = newMode;
      _albums = null;
      _error = null;
    });
    _fetchAlbums();
  }

  void onScroll() {
    final position = _scrollController.position.pixels;
    final maxPosition = _scrollController.position.maxScrollExtent;
    if (position == maxPosition) {
      _fetchAlbums();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        spacing: 24,
        children: [
          ToggleButtons(
            borderRadius: BorderRadius.circular(4),
            textStyle: Theme.of(context).textTheme.labelLarge,
            isSelected: SortMode.values.map((m) => m == sortMode).toList(),
            children: SortMode.values
                .map((m) => Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Text(switch (m) {
                        SortMode.recent => recentAlbums,
                        SortMode.random => randomAlbums,
                      }),
                    ))
                .toList(),
            onPressed: (index) => setSortMode(SortMode.values[index]),
          ),
          Expanded(child: _buildResults())
        ],
      ),
    );
  }

  Widget _buildResults() {
    List<AlbumHeader>? albums = _albums;

    if (albums == null) {
      if (_error != null) {
        return ErrorMessage(
          albumsError,
          action: _fetchAlbums,
          actionLabel: retryButtonLabel,
        );
      } else {
        return const Center(child: CircularProgressIndicator());
      }
    }

    return AlbumGrid(albums, _scrollController);
  }

  Future _fetchAlbums() async {
    // TODO legacy API cleanup
    final connectionManager = getIt<connection.Manager>();
    final hasAlbums = _albums?.isNotEmpty ?? false;
    final supportsInfiniteFeed = (connectionManager.apiVersion ?? 0) >= 8;
    if (hasAlbums && sortMode == SortMode.recent && !supportsInfiniteFeed) {
      return;
    }

    try {
      setState(() {
        _error = null;
      });

      final APIClientInterface? client = getIt<AppClient>().apiClient;
      if (client != null) {
        final albums = await switch (sortMode) {
          SortMode.recent => client.recent(offset: _albums?.length ?? 0),
          SortMode.random => client.random(seed: seed, offset: _albums?.length ?? 0),
        };
        setState(() {
          _albums ??= [];
          _albums?.addAll(albums);
        });
      }
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
