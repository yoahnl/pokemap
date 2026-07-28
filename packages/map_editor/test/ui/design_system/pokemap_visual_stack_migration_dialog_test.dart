import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/map_visual_stack_migration_use_case.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/pokemap_button.dart';
import 'package:map_editor/src/ui/design_system/pokemap_visual_stack_migration_dialog.dart';

void main() {
  testWidgets('shows async loading before the real render preview resolves',
      (tester) async {
    final completer = Completer<EditorMapVisualStackMigrationPreview>();
    await _pumpLauncher(
      tester,
      onLaunch: (context) => showPokeMapVisualStackMigrationDialog(
        context,
        preview: completer.future,
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pump();

    expect(find.text('Calcul du rendu réel…'), findsOneWidget);
    expect(_applyButton(tester).isLoading, isTrue);
    expect(_applyButton(tester).onPressed, isNull);

    completer.complete(await _preview(_legacyMap()));
    await tester.pumpAndSettle();

    expect(find.text('Calcul du rendu réel…'), findsNothing);
    expect(find.text('Migration prête'), findsOneWidget);
  });

  testWidgets('shows before/after and returns the exact reviewed preview',
      (tester) async {
    final preview = await _preview(_legacyMap());
    EditorMapVisualStackMigrationPreview? accepted;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        accepted = await showPokeMapVisualStackMigrationDialog(
          context,
          preview: Future.value(preview),
        );
      },
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.byKey(pokeMapVisualStackMigrationDialogKey), findsOneWidget);
    expect(find.text('Migration prête'), findsOneWidget);
    expect(find.text('Comparaison des pixels RGBA rendus'), findsOneWidget);
    expect(find.text('Legacy'), findsOneWidget);
    expect(find.text('Canonique v1'), findsOneWidget);
    expect(find.text('Différences de composition'), findsOneWidget);
    expect(
      find.text('J’ai compris les changements affichés'),
      findsOneWidget,
    );
    expect(find.textContaining('Tuiles de fond — Tile (tile)'), findsWidgets);
    expect(find.textContaining('surfaceLayer:'), findsNothing);
    expect(find.textContaining('fnv1a32:'), findsNothing);
    expect(_applyButton(tester).onPressed, isNull);

    await tester.ensureVisible(
      find.byKey(pokeMapVisualStackMigrationConsentKey),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(pokeMapVisualStackMigrationConsentKey));
    await tester.pump();
    expect(_applyButton(tester).onPressed, isNotNull);

    await tester.tap(find.byKey(pokeMapVisualStackMigrationApplyKey));
    await tester.pumpAndSettle();

    expect(accepted, same(preview));
    expect(find.byKey(pokeMapVisualStackMigrationDialogKey), findsNothing);
  });

  testWidgets('future semantics stay inspectable and read-only',
      (tester) async {
    final preview = await _preview(
      MapData(
        id: 'future',
        name: 'Future',
        size: const GridSize(width: 1, height: 1),
        version: ProjectVersion.v3,
        visualStack: MapVisualStackConfig(semanticsVersion: 99),
      ),
    );
    await _pumpLauncher(
      tester,
      size: const Size(800, 600),
      onLaunch: (context) => showPokeMapVisualStackMigrationDialog(
        context,
        preview: Future.value(preview),
      ),
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();

    expect(find.text('Migration bloquée — lecture seule'), findsOneWidget);
    expect(find.textContaining('99'), findsOneWidget);
    expect(find.text('Plan indisponible'), findsNWidgets(2));
    expect(find.text('Comparaison des pixels RGBA rendus'), findsNothing);
    expect(_applyButton(tester).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel button returns null without a typed-route error',
      (tester) async {
    EditorMapVisualStackMigrationPreview? result;
    var completed = false;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapVisualStackMigrationDialog(
          context,
          preview: _preview(_legacyMap()),
        );
        completed = true;
      },
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Escape returns null without a typed-route error',
      (tester) async {
    EditorMapVisualStackMigrationPreview? result;
    var completed = false;
    await _pumpLauncher(
      tester,
      onLaunch: (context) async {
        result = await showPokeMapVisualStackMigrationDialog(
          context,
          preview: _preview(_legacyMap()),
        );
        completed = true;
      },
    );

    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    expect(completed, isTrue);
    expect(result, isNull);
    expect(tester.takeException(), isNull);
  });
}

Future<EditorMapVisualStackMigrationPreview> _preview(MapData map) =>
    const MapVisualStackMigrationUseCase().preview(
      map,
      compareRenderedPixels: ({required before, required after}) async =>
          MapVisualStackPixelComparison(
        width: 16,
        height: 16,
        changedPixelCount: 1,
        changedBounds: const MapVisualStackPixelBounds(
          left: 0,
          top: 0,
          right: 0,
          bottom: 0,
        ),
        beforeFingerprint: 'fnv1a32:before',
        afterFingerprint: 'fnv1a32:after',
        limitations: const <String>[
          'Comparaison RGBA du rendu statique de l’éditeur à t=0.',
        ],
      ),
    );

MapData _legacyMap() => const MapData(
      id: 'legacy',
      name: 'Legacy',
      size: GridSize(width: 1, height: 1),
      version: ProjectVersion.v2,
      layers: <MapLayer>[
        SurfaceLayer(
          id: 'surface',
          name: 'Surface',
          placements: <SurfaceCellPlacement>[
            SurfaceCellPlacement(
              x: 0,
              y: 0,
              surfacePresetId: 'water',
            ),
          ],
        ),
        TileLayer(
          id: 'tile',
          name: 'Tile',
          tiles: <int>[1],
        ),
      ],
    );

PokeMapButton _applyButton(WidgetTester tester) => tester.widget<PokeMapButton>(
      find.byKey(pokeMapVisualStackMigrationApplyKey),
    );

Future<void> _pumpLauncher(
  WidgetTester tester, {
  required Future<void> Function(BuildContext context) onLaunch,
  Size size = const Size(1200, 900),
}) async {
  tester.view.physicalSize = size;
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
            child: const Text('Ouvrir'),
          ),
        ),
      ),
    ),
  );
}
