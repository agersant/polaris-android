import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart' as mockito;
import 'package:mockito/mockito.dart';
import 'package:polaris/platform/dto.dart';
import 'package:polaris/platform/http_api.dart';

final missingProtocolHostURL = 'my-polaris-server';
final goodHostURL = 'http://' + missingProtocolHostURL;
final badHostURL = 'http://not-a-polaris-server';
final trailingSlashHostURL = goodHostURL + '/';
final incompatibleHostURL = 'http://incompatible-polaris-server';

final compatibleAPIVersion = '{"major": 6, "minor": 0}';
final incompatibleAPIVersion = '{"major": 5, "minor": 0}';
final authorization = '{"username": "test-user", "token": "0xDEADBEEF", "is_admin": false}';

class Mock extends mockito.Mock implements http.Client {
  Mock() {
    // API version
    when(this.get(goodHostURL + apiVersionEndpoint, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(compatibleAPIVersion, 200));
    when(this.get(incompatibleHostURL + apiVersionEndpoint, headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(incompatibleAPIVersion, 200));
    when(this.get(badHostURL + apiVersionEndpoint, headers: anyNamed('headers'))).thenThrow('borked internet');

    // Login
    when(this.post(goodHostURL + loginEndpoint, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(authorization, 200));

    // Browse
    when(this.get(argThat(startsWith(goodHostURL + browseEndpoint)), headers: anyNamed('headers')))
        .thenAnswer((Invocation invocation) async {
      final String endpoint = invocation.positionalArguments[0];
      final String path = endpoint.substring((goodHostURL + browseEndpoint).length);
      final List<CollectionFile> files = _browseData[path];
      if (files == null) {
        return http.Response('', 404);
      }
      final String payload = jsonEncode(files);
      return http.Response(payload, 200);
    });
  }

  mockBadLogin() {
    when(this.post(goodHostURL + loginEndpoint, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 401));
  }
}

Map<String, List<CollectionFile>> _browseData = {
  '': [
    CollectionFile(Right(
      Directory()..path = 'root',
    ))
  ],
};
