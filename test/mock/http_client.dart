import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:polaris/core/client/api/v8_dto.dart';
import 'package:polaris/core/client/api/v8_client.dart';

const goodHost = 'my-polaris-server';
const badHost = 'not-a-polaris-server';
const incompatibleHost = 'incompatible-polaris-server';
const goodHostURI = 'http://$goodHost';
const badHostURI = 'http://$badHost';
const incompatibleHostURI = 'http://$incompatibleHost';
const trailingSlashHostURI = '$goodHostURI/';

const compatibleAPIVersion = '{"major": 8, "minor": 0}';
const incompatibleAPIVersion = '{"major": 5, "minor": 0}';
const authorization = '{"username": "test-user", "token": "0xDEADBEEF", "is_admin": false}';

const rootDirectoryName = 'root';
const heronDirectoryName = 'Heron';
const aegeusDirectoryName = 'Aegeus';
const rootDirectoryPath = rootDirectoryName;
const heronDirectoryPath = '$rootDirectoryName/$heronDirectoryName';
const aegeusDirectoryPath = '$heronDirectoryPath/$aegeusDirectoryName';

const labyrinthSongName = 'Labyrinth';
const fallInwardsSongName = 'Falling Inwards';
const labyrinthFilePath = '$aegeusDirectoryPath/$labyrinthSongName.mp3';
const fallInwardsFilePath = '$aegeusDirectoryPath/$fallInwardsSongName.mp3';

class HttpClient extends mocktail.Mock implements http.Client {
  bool _mockUnauthorized = false;
  Duration? _delay;

  void mockUnauthorized() {
    _mockUnauthorized = true;
  }

  void setNetworkDelay(Duration delay) {
    _delay = delay;
  }

  HttpClient() {
    mocktail.registerFallbackValue(http.Request("GET", Uri()));

    mocktail.when(() => send(mocktail.any())).thenAnswer((Invocation invocation) async {
      final delay = _delay;
      if (delay != null) {
        await Future<void>.delayed(delay);
      }

      final Request request = invocation.positionalArguments[0];
      final String endpoint = request.url.path;

      if (_mockUnauthorized) {
        return http.StreamedResponse(Stream<List<int>>.value([]), 401);
      }

      if (endpoint.startsWith(apiVersionEndpoint)) {
        final String host = request.url.host;
        if (host == goodHost) {
          return http.StreamedResponse(Stream<List<int>>.value(compatibleAPIVersion.codeUnits), 200);
        }
        if (host == incompatibleHost) {
          return http.StreamedResponse(Stream<List<int>>.value(incompatibleAPIVersion.codeUnits), 200);
        }
        if (host == badHost) {
          return http.StreamedResponse(Stream<List<int>>.value([]), 404);
        }
      } else if (endpoint.startsWith(loginEndpoint)) {
        return http.StreamedResponse(Stream<List<int>>.value(authorization.codeUnits), 200);
      } else if (endpoint.startsWith(browseEndpoint)) {
        final String path = Uri.decodeComponent(endpoint.substring(browseEndpoint.length));
        final List<BrowserEntry>? files = _browseData[path];
        if (files != null) {
          final String payload = jsonEncode(files);
          return http.StreamedResponse(Stream<List<int>>.value(payload.codeUnits), 200);
        }
      } else if (endpoint.startsWith(songsEndpoint)) {
        final songBatch = SongBatchRequest.fromJson(jsonDecode(request.body));
        final songs = SongBatch(songs: [], notFound: songBatch.paths);
        final String payload = jsonEncode(songs);
        return http.StreamedResponse(Stream<List<int>>.value(payload.codeUnits), 200);
      }
      return http.StreamedResponse(Stream<List<int>>.value([]), 404);
    });
  }
}

Map<String, List<BrowserEntry>> _browseData = {
  '': [
    BrowserEntry(path: rootDirectoryPath, isDirectory: true),
  ],
  rootDirectoryPath: [
    BrowserEntry(path: heronDirectoryPath, isDirectory: true),
  ],
  heronDirectoryPath: [
    BrowserEntry(path: aegeusDirectoryPath, isDirectory: true),
  ],
  aegeusDirectoryPath: [
    BrowserEntry(path: labyrinthFilePath, isDirectory: false),
    BrowserEntry(path: fallInwardsFilePath, isDirectory: false),
  ],
};
