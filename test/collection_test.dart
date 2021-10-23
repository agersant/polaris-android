import 'harness.dart';
import 'mock/client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:polaris/main.dart';
import 'package:polaris/ui/collection/browser.dart';

final rootDirectory = find.text(rootDirectoryName);
final heronDirectory = find.text(heronDirectoryName);
final aegeusDirectory = find.text(aegeusDirectoryName);
final labyrinthSong = find.text(labyrinthSongName);
final rootBreadcrumb = find.widgetWithText(Breadcrumb, rootDirectoryName);
final heronBreadcrumb = find.widgetWithText(Breadcrumb, heronDirectoryName);
final aegeusBreadcrumb = find.widgetWithText(Breadcrumb, aegeusDirectoryName);

void main() {
  testWidgets('Shows browse tab on start', (WidgetTester tester) async {
    await Harness.reconnect();
    await tester.pumpWidget(PolarisApp());
    await tester.pumpAndSettle();
    expect(rootDirectory, findsOneWidget);
  });

  testWidgets('Can open browser directories', (WidgetTester tester) async {
    await Harness.reconnect();
    await tester.pumpWidget(PolarisApp());

    await tester.pumpAndSettle();
    expect(rootDirectory, findsOneWidget);
    expect(heronDirectory, findsNothing);
    expect(aegeusDirectory, findsNothing);

    await tester.tap(rootDirectory);
    await tester.pumpAndSettle();
    expect(heronDirectory, findsOneWidget);
    expect(aegeusDirectory, findsNothing);

    await tester.tap(heronDirectory);
    await tester.pumpAndSettle();
    expect(aegeusDirectory, findsOneWidget);
  });

  testWidgets('Browser shows breadcrumbs', (WidgetTester tester) async {
    await Harness.reconnect();
    await tester.pumpWidget(PolarisApp());
    await tester.pumpAndSettle();

    await tester.tap(rootDirectory);
    await tester.pumpAndSettle();

    expect(heronBreadcrumb, findsNothing);
    await tester.tap(heronDirectory);
    await tester.pumpAndSettle();
    expect(heronBreadcrumb, findsOneWidget);

    await tester.pumpAndSettle();
    await tester.tap(aegeusDirectory);
    expect(heronBreadcrumb, findsOneWidget);
  });

  testWidgets('Can navigate backwards using browser breadcrumbs', (WidgetTester tester) async {
    await Harness.reconnect();
    await tester.pumpWidget(PolarisApp());
    await tester.pumpAndSettle();

    await tester.tap(rootDirectory);
    await tester.pumpAndSettle();

    await tester.tap(heronDirectory);
    await tester.pumpAndSettle();

    expect(aegeusDirectory, findsOneWidget);
    await tester.tap(rootDirectory);
    await tester.pumpAndSettle();
    expect(aegeusDirectory, findsNothing);
  });
}
