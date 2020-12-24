import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/api/api.dart';
import 'package:polaris/api/host.dart';
import 'package:polaris/api/http_api.dart';
import 'package:polaris/main.dart';
import 'package:polaris/store/connection.dart';
import 'package:polaris/ui/startup/connect.dart';
import 'package:shared_preferences/shared_preferences.dart';

final getIt = GetIt.instance;

Future _setup() async {
  // https://github.com/flutter/flutter/issues/65606
  HttpOverrides.global = null;
  SharedPreferences.setMockInitialValues(Map<String, dynamic>());

  var host = await Host.create();
  getIt.registerSingleton<Host>(host);
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

    await tester.enterText(urlInputField, 'bad-polaris-url');
    await tester.tap(connectButton);
    await tester.pump();
    expect(find.widgetWithText(SnackBar, errorNetwork), findsOneWidget);
  });
}
