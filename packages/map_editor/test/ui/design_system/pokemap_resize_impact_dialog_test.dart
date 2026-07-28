import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_resize_impact_dialog.dart';

void main() {
  testWidgets('starts as a no-op and applies a proven safe expansion',
      (tester) async {
    PokeMapResizeTarget? selected;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        selected = await showPokeMapResizeImpactDialog(
          context,
          currentWidth: 3,
          currentHeight: 3,
          buildPlan: _safePlan,
        );
      },
    );

    await tester.tap(find.text('Redimensionner'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapResizeImpactDialogKey), findsOneWidget);
    expect(find.text('Taille actuelle : 3 × 3 cases'), findsOneWidget);
    expect(find.text('Aucune modification'), findsOneWidget);
    expect(_applyButton(tester).onPressed, isNull);

    await tester.enterText(
      find.byKey(pokeMapResizeWidthFieldKey),
      '5',
    );
    await tester.enterText(
      find.byKey(pokeMapResizeHeightFieldKey),
      '4',
    );
    await _settlePlan(tester);

    expect(find.text('Aucune perte détectée'), findsOneWidget);
    expect(find.text('La carte sera agrandie à 5 × 4 cases.'), findsOneWidget);
    expect(_applyButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(pokeMapResizeApplyButtonKey));
    await tester.pumpAndSettle();

    expect(selected, const PokeMapResizeTarget(width: 5, height: 4));
    expect(find.byKey(pokeMapResizeImpactDialogKey), findsNothing);
  });

  testWidgets('lists destructive impacts and never exposes an override',
      (tester) async {
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapResizeImpactDialog(
        context,
        currentWidth: 3,
        currentHeight: 3,
        buildPlan: (width, height) => MapResizePlan(
          sourceSize: const GridSize(width: 3, height: 3),
          targetSize: GridSize(width: width, height: height),
          impacts: width < 3
              ? <MapResizeImpact>[
                  MapResizeImpact(
                    kind: MapResizeImpactKind.entity,
                    reason: MapResizeImpactReason.footprintOutside,
                    subjectId: 'house',
                    subjectLabel: 'Maison du joueur',
                    affectedCount: 2,
                    positions: const <GridPos>[
                      GridPos(x: 2, y: 1),
                      GridPos(x: 2, y: 2),
                    ],
                  ),
                ]
              : const <MapResizeImpact>[],
        ),
      ),
    );

    await tester.tap(find.text('Redimensionner'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(pokeMapResizeWidthFieldKey),
      '2',
    );
    await _settlePlan(tester);

    expect(find.text('Redimensionnement bloqué'), findsOneWidget);
    expect(find.textContaining('1 impact bloquant'), findsOneWidget);
    expect(find.text('Maison du joueur'), findsOneWidget);
    expect(find.textContaining('2 cases'), findsOneWidget);
    expect(_applyButton(tester).onPressed, isNull);
    expect(find.textContaining('Forcer'), findsNothing);
  });

  testWidgets('validates positive integer dimensions before planning',
      (tester) async {
    var planCalls = 0;
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapResizeImpactDialog(
        context,
        currentWidth: 3,
        currentHeight: 3,
        buildPlan: (width, height) {
          planCalls += 1;
          return _safePlan(width, height);
        },
      ),
    );

    await tester.tap(find.text('Redimensionner'));
    await tester.pumpAndSettle();
    final callsBeforeInvalidInput = planCalls;
    await tester.enterText(
      find.byKey(pokeMapResizeHeightFieldKey),
      '0',
    );
    await _settlePlan(tester);

    expect(
      find.text('Utilisez un entier supérieur à 0.'),
      findsOneWidget,
    );
    expect(planCalls, callsBeforeInvalidInput);
    expect(_applyButton(tester).onPressed, isNull);
  });
}

MapResizePlan _safePlan(int width, int height) => MapResizePlan(
      sourceSize: const GridSize(width: 3, height: 3),
      targetSize: GridSize(width: width, height: height),
      impacts: const <MapResizeImpact>[],
    );

PokeMapButton _applyButton(WidgetTester tester) => tester.widget<PokeMapButton>(
      find.byKey(pokeMapResizeApplyButtonKey),
    );

Future<void> _settlePlan(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pumpAndSettle();
}

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
}) async {
  tester.view.physicalSize = const Size(1200, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      theme: PokeMapTheme.dark(),
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () => onLaunch(context),
            child: const Text('Redimensionner'),
          ),
        ),
      ),
    ),
  );
}
