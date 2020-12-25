import 'mock/client.dart' as client;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart';
import 'package:polaris/main.dart';
import 'package:polaris/platform/api.dart';
import 'package:polaris/platform/authentication.dart' as authentication;
import 'package:polaris/platform/connection.dart' as connection;
import 'package:polaris/platform/http_api.dart';
import 'package:polaris/platform/host.dart' as host;
import 'package:polaris/platform/token.dart' as token;
import 'package:polaris/ui/startup/connect.dart';
import 'package:polaris/ui/startup/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

final urlInputField = find.widgetWithText(TextFormField, serverURLFieldLabel);
final connectButton = find.widgetWithText(ElevatedButton, connectButtonLabel);

final usernameInputField = find.widgetWithText(TextFormField, usernameFieldLabel);
final passwordInputField = find.widgetWithText(TextFormField, passwordFieldLabel);
final disconnectButton = find.widgetWithText(FlatButton, disconnectButtonLabel);
final loginButton = find.widgetWithText(ElevatedButton, loginButtonLabel);

class Context {
  final client.Mock mockClient;
  Context(this.mockClient);
}

Future<Context> _setup({Map<String, dynamic> preferences}) async {
  SharedPreferences.setMockInitialValues(preferences != null ? preferences : Map());

  getIt.allowReassignment = true;

  getIt.registerSingleton<host.Manager>(await host.Manager.create());
  getIt.registerSingleton<token.Manager>(await token.Manager.create());

  final mockClient = client.Mock();
  getIt.registerSingleton<Client>(mockClient);
  getIt.registerSingleton<API>(HttpAPI());

  getIt.registerSingleton<connection.Manager>(connection.Manager());
  getIt.registerSingleton<authentication.Manager>(authentication.Manager());

  return Context(mockClient);
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
    await tester.pumpAndSettle();
    expect(urlInputField, findsNothing);
  });

  testWidgets('Reconnects on startup', (WidgetTester tester) async {
    await _setup(preferences: {host.preferenceKey: client.goodhostURL});

    await tester.pumpWidget(PolarisApp());

    expect(connectButton, findsNothing);
    expect(disconnectButton, findsOneWidget);
  });

  testWidgets('Failed reconnect shows connect screen', (WidgetTester tester) async {
    await _setup(preferences: {host.preferenceKey: client.badHostURL});

    await tester.pumpWidget(PolarisApp());

    expect(connectButton, findsOneWidget);
    expect(disconnectButton, findsNothing);
  });

  testWidgets('Failed reconnect shows attempted URL screen', (WidgetTester tester) async {
    await _setup(preferences: {host.preferenceKey: client.badHostURL});

    await tester.pumpWidget(PolarisApp());

    final inputField = urlInputField.evaluate().single.widget as TextFormField;
    expect(inputField.controller.text, equals(client.badHostURL));
  });

  testWidgets('Disconnect returns to connect screen', (WidgetTester tester) async {
    await _setup();

    await tester.pumpWidget(PolarisApp());

    await tester.enterText(urlInputField, client.goodhostURL);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(urlInputField, findsNothing);

    await tester.tap(disconnectButton);
    await tester.pumpAndSettle();
    expect(urlInputField, findsOneWidget);
  });

  testWidgets('Login screen rejects bad credentials', (WidgetTester tester) async {
    Context context = await _setup(preferences: {host.preferenceKey: client.goodhostURL});
    context.mockClient.mockBadLogin();

    await tester.pumpWidget(PolarisApp());

    await tester.enterText(usernameInputField, client.badUsername);
    await tester.enterText(passwordInputField, 'bad-password');
    await tester.tap(loginButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorIncorrectCredentials), findsOneWidget);
  });
}
