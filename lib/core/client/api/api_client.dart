import 'package:http/http.dart' as http;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/cache/media.dart';
import 'package:polaris/core/client/api/v7_client.dart';
import 'package:polaris/core/client/api/v8_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/connection.dart' as connection;

enum APIError {
  unspecifiedHost,
  networkError,
  unauthorized,
  responseParseError,
  requestFailed,
  timeout,
  notImplemented,
  unexpectedCacheMiss,
}

abstract class APIClientInterface {
  Future<dto.SongList> flatten(String path);
  Future<dto.Album> getAlbum(String name, List<String> mainArtists);
  Future<List<dto.AlbumHeader>> random({required int offset, required int seed});
  Future<List<dto.AlbumHeader>> recent({required int offset});
  Future<dto.SongList> search(String query);
  Future<List<dto.PlaylistHeader>> listPlaylists();
  Future<dto.Playlist> getPlaylist(String name);
  Future<void> savePlaylist(String name, List<String> tracks);
  Future<void> deletePlaylist(String name);
}

class APIClient implements APIClientInterface {
  connection.Manager connectionManager;
  final V7Client v7;
  final V8Client v8;

  APIClient({
    required http.Client httpClient,
    required CollectionCache collectionCache,
    required this.connectionManager,
    required authentication.Manager authenticationManager,
  })  : v7 = V7Client(
          httpClient: httpClient,
          connectionManager: connectionManager,
          authenticationManager: authenticationManager,
          collectionCache: collectionCache,
        ),
        v8 = V8Client(
          httpClient: httpClient,
          connectionManager: connectionManager,
          authenticationManager: authenticationManager,
          collectionCache: collectionCache,
        );

  Future<List<dto.BrowserEntry>> browse(String path) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.browse(path),
      7 => await v7.browse(path),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<dto.SongList> flatten(String path) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.flatten(path),
      7 => await v7.flatten(path),
      _ => throw APIError.notImplemented,
    };
  }

  Future<dto.SongBatch> getSongs(List<String> paths) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.getSongs(paths),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<dto.Album> getAlbum(String name, List<String> mainArtists) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.getAlbum(name, mainArtists),
      7 => await v7.getAlbum(name, mainArtists),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<List<dto.AlbumHeader>> random({required int seed, required int offset}) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.random(seed: seed, offset: offset),
      7 => await v7.random(seed: seed, offset: offset),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<List<dto.AlbumHeader>> recent({required int offset}) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.recent(offset: offset),
      7 => await v7.recent(offset: offset),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<dto.SongList> search(String query) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.search(query),
      7 => await v7.search(query),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<List<dto.PlaylistHeader>> listPlaylists() async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.listPlaylists(),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<dto.Playlist> getPlaylist(String name) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.getPlaylist(name),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<void> savePlaylist(String name, List<String> tracks) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.savePlaylist(name, tracks),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<void> deletePlaylist(String name) async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.deletePlaylist(name),
      _ => throw APIError.notImplemented,
    };
  }

  Future<http.StreamedResponse> getImage(String path, ArtworkSize size) {
    return switch (connectionManager.apiVersion) {
      8 => v8.getImage(path, size),
      7 => v7.getImage(path, size),
      _ => throw APIError.notImplemented,
    };
  }

  Uri getImageURI(String path, ArtworkSize size) {
    return switch (connectionManager.apiVersion) {
      8 => v8.getImageURI(path, size),
      7 => v7.getImageURI(path, size),
      _ => throw APIError.notImplemented,
    };
  }

  Uri getAudioURI(String path) {
    return switch (connectionManager.apiVersion) {
      8 => v8.getAudioURI(path),
      7 => v7.getAudioURI(path),
      _ => throw APIError.notImplemented,
    };
  }
}
