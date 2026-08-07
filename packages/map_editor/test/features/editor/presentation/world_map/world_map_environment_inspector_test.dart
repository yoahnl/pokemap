// ignore_for_file: prefer_const_constructors — fixtures MapData volontairement non const pour lisibilité

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_environment_inspector.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/state/environment_mask_brush_size_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

import '../../../../shell_chrome_test_harness.dart';

void main() {
  testWidgets('opens a zone from the only published preset', (tester) async {
    final harness = _Harness(
      _map(areas: const <EnvironmentArea>[]),
      activeLayerId: 'tiles',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    // Nothing to tune before a zone exists.
    expect(
      find.byKey(const ValueKey<String>('world-map-environment-density')),
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
  });

  testWidgets('toggles mask painting and picks a brush size', (tester) async {
    final harness = _Harness(
      _map(areas: <EnvironmentArea>[_area()]),
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

    harness.notifier.setEnvironmentMaskBrushSize(5);
    await tester.pump();
    expect(harness.container.read(environmentMaskBrushSizeProvider), 5);

    await tester.tap(paint);
    await tester.pump();
    expect(harness.notifier.state.environmentMaskEditMode, isNull);
  });

  testWidgets('generates, then offers regenerate, shuffle and clear',
      (tester) async {
    final harness = _Harness(
      _map(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    await tester.tap(
      find.byKey(const ValueKey<String>('world-map-environment-generate')),
    );
    await tester.pump();

    expect(harness.notifier.state.activeMap!.placedElements, isNotEmpty);
    expect(find.text('Régénérer'), findsOneWidget);
    expect(
      tester
          .widget<PokeMapButton>(
            find.byKey(const ValueKey<String>('world-map-environment-clear')),
          )
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('tuning writes a per-zone override and can reset it',
      (tester) async {
    final harness = _Harness(
      _map(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final densityFinder =
        find.byKey(const ValueKey<String>('world-map-environment-density'));
    await tester.scrollUntilVisible(densityFinder, 120);
    expect(
      find.byKey(const ValueKey<String>('world-map-environment-reset-params')),
      findsNothing,
    );

    final slider = tester.widget<PokeMapGuidedSlider>(densityFinder);
    slider.onChanged(40);
    await tester.pump();

    final area = harness.notifier.state.activeMap!.layers
        .whereType<EnvironmentLayer>()
        .single
        .content
        .areas
        .single;
    expect(area.paramsOverride?.density, closeTo(0.4, 0.001));
    expect(
      find.byKey(const ValueKey<String>('world-map-environment-reset-params')),
      findsOneWidget,
    );
  });

  testWidgets('a new seed changes the zone seed', (tester) async {
    final harness = _Harness(
      _map(areas: <EnvironmentArea>[_area()]),
      activeLayerId: 'tiles',
      selectedEnvironmentAreaId: 'area1',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    final reseed =
        find.byKey(const ValueKey<String>('world-map-environment-reseed'));
    await tester.scrollUntilVisible(reseed, 120);
    await tester.ensureVisible(reseed);
    await tester.pumpAndSettle();
    await tester.tap(reseed);
    await tester.pump();

    final area = harness.notifier.state.activeMap!.layers
        .whereType<EnvironmentLayer>()
        .single
        .content
        .areas
        .single;
    expect(area.seed, 2);
  });

  testWidgets('says so when the layer carries no environment', (tester) async {
    final harness = _Harness(
      MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [_tiles()],
      ),
      activeLayerId: 'tiles',
    );
    addTearDown(harness.dispose);
    await harness.pump(tester);

    expect(find.textContaining('Aucun environnement'), findsOneWidget);
  });
}

final class _Harness {
  _Harness(
    MapData map, {
    required String activeLayerId,
    String? selectedEnvironmentAreaId,
  }) : container = ProviderContainer() {
    keepAlive = container.listen(editorNotifierProvider, (_, __) {});
    notifier.state = EditorState(
      projectRootPath: '/virtual/project',
      project: _manifest(),
      activeMap: map,
      activeMapPath: 'maps/x.json',
      activeLayerId: activeLayerId,
      selectedEnvironmentAreaId: selectedEnvironmentAreaId,
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
              height: 900,
              child: const WorldMapEnvironmentInspector(),
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

ProjectManifest _manifest() {
  return buildShellChromeProject(
    environmentPresets: [
      EnvironmentPreset(
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
      ),
    ],
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

MapData _map({required List<EnvironmentArea> areas}) {
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
