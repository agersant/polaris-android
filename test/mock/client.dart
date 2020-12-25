import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart' as mockito;
import 'package:mockito/mockito.dart';
import 'package:polaris/platform/http_api.dart';

final goodhostURL = 'my-polaris-server';
final badHostURL = 'not-a-polaris-server';
final incompatibleHostURL = 'incompatible-polaris-server';

final compatibleAPIVersion = '{"major": 6, "minor": 0}';
final incompatibleAPIVersion = '{"major": 5, "minor": 0}';
final authorization = '{"username": "test-user", "token": "0xDEADBEEF", "is_admin": false}';

class Mock extends mockito.Mock implements http.Client {
  Mock() {
    // API version
    when(this.get(goodhostURL + apiVersionEndpoint)).thenAnswer((_) async => http.Response(compatibleAPIVersion, 200));
    when(this.get(incompatibleHostURL + apiVersionEndpoint))
        .thenAnswer((_) async => http.Response(incompatibleAPIVersion, 200));
    when(this.get(badHostURL + apiVersionEndpoint)).thenThrow('borked internet');

    // Login
    when(this.post(goodhostURL + loginEndpoint, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response(authorization, 200));

    // Browse
    when(this.get(goodhostURL + browseEndpoint)).thenAnswer((_) async => http.Response('', 200));
  }

  mockBadLogin() {
    when(this.post(goodhostURL + loginEndpoint, body: anyNamed('body'), headers: anyNamed('headers')))
        .thenAnswer((_) async => http.Response('', 401));
  }
}
