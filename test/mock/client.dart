import 'package:polaris/core/client/api_client.dart';
import 'package:polaris/core/client/app_client.dart';
import 'package:polaris/core/client/dto.dart';

class APIClient implements APIClientInterface {
  @override
  Future<SongList> flatten(String path) async {
    return SongList(paths: [], firstSongs: []);
  }

  @override
  Future<Album> getAlbum(String name, List<String> mainArtists) async {
    return Album(name: "Test Album", mainArtists: [""]);
  }

  @override
  Future<List<AlbumHeader>> random() async {
    return [];
  }

  @override
  Future<List<AlbumHeader>> recent() async {
    return [];
  }
}

class AppClient implements AppClientInterface {
  final APIClientInterface? _apiClient;

  AppClient(this._apiClient);

  @override
  APIClientInterface? get apiClient => _apiClient;
}
