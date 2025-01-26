import 'package:polaris/core/client/api/api_client.dart';
import 'package:polaris/core/client/api/v8_dto.dart';
import 'package:polaris/core/client/app_client.dart';

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
  Future<List<AlbumHeader>> random({required int seed, required int offset}) async {
    return [];
  }

  @override
  Future<List<AlbumHeader>> recent({required int offset}) async {
    return [];
  }

  @override
  Future<SongList> search(String path) async {
    return SongList(paths: [], firstSongs: []);
  }

  @override
  Future<void> deletePlaylist(String name) async {}

  @override
  Future<Playlist> getPlaylist(String name) async {
    return Playlist(
      name: 'Test Playlist',
      duration: 0,
      numSongsByGenre: {},
      songs: SongList(paths: [], firstSongs: []),
    );
  }

  @override
  Future<List<PlaylistHeader>> listPlaylists() async {
    return [];
  }

  @override
  Future<void> savePlaylist(String name, List<String> tracks) async {}
}

class AppClient implements AppClientInterface {
  final APIClientInterface? _apiClient;

  AppClient(this._apiClient);

  @override
  APIClientInterface? get apiClient => _apiClient;

  @override
  Future<SongList> flatten(String path) async => SongList(paths: [], firstSongs: []);
}
