import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:http/http.dart' as http;
import 'package:http/http.dart';
import 'package:mocktail/mocktail.dart' as mocktail;
import 'package:polaris/core/dto.dart';
import 'package:polaris/core/polaris.dart';

const goodHost = 'my-polaris-server';
const badHost = 'not-a-polaris-server';
const incompatibleHost = 'incompatible-polaris-server';
const goodHostURI = 'http://$goodHost';
const badHostURI = 'http://$badHost';
const incompatibleHostURI = 'http://$incompatibleHost';
const trailingSlashHostURI = '$goodHostURI/';

const compatibleAPIVersion = '{"major": 6, "minor": 0}';
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
