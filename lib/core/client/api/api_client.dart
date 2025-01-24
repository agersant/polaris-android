import 'package:http/http.dart' as http;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/cache/collection.dart';
import 'package:polaris/core/client/api/v7_client.dart';
import 'package:polaris/core/client/api/v8_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart' as dto;
import 'package:polaris/core/client/constants.dart';
import 'package:polaris/core/connection.dart' as connection;

abstract class APIClientInterface {
  Future<dto.SongList> flatten(String path);
  Future<dto.Album> getAlbum(String name, List<String> mainArtists);
  Future<List<dto.AlbumHeader>> random();
  Future<List<dto.AlbumHeader>> recent();
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
  Future<List<dto.AlbumHeader>> random() async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.random(),
      7 => await v7.random(),
      _ => throw APIError.notImplemented,
    };
  }

  @override
  Future<List<dto.AlbumHeader>> recent() async {
    return switch (connectionManager.apiVersion) {
      8 => await v8.recent(),
      7 => await v7.recent(),
      _ => throw APIError.notImplemented,
    };
  }

  Future<http.StreamedResponse> getImage(String path) {
    return switch (connectionManager.apiVersion) {
      8 => v8.getImage(path),
      7 => v7.getImage(path),
      _ => throw APIError.notImplemented,
    };
  }

  Uri getImageURI(String path) {
    return switch (connectionManager.apiVersion) {
      8 => v8.getImageURI(path),
      7 => v7.getImageURI(path),
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
