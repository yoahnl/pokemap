// ignore_for_file: prefer_const_constructors — fixtures MapData volontairement non const pour lisibilité

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_environment_section.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../../../shell_chrome_test_harness.dart';

void main() {
  testWidgets('stays out of the way when the layer has no environment',
      (tester) async {
    final harness = _Harness(_mapWithoutEnvironment(), activeLayerId: 'tiles');
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(
      find.byKey(const ValueKey<String>('world-map-environment-section')),
      findsNothing,
    );
  });

  testWidgets('opens a zone from the only published preset', (tester) async {
    final harness = _Harness(
      _mapWithEnvironment(areas: const <EnvironmentArea>[]),
      activeLayerId: 'tiles',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(
      find.byKey(const ValueKey<String>('world-map-environment-section')),
      findsOneWidget,
    );
    // A single preset needs no picker.
    expect(
      find.byKey(const ValueKey<String>('world-map-environment-preset')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-environment-create-area')),
    );
    await tester.pump();

    final layer = harness.notifier.state.activeMap!.layers
        .whereType<EnvironmentLayer>()
        .single;
    expect(layer.content.areas, hasLength(1));
    expect(layer.content.areas.single.presetId, 'preset1');
  });

  testWidgets('toggles mask painting on and back off', (tester) async {
    final harness = _Harness(
      _mapWithEnvironment(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final paint =
        find.byKey(const ValueKey<String>('world-map-environment-mask-paint'));
    await tester.tap(paint);
    await tester.pump();
    expect(
      harness.notifier.state.environmentMaskEditMode,
      EnvironmentMaskEditMode.paint,
    );

    await tester.tap(paint);
    await tester.pump();
    expect(harness.notifier.state.environmentMaskEditMode, isNull);
  });

  testWidgets('generates placements once the mask is painted', (tester) async {
    final harness = _Harness(
      _mapWithEnvironment(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.text('Générer'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-environment-generate')),
    );
    await tester.pump();

    expect(harness.notifier.state.activeMap!.placedElements, isNotEmpty);
    // A second pass is a regeneration, not a duplicate generation.
    expect(find.text('Régénérer'), findsOneWidget);
  });

  testWidgets('refuses to generate while a mask gesture is open',
      (tester) async {
    final harness = _Harness(
      _mapWithEnvironment(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
      environmentMaskEditMode: EnvironmentMaskEditMode.paint,
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final generate = tester.widget<PokeMapButton>(
      find.byKey(const ValueKey<String>('world-map-environment-generate')),
    );
    expect(generate.onPressed, isNull);
  });
}

final class _Harness {
  _Harness(
    MapData map, {
    required String activeLayerId,
    String? selectedEnvironmentAreaId,
    EnvironmentMaskEditMode? environmentMaskEditMode,
  }) : container = ProviderContainer() {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      projectRootPath: '/virtual/project',
      project: _manifest(),
      activeMap: map,
      activeMapPath: 'maps/x.json',
      activeLayerId: activeLayerId,
      selectedEnvironmentAreaId: selectedEnvironmentAreaId,
      environmentMaskEditMode: environmentMaskEditMode,
      savedMapSnapshot: map,
    );
  }

  final ProviderContainer container;
  late final ProviderSubscription<EditorState> keepAlive;

  EditorNotifier get notifier =>
      container.read(editorNotifierProvider.notifier);

  Future<void> pump(WidgetTester tester) {
    return tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: PokeMapTheme.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 760,
              child: SingleChildScrollView(
                child: const WorldMapEnvironmentSection(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void dispose() {
    keepAlive.close();
    container.dispose();
  }
}

EnvironmentPreset _preset() {
  return EnvironmentPreset(
    id: 'preset1',
    name: 'Forêt',
    templateId: 't',
    palette: [
      EnvironmentPaletteItem(elementId: 'e1', weight: 1),
    ],
    defaultParams: EnvironmentGenerationParams(
      density: 1,
      edgeDensity: 1,
      variation: 0,
      minSpacingCells: 0,
    ),
    sortOrder: 0,
  );
}

ProjectManifest _manifest() {
  return buildShellChromeProject(
    environmentPresets: [_preset()],
    elements: [
      ProjectElementEntry(
        id: 'e1',
        name: 'El',
        tilesetId: 'tsA',
        categoryId: 'cat',
        frames: const [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
  );
}

EnvironmentArea _area() {
  return EnvironmentArea(
    id: 'area1',
    name: 'Zone',
    presetId: 'preset1',
    mask: EnvironmentAreaMask(
      width: 2,
      height: 2,
      cells: List<bool>.filled(4, true),
    ),
    seed: 1,
  );
}

TileLayer _tiles() {
  return TileLayer(
    id: 'tiles',
    name: 'Tuiles',
    cells: List<int>.filled(4, 0),
  );
}

MapData _mapWithoutEnvironment() {
  return MapData(
    id: 'm1',
    name: 'M1',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'tsA',
    layers: [_tiles()],
  );
}

MapData _mapWithEnvironment({required List<EnvironmentArea> areas}) {
  return MapData(
    id: 'm1',
    name: 'M1',
    size: const GridSize(width: 2, height: 2),
    tilesetId: 'tsA',
    layers: [
      MapLayer.environment(
        id: 'env',
        name: 'Environnement',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: areas,
        ),
      ),
      _tiles(),
    ],
  );
}
