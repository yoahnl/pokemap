import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  setUpAll(() async {
    await (FontLoader(
      'packages/map_player_ui/PokeMapSplashDMSans',
    )..addFont(rootBundle.load('assets/fonts/DMSans-Variable.ttf'))).load();
  });
  for (final dark in [false, true]) {
    for (final scale in [1.0, 2.0]) {
      testWidgets(
        'companion keyboard keeps its field and typed commands dark=$dark text=$scale',
        (tester) async {
          final results = <SceneInteractionResult>[];
          await _mount(tester, results, dark: dark, scale: scale);
          final rail = find.byKey(const ValueKey('scene-keyboard-sidebar'));
          final first = find.byKey(const ValueKey('scene-keyboard-char-A'));
          final field = tester.widget<TextField>(
            find.byKey(const ValueKey('scene-interaction-text-field')),
          );
          expect(field.readOnly, isTrue);
          if (scale == 1) {
            final grid = tester.getRect(
              find.byKey(const ValueKey('scene-keyboard-grid')),
            );
            final sidebar = tester.getRect(rail);
            expect(sidebar.width, 120);
            expect(grid.left - sidebar.right, closeTo(8, .5));
            expect(
              tester
                  .getRect(
                    find.byKey(const ValueKey('scene-interaction-text-field')),
                  )
                  .right,
              lessThanOrEqualTo(sidebar.right),
            );
            final row = ['A', 'Z', 'E', 'R', 'T', 'Y']
                .map(
                  (letter) => tester.getRect(
                    find.byKey(ValueKey('scene-keyboard-char-$letter')),
                  ),
                )
                .toList();
            expect(row.map((rect) => rect.top).toSet(), hasLength(1));
            for (var i = 0; i < row.length; i++) {
              expect(row[i].width, greaterThanOrEqualTo(48));
              expect(row[i].height, greaterThanOrEqualTo(48));
              if (i > 0) expect(row[i].left - row[i - 1].right, closeTo(8, .5));
            }
          } else {
            expect(rail, findsNothing);
          }
          await tester.tap(first);
          await tester.pumpAndSettle();
          expect(field.controller!.text, 'A');
          await tester.tap(find.byKey(const ValueKey('scene-keyboard-erase')));
          await tester.pumpAndSettle();
          expect(field.controller!.text, isEmpty);
          await tester.tap(first);
          await tester.pumpAndSettle();
          await tester.tap(
            find.byKey(const ValueKey('scene-interaction-text-submit')),
          );
          await tester.pumpAndSettle();
          final result = results.single as SceneTextSubmittedInteractionResult;
          expect(result.requestId, 'companion-name');
          expect(result.revision, 17);
          expect(result.value, 'A');
          expect(
            find
                .byType(Scrollable)
                .evaluate()
                .where(
                  (element) =>
                      element.findAncestorWidgetOfExactType<EditableText>() ==
                      null,
                ),
            isEmpty,
            reason: 'Only the native EditableText viewport may scroll.',
          );
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
  testWidgets(
    'initial name fits the companion field without horizontal scrolling',
    (tester) async {
      await _mount(tester, <SceneInteractionResult>[], initialValue: 'Yoahn');
      final editable = find.byType(EditableText);
      expect(tester.widget<EditableText>(editable).controller.text, 'Yoahn');
      final viewport = find.descendant(
        of: editable,
        matching: find.byType(Scrollable),
      );
      final position = tester.state<ScrollableState>(viewport).position;
      expect(position.maxScrollExtent, closeTo(0, .1));
      expect(position.pixels, closeTo(0, .1));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'authored windows retain the existing companion form composition',
    (tester) async {
      await _mount(tester, <SceneInteractionResult>[], authored: true);
      expect(
        find.byKey(const ValueKey('scene-keyboard-sidebar')),
        findsNothing,
      );
      expect(find.byType(PlayerPanel), findsOneWidget);
      expect(
        find.byKey(const ValueKey('scene-controller-keyboard')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('disabled companion requests cannot edit or submit', (
    tester,
  ) async {
    final results = <SceneInteractionResult>[];
    await _mount(tester, results, enabled: false);
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey('scene-interaction-text-field')),
    );
    await tester.tap(find.byKey(const ValueKey('scene-keyboard-char-A')));
    await tester.pumpAndSettle();
    expect(field.controller!.text, isEmpty);
    expect(
      tester
          .widget<PlayerActionButton>(
            find.byKey(const ValueKey('scene-interaction-text-submit')),
          )
          .onPressed,
      isNull,
    );
    expect(results, isEmpty);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _mount(
  WidgetTester tester,
  List<SceneInteractionResult> results, {
  bool dark = true,
  double scale = 1,
  bool authored = false,
  bool enabled = true,
  String initialValue = '',
}) async {
  tester.view.physicalSize = const Size(496, 432);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  var theme = dark ? PokeMapPlayerTheme.dark() : PokeMapPlayerTheme.light();
  if (authored) {
    theme = PokeMapPlayerTheme.withWindowProfile(
      theme,
      legacyProjectPresentationWindows,
    );
  }
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: theme,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: child!,
      ),
      home: PlayerCompanionScope(
        child: PlayerInputScope(
          activeInputSource: PlayerInputSource.controller,
          child: PlayerSceneInteractionSurface(
            request: SceneInteractionRequest.text(
              requestId: 'companion-name',
              revision: 17,
              initialValue: initialValue,
              prompt: SceneInteractionPrompt(
                localizationKey: 'name',
                fallbackText: 'Votre nom',
              ),
              constraints: SceneTextInputConstraints(
                minGraphemes: 1,
                maxGraphemes: 12,
              ),
            ),
            onResult: results.add,
            interactionEnabled: enabled,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
