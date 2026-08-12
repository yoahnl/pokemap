import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/features/personalization/application/personalization_inspector_target.dart';
import 'package:map_editor/src/features/personalization/application/personalization_preview_surface_descriptor.dart';
import 'package:map_editor/src/features/personalization/presentation/personalization_studio_shell.dart';
import 'package:map_editor/src/theme/pokemap_theme.dart';

void main() {
  final scenarios = <_StudioScenario>[
    const _StudioScenario(
      size: Size(720, 900),
      textScales: <double>[1, 2],
      layoutKey: 'personalization-studio-navigation-horizontal',
    ),
    const _StudioScenario(
      size: Size(1024, 768),
      textScales: <double>[1, 1.5],
      layoutKey: 'personalization-studio-navigation-rail',
    ),
    const _StudioScenario(
      size: Size(1440, 900),
      textScales: <double>[1],
      layoutKey: 'personalization-studio-navigation-list',
    ),
    const _StudioScenario(
      size: Size(1440, 900),
      textScales: <double>[2],
      layoutKey: 'personalization-studio-navigation-rail',
    ),
    const _StudioScenario(
      size: Size(1600, 1000),
      textScales: <double>[1],
      layoutKey: 'personalization-studio-navigation-list',
    ),
  ];

  for (final scenario in scenarios) {
    for (final textScale in scenario.textScales) {
      testWidgets(
        '${scenario.size.width}x${scenario.size.height} at ${textScale}x '
        'keeps Studio controls accessible',
        (tester) async {
          final semantics = tester.ensureSemantics();
          await _pumpShell(tester, scenario.size, textScale: textScale);

          expect(
            find.byKey(ValueKey<String>(scenario.layoutKey)),
            findsOneWidget,
          );
          for (final scene in PersonalizationStudioScene.values) {
            final target = find.byKey(
              ValueKey<String>('personalization-studio-scene-${scene.name}'),
            );
            expect(target, findsOneWidget);
            expect(tester.getSize(target).height, greaterThanOrEqualTo(48));
          }
          if (scenario.layoutKey != 'personalization-studio-navigation-list') {
            expect(
              tester
                  .getSize(
                    find.byKey(
                      const ValueKey<String>(
                        'personalization-studio-open-inspector',
                      ),
                    ),
                  )
                  .height,
              greaterThanOrEqualTo(48),
            );
          } else {
            expect(
              find.byKey(
                const ValueKey<String>(
                  'personalization-inspector-target-globalColors',
                ),
              ),
              findsNothing,
            );
            expect(
              find.byKey(
                const ValueKey<String>(
                  'personalization-studio-inspector-scroll',
                ),
              ),
              findsOneWidget,
            );
          }
          expect(find.bySemanticsLabel('Style global'), findsOneWidget);
          expect(
            find.bySemanticsLabel('Aperçu de personnalisation en direct'),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          semantics.dispose();
        },
      );
    }
  }

  testWidgets('Tab Shift Tab Enter Space and directions navigate the Studio', (
    tester,
  ) async {
    final selections = <PersonalizationStudioScene>[];
    await _pumpShell(
      tester,
      const Size(1024, 768),
      onSceneSelected: selections.add,
    );

    await _focusScene(tester, PersonalizationStudioScene.title);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(selections.last, PersonalizationStudioScene.title);

    final beforeReverse = FocusManager.instance.primaryFocus;
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(FocusManager.instance.primaryFocus, isNot(beforeReverse));
    await _focusScene(tester, PersonalizationStudioScene.globalStyle);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(selections.last, PersonalizationStudioScene.globalStyle);

    await _focusScene(tester, PersonalizationStudioScene.title);
    final beforeDirection = FocusManager.instance.primaryFocus;
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    expect(FocusManager.instance.primaryFocus, isNot(beforeDirection));
  });

  testWidgets('gamepad A activates the focused Studio scene', (tester) async {
    final selections = <PersonalizationStudioScene>[];
    await _pumpShell(
      tester,
      const Size(1440, 900),
      onSceneSelected: selections.add,
    );

    await _focusScene(tester, PersonalizationStudioScene.dialogue);
    await tester.sendKeyEvent(LogicalKeyboardKey.gameButtonA);

    expect(selections, <PersonalizationStudioScene>[
      PersonalizationStudioScene.dialogue,
    ]);
  });
}

Future<void> _pumpShell(
  WidgetTester tester,
  Size size, {
  double textScale = 1,
  ValueChanged<PersonalizationStudioScene>? onSceneSelected,
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: PersonalizationStudioShell(
            selectedScene: PersonalizationStudioScene.globalStyle,
            onSceneSelected: onSceneSelected ?? (_) {},
            preview: Semantics(
              label: 'Aperçu de personnalisation en direct',
              child: const SizedBox.expand(),
            ),
            inspectorTitle: 'Style global',
            inspectorDescription: 'Réglages communs à toutes les scènes.',
            selectedTarget: const GlobalColorsTarget(),
            onTargetSelected: (_) {},
            inspector: const Text('Inspecteur'),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _focusScene(
  WidgetTester tester,
  PersonalizationStudioScene scene,
) async {
  final target = find.byKey(
    ValueKey<String>('personalization-studio-scene-${scene.name}'),
  );
  for (var index = 0; index < 20; index += 1) {
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focusContext = FocusManager.instance.primaryFocus?.context;
    if (focusContext == null) continue;
    final focused = find.byElementPredicate(
      (element) => identical(element, focusContext),
    );
    if (find.descendant(of: target, matching: focused).evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Unable to focus ${scene.name}.');
}

final class _StudioScenario {
  const _StudioScenario({
    required this.size,
    required this.textScales,
    required this.layoutKey,
  });

  final Size size;
  final List<double> textScales;
  final String layoutKey;
}
