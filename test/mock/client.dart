import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:polaris/shared/dto.dart';
import 'package:polaris/shared/polaris.dart';

final goodHost = 'my-polaris-server';
final badHost = 'not-a-polaris-server';
final incompatibleHost = 'incompatible-polaris-server';
final goodHostURI = 'http://' + goodHost;
final badHostURI = 'http://' + badHost;
final incompatibleHostURI = 'http://' + incompatibleHost;
final trailingSlashHostURI = goodHostURI + '/';

final compatibleAPIVersion = '{"major": 6, "minor": 0}';
final incompatibleAPIVersion = '{"major": 5, "minor": 0}';
final authorization = '{"username": "test-user", "token": "0xDEADBEEF", "is_admin": false}';

final rootDirectoryName = 'root';
final heronDirectoryName = 'Heron';
final aegeusDirectoryName = 'Aegeus';
final rootDirectoryPath = rootDirectoryName;
final heronDirectoryPath = rootDirectoryName + '/' + heronDirectoryName;
final aegeusDirectoryPath = heronDirectoryPath + '/' + aegeusDirectoryName;

final labyrinthSongName = 'Labyrinth';
final fallInwardsSongName = 'Falling Inwards';
final labyrinthFilePath = aegeusDirectoryPath + '/' + labyrinthSongName + '.mp3';
final fallInwardsFilePath = aegeusDirectoryPath + '/' + fallInwardsSongName + '.mp3';

class Mock extends mocktail.Mock implements http.Client {
  bool _failLogin = false;

  mockBadLogin() {
    _failLogin = true;
  }

  Mock() {
    mocktail.registerFallbackValue(new http.Request("", new Uri()));

    mocktail.when(() => this.send(mocktail.any())).thenAnswer((Invocation invocation) async {
      final Request request = invocation.positionalArguments[0];
      final String endpoint = request.url.path;

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
        if (_failLogin) {
          return http.StreamedResponse(Stream<List<int>>.value([]), 401);
        } else {
          return http.StreamedResponse(Stream<List<int>>.value(authorization.codeUnits), 200);
        }
      } else if (endpoint.startsWith(browseEndpoint)) {
        final String path = Uri.decodeComponent(endpoint.substring(browseEndpoint.length));
        final List<CollectionFile>? files = _browseData[path];
        if (files != null) {
          final String payload = jsonEncode(files);
          return http.StreamedResponse(Stream<List<int>>.value(payload.codeUnits), 200);
        }
      }
      return http.StreamedResponse(Stream<List<int>>.value([]), 404);
    });
  }
}

Map<String, List<CollectionFile>> _browseData = {
  '': [
    CollectionFile(Right(
      Directory(path: rootDirectoryPath),
    ))
  ],
  rootDirectoryPath: [
    CollectionFile(Right(
      Directory(path: heronDirectoryPath),
    ))
  ],
  heronDirectoryPath: [
    CollectionFile(Right(
      Directory(path: aegeusDirectoryPath)
        ..album = 'Aegeus'
        ..artist = 'Heron'
        ..year = 2016,
    ))
  ],
  aegeusDirectoryPath: [
    CollectionFile(Left(
      Song(path: labyrinthFilePath)
        ..title = labyrinthSongName
        ..artist = heronDirectoryName
        ..trackNumber = 1
        ..album = aegeusDirectoryName,
    )),
    CollectionFile(Left(
      Song(path: fallInwardsFilePath)
        ..title = fallInwardsSongName
        ..artist = heronDirectoryName
        ..trackNumber = 2
        ..album = aegeusDirectoryName,
    )),
  ],
};
