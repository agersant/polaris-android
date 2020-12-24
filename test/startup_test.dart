import 'mock/client.dart' as client;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/main.dart';
import 'package:polaris/manager/connection.dart' as connection;
import 'package:polaris/service/api.dart';
import 'package:polaris/service/host.dart';
import 'package:polaris/service/http_api.dart';
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

final urlInputField = find.widgetWithText(TextFormField, serverURLFieldLabel);
final connectButton = find.widgetWithText(ElevatedButton, connectButtonLabel);
final disconnectButton = find.widgetWithText(FlatButton, disconnectButtonLabel);

Future _setup({Map<String, dynamic> preferences}) async {
  SharedPreferences.setMockInitialValues(preferences != null ? preferences : Map());

  getIt.allowReassignment = true;

  getIt.registerSingleton<Host>(await Host.create());
  getIt.registerSingleton<Client>(client.Mock());
  getIt.registerSingleton<API>(HttpAPI());
  getIt.registerSingleton<connection.Manager>(connection.Manager());
}

void main() {
  testWidgets('Connect screen shows error when failing to connect', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    await tester.enterText(urlInputField, client.badHostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorNetwork), findsOneWidget);
  });

  testWidgets('Connect screen shows error when connecting to incompatible server', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    await tester.enterText(urlInputField, client.incompatibleHostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorAPIVersion), findsOneWidget);
  });

  testWidgets('Connect screen golden path', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    await tester.enterText(urlInputField, client.goodhostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(urlInputField, findsNothing);
  });

  testWidgets('Reconnects on startup', (WidgetTester tester) async {
    await _setup(preferences: {serverURLKey: client.goodhostURL});

    await tester.pumpWidget(PolarisApp());

    expect(connectButton, findsNothing);
    expect(disconnectButton, findsOneWidget);
  });

  testWidgets('Failed reconnect shows connect screen', (WidgetTester tester) async {
    await _setup(preferences: {serverURLKey: client.badHostURL});

    await tester.pumpWidget(PolarisApp());

    expect(connectButton, findsOneWidget);
    expect(disconnectButton, findsNothing);
  });

  testWidgets('Disconnect returns to connect screen', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    await tester.enterText(urlInputField, client.goodhostURL);
    await tester.tap(connectButton);
    await tester.pump();
    expect(urlInputField, findsNothing);

    await tester.tap(disconnectButton);
    await tester.pump();
    expect(urlInputField, findsOneWidget);
  });
}
