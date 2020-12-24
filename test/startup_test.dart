import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:polaris/api/api.dart';
import 'package:polaris/api/host.dart';
import 'package:polaris/api/http_api.dart';
import 'package:polaris/main.dart';
import 'package:polaris/store/connection.dart';
import 'package:polaris/ui/startup/connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

class MockClient extends Mock implements Client {}

final host = 'my-polaris-server';

Future _setup() async {
  SharedPreferences.setMockInitialValues(Map<String, dynamic>());

  var host = await Host.create();
  getIt.allowReassignment = true;
  getIt.registerSingleton<Host>(host);
  getIt.registerSingleton<Client>(MockClient());
  getIt.registerSingleton<API>(HttpAPI());
  getIt.registerSingleton<ConnectionStore>(ConnectionStore());
}

void main() {
  testWidgets('Connect screen shows error when failing to connect',
      (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    final Finder urlInputField =
        find.widgetWithText(TextFormField, 'Server URL');
    final Finder connectButton = find.widgetWithText(ElevatedButton, 'CONNECT');

    final client = getIt<Client>();
    when(client.get(host + '/api/version')).thenThrow('bad host');

    await tester.enterText(urlInputField, host);
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
        find.widgetWithText(TextFormField, 'Server URL');
    final Finder connectButton = find.widgetWithText(ElevatedButton, 'CONNECT');

    final client = getIt<Client>();
    when(client.get(host + '/api/version'))
        .thenAnswer((_) async => Response('{"major": 5, "minor": 0}', 200));

    await tester.enterText(urlInputField, host);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorAPIVersion), findsOneWidget);
  });

  testWidgets('Connect screen golden path', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    final Finder urlInputField =
        find.widgetWithText(TextFormField, 'Server URL');
    final Finder connectButton = find.widgetWithText(ElevatedButton, 'CONNECT');

    final client = getIt<Client>();
    when(client.get(host + '/api/version'))
        .thenAnswer((_) async => Response('{"major": 6, "minor": 0}', 200));

    await tester.enterText(urlInputField, host);
    await tester.tap(connectButton);
    await tester.pump();
    expect(urlInputField, findsNothing);
  });
}
