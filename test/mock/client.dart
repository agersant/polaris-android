import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart' as mockito;
import 'package:mockito/mockito.dart';
import 'package:polaris/platform/http_api.dart';

final goodhostURL = 'my-polaris-server';
final badHostURL = 'not-a-polaris-server';
final incompatibleHostURL = 'incompatible-polaris-server';

final badUsername = 'not-a-user';

final compatibleAPIVersion = '{"major": 6, "minor": 0}';
final incompatibleAPIVersion = '{"major": 5, "minor": 0}';

class Mock extends mockito.Mock implements http.Client {
  Mock() {
    when(this.get(goodhostURL + apiVersionEndpoint)).thenAnswer((_) async => http.Response(compatibleAPIVersion, 200));
    when(this.get(incompatibleHostURL + apiVersionEndpoint))
        .thenAnswer((_) async => http.Response(incompatibleAPIVersion, 200));
    when(this.get(badHostURL + apiVersionEndpoint)).thenThrow('borked internet');
  }

  mockBadLogin() {
    when(this.post(goodhostURL + loginEndpoint, body: anyNamed('body')))
        .thenAnswer((_) async => http.Response('', 401));
  }
}
