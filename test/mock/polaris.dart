import 'package:polaris/core/dto.dart';
import 'package:polaris/core/polaris.dart';

class HttpClient implements HttpClientInterface {
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

class PolarisClient implements ClientInterface {
  final HttpClientInterface? _httpClient;

  PolarisClient(this._httpClient);

  @override
  HttpClientInterface? get httpClient => _httpClient;
}
