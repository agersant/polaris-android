import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_test/flutter_test.dart';
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

Future _setup() async {
  SharedPreferences.setMockInitialValues(Map<String, dynamic>());

  var host = await Host.create();
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

    final badURL = 'bad-polaris-url';
    final client = getIt<Client>();
    when(client.get(badURL + '/api/version')).thenThrow('bad host');

    await tester.enterText(urlInputField, badURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorNetwork), findsOneWidget);
  });
}
