import 'harness.dart';
import 'mock/client.dart' as client;
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/core/connection.dart' as connection;
import 'package:polaris/core/authentication.dart' as authentication;
import 'package:polaris/core/dto.dart' as dto;
import 'package:polaris/main.dart';
import 'package:polaris/ui/startup/page.dart';
import 'package:polaris/ui/strings.dart';

final startupPage = find.byType(StartupPage);

final urlInputField = find.widgetWithText(TextFormField, serverURLFieldLabel);
final connectButton = find.widgetWithText(ElevatedButton, connectButtonLabel);

final usernameInputField = find.widgetWithText(TextFormField, usernameFieldLabel);
final passwordInputField = find.widgetWithText(TextFormField, passwordFieldLabel);
final disconnectButton = find.widgetWithText(TextButton, disconnectButtonLabel);
final loginButton = find.widgetWithText(ElevatedButton, loginButtonLabel);

void main() {
  testWidgets('Connect screen shows error when failing to connect', (WidgetTester tester) async {
    await Harness.create();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.badHostURI);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorRequestFailed), findsOneWidget);
  });

  testWidgets('Connect screen shows error when connecting to incompatible server', (WidgetTester tester) async {
    await Harness.create();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.incompatibleHostURI);
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorAPIVersion), findsOneWidget);
    expect(urlInputField, findsOneWidget);
    expect(connectButton, findsOneWidget);
  });

  testWidgets('Connect screen golden path', (WidgetTester tester) async {
    await Harness.create();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.goodHostURI);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(urlInputField, findsNothing);
    expect(connectButton, findsNothing);
  });

  testWidgets('Connect screens works without HTTP prefix in host URL', (WidgetTester tester) async {
    await Harness.create();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.goodHost);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(urlInputField, findsNothing);
    expect(connectButton, findsNothing);
  });

  testWidgets('Connect screens works with trailing slash in host URL', (WidgetTester tester) async {
    await Harness.create();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.trailingSlashHostURI);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(urlInputField, findsNothing);
    expect(connectButton, findsNothing);
  });

  testWidgets('Connect screen can timeout', (WidgetTester tester) async {
    final harness = await Harness.create();
    const networkDelay = Duration(seconds: 10);
    harness.mockHTTPClient.setNetworkDelay(networkDelay);

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.goodHostURI);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();

    expect(find.widgetWithText(SnackBar, errorTimeout), findsOneWidget);
    expect(urlInputField, findsOneWidget);
    expect(connectButton, findsOneWidget);

    await tester.pumpAndSettle(networkDelay);
  });

  testWidgets('Reconnects on startup', (WidgetTester tester) async {
    await Harness.create(preferences: {connection.hostPreferenceKey: client.goodHostURI});

    await tester.pumpWidget(const PolarisApp());

    expect(connectButton, findsNothing);
    expect(disconnectButton, findsOneWidget);
  });

  testWidgets('Failed reconnect shows connect screen', (WidgetTester tester) async {
    await Harness.create(preferences: {connection.hostPreferenceKey: client.badHostURI});

    await tester.pumpWidget(const PolarisApp());

    expect(connectButton, findsOneWidget);
    expect(disconnectButton, findsNothing);
  });

  testWidgets('Failed reconnect shows attempted URL', (WidgetTester tester) async {
    await Harness.create(preferences: {connection.hostPreferenceKey: client.badHostURI});

    await tester.pumpWidget(const PolarisApp());

    final inputField = urlInputField.evaluate().single.widget as TextFormField;
    expect(inputField.controller?.text, equals(client.badHostURI));
  });

  testWidgets('Failed reconnect does not wipe auth token', (WidgetTester tester) async {
    await Harness.create(preferences: {
      connection.hostPreferenceKey: client.badHostURI,
      authentication.authHostPreferenceKey: client.goodHostURI,
      authentication.tokenPreferenceKey: 'auth-token',
      authentication.usernamePreferenceKey: 'good-username'
    });

    await tester.pumpWidget(const PolarisApp());
    expect(connectButton, findsOneWidget);

    await tester.enterText(urlInputField, client.goodHostURI);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(startupPage, findsNothing);
  });

  testWidgets('Failed re-login lands on login screen', (WidgetTester tester) async {
    final harness = await Harness.create(preferences: {
      connection.hostPreferenceKey: client.goodHostURI,
      authentication.authHostPreferenceKey: client.goodHostURI,
      authentication.tokenPreferenceKey: 'auth-token',
      authentication.usernamePreferenceKey: 'bad-username'
    });

    harness.mockHTTPClient.mockUnauthorized();
    await tester.pumpWidget(const PolarisApp());

    expect(loginButton, findsOneWidget);
  });

  testWidgets('Disconnect returns to connect screen', (WidgetTester tester) async {
    await Harness.create();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(urlInputField, client.goodHostURI);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();
    expect(urlInputField, findsNothing);

    await tester.tap(disconnectButton);
    await tester.pumpAndSettle();
    expect(connectButton, findsOneWidget);
  });

  testWidgets('Login screen rejects bad credentials', (WidgetTester tester) async {
    Harness harness = await Harness.create(preferences: {connection.hostPreferenceKey: client.goodHostURI});
    harness.mockHTTPClient.mockUnauthorized();

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(usernameInputField, 'bad-username');
    await tester.enterText(passwordInputField, 'bad-password');
    await tester.tap(loginButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorIncorrectCredentials), findsOneWidget);
    expect(loginButton, findsOneWidget);
  });

  testWidgets('Login screen golden path', (WidgetTester tester) async {
    await Harness.create(preferences: {connection.hostPreferenceKey: client.goodHostURI});

    await tester.pumpWidget(const PolarisApp());

    await tester.enterText(usernameInputField, 'good-username');
    await tester.enterText(passwordInputField, 'good-password');
    await tester.tap(loginButton);
    await tester.pump();
    expect(startupPage, findsNothing);
  });

  testWidgets('Re-logins on startup', (WidgetTester tester) async {
    await Harness.create(preferences: {
      connection.hostPreferenceKey: client.goodHostURI,
      authentication.authHostPreferenceKey: client.goodHostURI,
      authentication.tokenPreferenceKey: 'auth-token',
      authentication.usernamePreferenceKey: 'good-username'
    });

    await tester.pumpWidget(const PolarisApp());
    expect(startupPage, findsNothing);
  });

  testWidgets('Failed connection offers offline mode', (WidgetTester tester) async {
    final harness = await Harness.create();

    final song = dto.CollectionFile(Left(dto.Song(path: client.labyrinthFilePath)));
    harness.collectionCache.putDirectory(client.badHostURI, client.aegeusDirectoryPath, [song]);

    await tester.pumpWidget(const PolarisApp());
    await tester.enterText(urlInputField, client.badHostURI);
    await tester.tap(connectButton);
    await tester.pumpAndSettle();

    final offlineModeButton = find.widgetWithText(SnackBarAction, offlineModeButtonLabel);
    expect(offlineModeButton, findsOneWidget);
    await tester.tap(offlineModeButton);
    await tester.pumpAndSettle();
    expect(startupPage, findsNothing);
  });
}
