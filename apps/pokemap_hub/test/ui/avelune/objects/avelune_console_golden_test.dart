import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_loadGoldenFonts);

  testWidgets('Avelune console idle visual gate', (tester) async {
    await _pumpConsole(tester, state: AveluneConsoleState.idle);
    await _expectGolden('phase3_console_idle_760x300.png');
  });

  testWidgets('Avelune console insertion visual gate', (tester) async {
    await _pumpConsole(tester, insertionProgress: 0.5);
    await _expectGolden('phase3_console_inserting_760x300.png');
  });

  testWidgets('Avelune console latched visual gate', (tester) async {
    await _pumpConsole(
      tester,
      state: AveluneConsoleState.latched,
      insertionProgress: 1,
    );
    await _expectGolden('phase3_console_latched_760x300.png');
  });

  testWidgets('Avelune console error visual gate', (tester) async {
    await _pumpConsole(tester, state: AveluneConsoleState.error);
    await _expectGolden('phase3_console_error_760x300.png');
  });

  testWidgets('Avelune console high contrast visual gate', (tester) async {
    await _pumpConsole(
      tester,
      state: AveluneConsoleState.launching,
      highContrast: true,
    );
    await _expectGolden('phase3_console_high_contrast_760x300.png');
  });
}

Future<void> _pumpConsole(
  WidgetTester tester, {
  AveluneConsoleState? state,
  double insertionProgress = 0,
  bool highContrast = false,
}) async {
  tester.view.physicalSize = const Size(760, 300);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final aveluneTheme =
      highContrast ? AveluneThemeData.highContrast : AveluneThemeData.standard;
  final theme = aveluneTheme.applyTo(ThemeData.dark());

  await tester.pumpWidget(
    MaterialApp(
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'AveluneGoldenSans'),
      ),
      home: RepaintBoundary(
        key: const ValueKey<String>('avelune-console-golden-root'),
        child: Scaffold(
          body: ColoredBox(
            color: aveluneTheme.colors.canvas,
            child: Center(
              child: SizedBox(
                width: 680,
                child: AveluneConsole(
                  state: state,
                  insertionProgress: insertionProgress,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  final context = tester.element(find.byType(AveluneConsole));
  await tester.runAsync(
    () => Future.wait<void>(
      AveluneMaterialCatalog.consoleLayers.map(
        (asset) => precacheImage(AssetImage(asset.path), context),
      ),
    ),
  );
  await tester.pumpAndSettle();
  _markSubtreeNeedsPaint(
    tester.renderObject(
      find.byKey(const ValueKey<String>('avelune-console-golden-root')),
    ),
  );
  await tester.pump();
  expect(tester.takeException(), isNull);
}

Future<void> _expectGolden(String path) => expectLater(
      find.byKey(const ValueKey<String>('avelune-console-golden-root')),
      matchesGoldenFile('../../goldens/avelune/$path'),
    );

void _markSubtreeNeedsPaint(RenderObject object) {
  object.markNeedsPaint();
  object.visitChildren(_markSubtreeNeedsPaint);
}

Future<void> _loadGoldenFonts() async {
  final bytes = await File(
    '../../packages/map_editor/assets/fonts/pokemap_capture_sans_regular.ttf',
  ).readAsBytes();
  final loader = FontLoader('AveluneGoldenSans')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await loader.load();
}
