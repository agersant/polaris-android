import 'dart:developer' as developer;
import 'package:async/async.dart';
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;

class Manager {
  final connection.Manager connectionManager;
  final authentication.Manager authenticationManager;
  final CollectionCache collectionCache;
  final APIClient apiClient;

  final Set<String> _failed = {};
  final List<CancelableOperation<dto.SongBatch?>> _activeFetches = [];

  Manager({
    required this.connectionManager,
    required this.authenticationManager,
    required this.collectionCache,
    required this.apiClient,
  }) {
    connectionManager.addListener(handleConnectionChange);
    authenticationManager.addListener(handleConnectionChange);
    collectionCache.onSongsRequested.listen((_) => _fetch());
  }

  void handleConnectionChange() {
    _failed.clear();
    for (CancelableOperation<dto.SongBatch?> activeFetch in _activeFetches) {
      activeFetch.cancel();
    }
    _activeFetches.clear();
    _fetch();
  }

  void _fetch() async {
    if (!connectionManager.isConnected() || !authenticationManager.isAuthenticated()) {
      return;
    }

    if ((connectionManager.apiVersion ?? 0) < 8) {
      return;
    }

    final String? host = connectionManager.url;
    if (host == null) {
      return;
    }

    if (_activeFetches.isNotEmpty) {
      return;
    }

    List<String> batch = [];
    int songCount = 0;
    List<Future> fetches = [];

    final missingSongs = collectionCache.getMissingSongs(host);
    for (String path in missingSongs) {
      if (_failed.contains(path)) {
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

    dto.SongBatch? batch;
    try {
      batch = await operation.valueOrCancellation();
      if (batch == null) {
        return;
      }
    } catch (e) {
      developer.log('Error while downloading song batch: $e');
      _failed.addAll(paths);
      return;
    }
    collectionCache.putSongs(host, batch.songs);
    final found = batch.songs.map((s) => s.path).toSet();
    _failed.addAll(paths.where((s) => !found.contains(s)));
    _failed.addAll(batch.notFound);
  }
}
