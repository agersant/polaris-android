import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:polaris/main.dart';
import 'package:polaris/manager/connection.dart' as connection;
import 'package:polaris/service/api.dart';
import 'package:polaris/service/host.dart';
import 'package:polaris/service/http_api.dart';
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

class MockClient extends Mock implements Client {}

final hostURL = 'my-polaris-server';
final apiVersionEndpoint = hostURL + '/api/version';
final compatibleAPIVersion = '{"major": 6, "minor": 0}';
final incompatibleAPIVersion = '{"major": 5, "minor": 0}';

Future _setup({bool connect = false}) async {
  var preferences = Map<String, dynamic>();
  if (connect) {
    preferences[serverURLKey] = hostURL;
  }
  SharedPreferences.setMockInitialValues(preferences);

  var host = await Host.create();
  getIt.allowReassignment = true;
  getIt.registerSingleton<Host>(host);
  getIt.registerSingleton<Client>(MockClient());
  if (connect) {
    final client = getIt<Client>();
    when(client.get(apiVersionEndpoint))
        .thenAnswer((_) async => Response(compatibleAPIVersion, 200));
  }

  getIt.registerSingleton<API>(HttpAPI());
  getIt.registerSingleton<connection.Manager>(connection.Manager());
}

void main() {
  testWidgets('Connect screen shows error when failing to connect',
      (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    final Finder urlInputField =
        find.widgetWithText(TextFormField, serverURLFieldLabel);
    final Finder connectButton =
        find.widgetWithText(ElevatedButton, connectButtonLabel);

    final client = getIt<Client>();
    when(client.get(apiVersionEndpoint)).thenThrow('bad host');

    await tester.enterText(urlInputField, hostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorNetwork), findsOneWidget);
  });

  testWidgets(
      'Connect screen shows error when connecting to incompatible server',
      (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    final Finder urlInputField =
        find.widgetWithText(TextFormField, serverURLFieldLabel);
    final Finder connectButton =
        find.widgetWithText(ElevatedButton, connectButtonLabel);

    final client = getIt<Client>();
    when(client.get(apiVersionEndpoint))
        .thenAnswer((_) async => Response(incompatibleAPIVersion, 200));

    await tester.enterText(urlInputField, hostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorAPIVersion), findsOneWidget);
  });

  testWidgets('Connect screen golden path', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    final Finder urlInputField =
        find.widgetWithText(TextFormField, serverURLFieldLabel);
    final Finder connectButton =
        find.widgetWithText(ElevatedButton, connectButtonLabel);

    final client = getIt<Client>();
    when(client.get(apiVersionEndpoint))
        .thenAnswer((_) async => Response(compatibleAPIVersion, 200));

    await tester.enterText(urlInputField, hostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(urlInputField, findsNothing);
  });

  testWidgets('Reconnects on startup', (WidgetTester tester) async {
    await _setup(connect: true);

    await tester.pumpWidget(PolarisApp());

    final Finder connectButton =
        find.widgetWithText(ElevatedButton, connectButtonLabel);
    final Finder disconnectButton =
        find.widgetWithText(FlatButton, disconnectButtonLabel);

    expect(connectButton, findsNothing);
    expect(disconnectButton, findsOneWidget);
  });

  testWidgets('Disconnect returns to connect screen',
      (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    final Finder urlInputField =
        find.widgetWithText(TextFormField, serverURLFieldLabel);
    final Finder connectButton =
        find.widgetWithText(ElevatedButton, connectButtonLabel);
    final Finder disconnectButton =
        find.widgetWithText(FlatButton, disconnectButtonLabel);

    final client = getIt<Client>();
    when(client.get(apiVersionEndpoint))
        .thenAnswer((_) async => Response(compatibleAPIVersion, 200));

    await tester.enterText(urlInputField, hostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(urlInputField, findsNothing);

    await tester.tap(disconnectButton);
    await tester.pump();
    expect(urlInputField, findsOneWidget);
  });
}
