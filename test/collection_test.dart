import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/main.dart';

import 'harness.dart';

final rootDirectory = find.text("root");

void main() {
  testWidgets('Shows browse tab on start', (WidgetTester tester) async {
    await Harness.reconnect();
    await tester.pumpWidget(PolarisApp());
    await tester.pumpAndSettle();
    expect(rootDirectory, findsOneWidget);
  });
}
