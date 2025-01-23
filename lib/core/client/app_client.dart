import 'dart:typed_data';
import 'package:just_audio/just_audio.dart';
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/constants.dart';
import 'package:polaris/core/client/offline_client.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/download.dart' as download;
import 'package:polaris/core/media_item.dart';
import 'package:polaris/core/songs.dart' as songs;

abstract class AppClientInterface {
  APIClientInterface? get apiClient;
}

class AppClient implements AppClientInterface {
  final APIClient _apiClient;
  final OfflineClient offlineClient;
  final download.Manager downloadManager;
  final connection.Manager connectionManager;
  final CollectionCache collectionCache;
  final MediaCacheInterface mediaCache;
  final songs.Manager songsManager;

  AppClient({
    required APIClient apiClient,
    required this.offlineClient,
    required this.connectionManager,
    required this.downloadManager,
    required this.collectionCache,
    required this.mediaCache,
    required this.songsManager,
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
      songsManager.request(content.where((entry) => !entry.isDirectory).map((e) => e.path).toList());
      return content;
    });
  }

  Future<dto.SongList> flatten(String path) async {
    final String host = _getHost();
    if (connectionManager.isConnected()) {
      return _apiClient.flatten(path).then((songList) {
        collectionCache.putFiles(host, songList.paths);
        collectionCache.putSongs(host, songList.firstSongs);
        songsManager.request(songList.paths);
        return songList;
      });
    }
    return offlineClient.flatten(host, path);
  }

  Future<Uri?> getImageURI(String path) async {
    try {
      final String host = _getHost();
      if (await mediaCache.hasImage(host, path)) {
        return mediaCache.getImageLocation(host, path).uri;
      }
      if (connectionManager.isConnected()) {
        return _apiClient.getImageURI(path);
      }
    } catch (e) {
      return null;
    }
    return null;
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

  Future<Uint8List?> getImage(String path) async {
    try {
      final String host = _getHost();
      if (connectionManager.isConnected()) {
        return await downloadManager.getImage(host, path);
      } else {
        return await offlineClient.getImage(host, path);
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
