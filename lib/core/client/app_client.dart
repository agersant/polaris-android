import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/offline_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/media_item.dart';

abstract class AppClientInterface {
  APIClientInterface? get apiClient;
  Future<dto.SongList> flatten(String path);
}

class AppClient implements AppClientInterface {
  final APIClient _apiClient;
  final OfflineClient offlineClient;
  final download.Manager downloadManager;
  final connection.Manager connectionManager;
  final CollectionCache collectionCache;
  final MediaCacheInterface mediaCache;

  AppClient({
    required APIClient apiClient,
    required this.offlineClient,
    required this.connectionManager,
    required this.downloadManager,
    required this.collectionCache,
    required this.mediaCache,
  }) : _apiClient = apiClient;

  @override
  APIClientInterface? get apiClient {
    if (connectionManager.isConnected()) {
      return _apiClient;
    }
    return null;
  }

  Future<List<dto.BrowserEntry>> browse(String path, {bool useCache = true}) async {
    final String host = _getHost();

    if (!connectionManager.isConnected()) {
      return offlineClient.browse(host, path);
    }

    if (useCache && collectionCache.hasPopulatedDirectory(host, path)) {
      final cachedContent = collectionCache.getDirectory(host, path);
      if (cachedContent != null) {
        return cachedContent;
      }
    }

    return _apiClient.browse(path).then((content) {
      collectionCache.putDirectory(host, path, content);
      return content;
    });
  }

  @override
  Future<dto.SongList> flatten(String path) async {
    final String host = _getHost();
    if (connectionManager.isConnected()) {
      return _apiClient.flatten(path).then((songList) {
        collectionCache.putSongs(host, songList.firstSongs);
        collectionCache.putFiles(host, songList.paths);
        return songList;
      });
    }
    return offlineClient.flatten(host, path);
  }

  Future<Uri?> getImageURI(String path, ArtworkSize size) async {
    try {
      final String host = _getHost();
      if (await mediaCache.hasImage(host, path, size)) {
        return mediaCache.getImageLocation(host, path, size).uri;
      }
      if (connectionManager.isConnected()) {
        return _apiClient.getImageURI(path, size);
      }
      return (await mediaCache.getImageAnySize(host, path))?.uri;
    } catch (e) {
      return null;
    }
  }

  Future<AudioSource?> getAudio(String path, String id) async {
    try {
      final String host = _getHost();
      final mediaItem = makeMediaItem(id, path);
      if (connectionManager.isConnected()) {
        return await downloadManager.getAudio(host, path, mediaItem);
      } else {
        return await offlineClient.getAudio(host, path, mediaItem);
      }
    } catch (e) {
      return null;
    }
  }

  Future<Uint8List?> getImage(String path, ArtworkSize size) async {
    try {
      final String host = _getHost();
      if (connectionManager.isConnected()) {
        return await downloadManager.getImage(host, path, size);
      } else {
        return await offlineClient.getImage(host, path, size);
      }
    } catch (e) {
      return null;
    }
  }

  String _getHost() {
    final String? host = connectionManager.url;
    if (host == null) {
      throw APIError.unspecifiedHost;
    }
    return host;
  }
}
