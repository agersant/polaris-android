import 'package:mockito/mockito.dart' as mockito;
import 'package:http/http.dart' as http;
import 'package:polaris/service/http_api.dart';

final goodhostURL = 'my-polaris-server';
final badHostURL = 'not-a-polaris-server';
final incompatibleHostURL = 'incompatible-polaris-server';

final compatibleAPIVersion = '{"major": 6, "minor": 0}';
final incompatibleAPIVersion = '{"major": 5, "minor": 0}';

class Mock extends mockito.Mock implements http.Client {
  Mock() {
    mockito
        .when(this.get(goodhostURL + apiVersionEndpoint))
        .thenAnswer((_) async => http.Response(compatibleAPIVersion, 200));
    mockito
        .when(this.get(incompatibleHostURL + apiVersionEndpoint))
        .thenAnswer((_) async => http.Response(incompatibleAPIVersion, 200));
    mockito.when(this.get(badHostURL + apiVersionEndpoint)).thenThrow('borked internet');
  }
}
