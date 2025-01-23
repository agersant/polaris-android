import 'package:async/async.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api_client.dart';
import 'package:polaris/core/client/dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;

class Manager {
  final connection.Manager connectionManager;
  final CollectionCache collectionCache;
  final APIClient apiClient;

  final Set<String> _requested = {};
  final Set<String> _failed = {};
  final List<CancelableOperation<dto.SongBatch?>> _activeFetches = [];

  Manager({
    required this.connectionManager,
    required this.collectionCache,
    required this.apiClient,
  }) {
    connectionManager.addListener(reset);
  }

  void reset() {
    _requested.clear();
    _failed.clear();
    for (CancelableOperation<dto.SongBatch?> activeFetch in _activeFetches) {
      activeFetch.cancel();
    }
    _activeFetches.clear();
  }

  void request(List<String> paths) {
    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    for (String path in paths) {
      if (!_failed.contains(path) && !collectionCache.hasSong(host, path)) {
        _requested.add(path);
      }
    }

    _fetch();
  }

  void _fetch() async {
    if (_requested.isEmpty || _activeFetches.isNotEmpty) {
      return;
    }

    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    List<String> batch = [];
    int songCount = 0;
    List<Future> fetches = [];

    for (String path in _requested) {
      if (collectionCache.hasSong(host, path) || _failed.contains(path)) {
        continue;
      }
      songCount += 1;
      batch.add(path);
      if (batch.length >= 1000) {
        fetches.add(_fetchBatch(host, batch));
        batch = [];
      }
    }
    fetches.add(_fetchBatch(host, batch));

    await Future.wait(fetches);
    _activeFetches.clear();

    if (songCount != 0) {
      _fetch();
    }
  }

  Future _fetchBatch(String host, List<String> paths) async {
    if (paths.isEmpty) {
      return;
    }

    final operation = CancelableOperation.fromFuture(apiClient.getSongs(paths));
    _activeFetches.add(operation);

    final batch = await operation.valueOrCancellation();
    if (batch == null) {
      return;
    }
    collectionCache.putSongs(host, batch.songs);
    _failed.addAll(batch.notFound);
    _requested.removeAll(paths);
  }
}
