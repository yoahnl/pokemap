// ignore_for_file: prefer_const_constructors — fixtures MapData lisibles

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/environment_generator_clear_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

ProjectManifest _minimalEnvManifest() {
  return buildShellChromeProject(
    environmentPresets: [
      EnvironmentPreset(
        id: 'p1',
        name: 'P',
        templateId: 't',
        palette: [
          EnvironmentPaletteItem(elementId: 'e1', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
  );
}

EnvironmentArea _area({
  required String id,
  required String presetId,
  List<String>? generatedPlacementIds,
  List<bool>? cells,
  int w = 2,
  int h = 2,
}) {
  final c = cells ?? List<bool>.filled(w * h, true);
  return EnvironmentArea(
    id: id,
    name: 'Z',
    presetId: presetId,
    mask: EnvironmentAreaMask(width: w, height: h, cells: c),
    seed: 1,
    generatedPlacementIds: generatedPlacementIds,
  );
}

void main() {
  group('ClearEnvironmentGeneratedPlacementsUseCase — modèles', () {
    test('EnvironmentClearResult copie défensivement et listes immuables', () {
      final m = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 1, height: 1),
        layers: [
          TileLayer(id: 't', name: 'T', tiles: const [0]),
        ],
      );
      final rawCleared = <EnvironmentClearedGeneratedPlacement>[
        const EnvironmentClearedGeneratedPlacement(
          placedElementId: 'p1',
          elementId: 'e1',
          layerId: 't',
          pos: GridPos(x: 0, y: 0),
        ),
      ];
      final rawIssues = <EnvironmentClearIssue>[
        const EnvironmentClearIssue(
          severity: EnvironmentClearIssueSeverity.warning,
          kind: EnvironmentClearIssueKind.noGeneratedPlacements,
          message: 'x',
        ),
      ];
      final r = EnvironmentClearResult(
        map: m,
        clearedPlacements: rawCleared,
        issues: rawIssues,
      );
      rawCleared.clear();
      rawIssues.clear();
      expect(r.clearedPlacementCount, 1);
      expect(r.warningCount, 1);
      expect(() => r.clearedPlacements.clear(), throwsUnsupportedError);
      expect(() => r.issues.clear(), throwsUnsupportedError);
      expect(
        r.issuesForKind(EnvironmentClearIssueKind.noGeneratedPlacements).length,
        1,
      );
    });

    test('EnvironmentClearedGeneratedPlacement et EnvironmentClearIssue', () {
      const a = EnvironmentClearedGeneratedPlacement(
        placedElementId: 'p',
        elementId: 'e',
        layerId: 'l',
        pos: GridPos(x: 1, y: 2),
      );
      const b = EnvironmentClearedGeneratedPlacement(
        placedElementId: 'p',
        elementId: 'e',
        layerId: 'l',
        pos: GridPos(x: 1, y: 2),
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);

      const i1 = EnvironmentClearIssue(
        severity: EnvironmentClearIssueSeverity.error,
        kind: EnvironmentClearIssueKind.areaNotFound,
        message: 'm',
        placedElementId: 'p',
      );
      const i2 = EnvironmentClearIssue(
        severity: EnvironmentClearIssueSeverity.error,
        kind: EnvironmentClearIssueKind.areaNotFound,
        message: 'm',
        placedElementId: 'p',
      );
      expect(i1, i2);
    });
  });

  group('ClearEnvironmentGeneratedPlacementsUseCase', () {
    test(
        'clear heureux : ids supprimés, manuel conservé, masque et cible préservés',
        () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['g1', 'g2'],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 5),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
        placedElements: [
          const MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
          const MapPlacedElement(
            id: 'g2',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 1, y: 0),
          ),
          const MapPlacedElement(
            id: 'manual',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 1),
          ),
        ],
      );
      final uc = ClearEnvironmentGeneratedPlacementsUseCase();
      final r = uc.execute(
        map,
        environmentLayerId: 'env',
        areaId: 'a1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.clearedPlacementCount, 2);
      expect(r.map.placedElements.map((e) => e.id).toList(), ['manual']);
      final outArea =
          (r.map.layers.first as EnvironmentLayer).content.areas.single;
      expect(outArea.generatedPlacementIds, isEmpty);
      expect(outArea.presetId, 'p1');
      expect(outArea.mask, area.mask);
      expect(
        (r.map.layers[1] as TileLayer).tiles,
        (map.layers[1] as TileLayer).tiles,
      );
    });

    test('deux areas : clear A ne touche pas B', () {
      final a = _area(
        id: 'A',
        presetId: 'p1',
        generatedPlacementIds: const ['a_only'],
      );
      final b = _area(
        id: 'B',
        presetId: 'p1',
        generatedPlacementIds: const ['b_only'],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [a, b],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'a_only',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'b_only',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 1, y: 0),
          ),
        ],
      );
      final r = ClearEnvironmentGeneratedPlacementsUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'A',
      );
      expect(r.hasErrors, isFalse);
      expect(r.map.placedElements.single.id, 'b_only');
      final areas = (r.map.layers.first as EnvironmentLayer).content.areas;
      expect(
          areas.firstWhere((x) => x.id == 'A').generatedPlacementIds, isEmpty);
      expect(
        areas.firstWhere((x) => x.id == 'B').generatedPlacementIds,
        const ['b_only'],
      );
    });

    test('ids manquants : warning, liste vidée, existant supprimé', () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['ok', 'ghost'],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'ok',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final r = ClearEnvironmentGeneratedPlacementsUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'a1',
      );
      expect(r.hasErrors, isFalse);
      expect(r.hasWarnings, isTrue);
      expect(
        r.issuesForKind(EnvironmentClearIssueKind.missingGeneratedPlacement),
        isNotEmpty,
      );
      expect(r.map.placedElements, isEmpty);
      expect(
        (r.map.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isEmpty,
      );
    });

    test('generatedPlacementIds vide : map inchangée, warning', () {
      final area = _area(id: 'a1', presetId: 'p1');
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final r = ClearEnvironmentGeneratedPlacementsUseCase().execute(
        map,
        environmentLayerId: 'env',
        areaId: 'a1',
      );
      expect(identical(r.map, map), isTrue);
      expect(r.clearedPlacementCount, 0);
      expect(
        r.issuesForKind(EnvironmentClearIssueKind.noGeneratedPlacements),
        isNotEmpty,
      );
    });

    test('erreurs bloquantes : layer / area inconnus', () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['x'],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(areas: [area]),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env],
      );
      final uc = ClearEnvironmentGeneratedPlacementsUseCase();
      final r1 = uc.execute(map, environmentLayerId: 'missing', areaId: 'a1');
      expect(r1.hasErrors, isTrue);
      expect(identical(r1.map, map), isTrue);

      final tileMap = MapData(
        id: 'm2',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [
          const MapLayer.tile(id: 'env', name: 'E', tiles: [0, 0, 0, 0]),
        ],
      );
      final r2 = uc.execute(tileMap, environmentLayerId: 'env', areaId: 'a1');
      expect(r2.hasErrors, isTrue);

      final r3 = uc.execute(map, environmentLayerId: 'env', areaId: 'ghost');
      expect(r3.hasErrors, isTrue);
      expect(
        r3.issuesForKind(EnvironmentClearIssueKind.areaNotFound),
        isNotEmpty,
      );
    });
  });

  group('EditorNotifier.clearEnvironmentGeneratedPlacements', () {
    test('succès : dirty, sélection placé nettoyée, status effacé', () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['g1'],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        selectedPlacedElementInstanceId: 'g1',
        savedMapSnapshot: map,
      );
      container
          .read(editorNotifierProvider.notifier)
          .clearEnvironmentGeneratedPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      expect(s.isDirty, isTrue);
      expect(s.activeLayerId, 'env');
      expect(s.selectedEnvironmentAreaId, 'a1');
      expect(s.selectedPlacedElementInstanceId, isNull);
      expect(s.statusMessage, contains('effacé'));
      expect(s.activeMap!.placedElements, isEmpty);
    });

    test(
        'deletePlacedElementInstance retire un placement généré individuel et sa référence',
        () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['g1', 'g2'],
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'g2',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 1, y: 0),
          ),
          MapPlacedElement(
            id: 'manual',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 1),
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        selectedPlacedElementInstanceId: 'g1',
        savedMapSnapshot: map,
      );

      container
          .read(editorNotifierProvider.notifier)
          .deletePlacedElementInstance(instanceId: 'g1');

      final s = container.read(editorNotifierProvider);
      final outMap = s.activeMap!;
      final outEnv = outMap.layers.first as EnvironmentLayer;
      expect(outMap.placedElements.map((p) => p.id).toList(), [
        'g2',
        'manual',
      ]);
      expect(outEnv.content.areas.single.generatedPlacementIds, const ['g2']);
      expect(s.selectedPlacedElementInstanceId, isNull);
      expect(s.isDirty, isTrue);
      expect(s.statusMessage, contains('Instance générée supprimée'));
    });

    test(
        'deleteGeneratedEnvironmentPlacementAt supprime le placement généré cliqué dans son footprint',
        () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['tree_a', 'tree_b'],
        w: 4,
        h: 4,
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(16, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 4, height: 4),
        layers: [env, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'tree_a',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
          MapPlacedElement(
            id: 'tree_b',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 2, y: 0),
          ),
        ],
      );
      final project = buildShellChromeProject(
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'ts',
            categoryId: 'flora',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: project,
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        savedMapSnapshot: map,
      );

      final deleted = container
          .read(editorNotifierProvider.notifier)
          .deleteGeneratedEnvironmentPlacementAt(const GridPos(x: 1, y: 1));

      final s = container.read(editorNotifierProvider);
      final outMap = s.activeMap!;
      final outEnv = outMap.layers.first as EnvironmentLayer;
      expect(s.errorMessage, isNull);
      expect(deleted, isTrue);
      expect(outMap.placedElements.map((p) => p.id).toList(), ['tree_b']);
      expect(
        outEnv.content.areas.single.generatedPlacementIds,
        const ['tree_b'],
      );
      expect(s.statusMessage, contains('Placement généré supprimé'));
    });

    test(
        'addGeneratedEnvironmentPlacementAt ajoute un placement individuel du preset',
        () {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['tree_a'],
        w: 4,
        h: 4,
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tilesetId: 'ts',
        tiles: List<int>.filled(16, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 4, height: 4),
        layers: [env, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'tree_a',
            layerId: 'tiles',
            elementId: 'tree',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final project = buildShellChromeProject(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p1',
            name: 'Forest',
            templateId: 'forest',
            palette: [
              EnvironmentPaletteItem(elementId: 'tree', weight: 1),
            ],
            defaultParams: EnvironmentGenerationParams.standard(),
            sortOrder: 0,
          ),
        ],
        elements: const [
          ProjectElementEntry(
            id: 'tree',
            name: 'Tree',
            tilesetId: 'ts',
            categoryId: 'flora',
            frames: [
              TilesetVisualFrame(
                source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
              ),
            ],
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: project,
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'a1',
        savedMapSnapshot: map,
      );

      final added = container
          .read(editorNotifierProvider.notifier)
          .addGeneratedEnvironmentPlacementAt(const GridPos(x: 1, y: 1));

      final s = container.read(editorNotifierProvider);
      final outMap = s.activeMap!;
      final outEnv = outMap.layers.first as EnvironmentLayer;
      expect(added, isTrue);
      expect(outMap.placedElements.map((p) => p.id).toList(), [
        'tree_a',
        'env_gen_a1_1_1_tree',
      ]);
      expect(outEnv.content.areas.single.generatedPlacementIds, const [
        'tree_a',
        'env_gen_a1_1_1_tree',
      ]);
      expect(s.statusMessage, contains('Placement généré ajouté'));
    });

    test('no-op ids vides : map inchangée, isDirty inchangé', () {
      final area = _area(id: 'a1', presetId: 'p1');
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: buildShellChromeProject(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        isDirty: false,
        savedMapSnapshot: map,
      );
      final before = container.read(editorNotifierProvider).activeMap!;
      container
          .read(editorNotifierProvider.notifier)
          .clearEnvironmentGeneratedPlacements(
            environmentLayerId: 'env',
            areaId: 'a1',
          );
      final s = container.read(editorNotifierProvider);
      expect(identical(s.activeMap, before), isTrue);
      expect(s.isDirty, isFalse);
      expect(s.statusMessage, contains('Aucun placement'));
    });
  });

  group('EnvironmentLayerInspectorPanel — Clear', () {
    testWidgets('sans placements générés : bouton disabled + texte', (
      tester,
    ) async {
      final area = _area(id: 'a1', presetId: 'p1');
      final envLayer = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        layers: [envLayer, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _minimalEnvManifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
      );
      await tester.binding.setSurfaceSize(const Size(480, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: EnvironmentLayerInspectorPanel(
                  map: map,
                  layer: envLayer as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Aucun placement généré à effacer.'), findsWidgets);
      expect(
        tester
            .widget<PushButton>(find.byKey(const Key('env-area-clear-a1')))
            .onPressed,
        isNull,
      );
    });

    testWidgets('clear puis generate disponible', (tester) async {
      final area = _area(
        id: 'a1',
        presetId: 'p1',
        generatedPlacementIds: const ['g1'],
      );
      final envLayer = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm',
        name: 'M',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [envLayer, tile],
        placedElements: const [
          MapPlacedElement(
            id: 'g1',
            layerId: 'tiles',
            elementId: 'e1',
            pos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final manifest = buildShellChromeProject(
        environmentPresets: [
          EnvironmentPreset(
            id: 'p1',
            name: 'P',
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
          const ProjectElementEntry(
            id: 'e1',
            name: 'E',
            tilesetId: 'tsA',
            categoryId: 'c',
            frames: [
              TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
            ],
          ),
        ],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: manifest,
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 2000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: SizedBox(
                  width: 440,
                  height: 2000,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final clearBtn = find.byKey(const Key('env-area-clear-a1'));
      expect(tester.widget<PushButton>(clearBtn).onPressed, isNotNull);
      await tester.ensureVisible(clearBtn);
      await tester.pumpAndSettle();
      await tester.tap(clearBtn);
      await tester.pumpAndSettle();
      expect(container.read(editorNotifierProvider).activeMap!.placedElements,
          isEmpty);
      await tester.pumpAndSettle();
      final genBtn = find.byKey(const Key('env-area-generate-a1'));
      expect(tester.widget<PushButton>(genBtn).onPressed, isNotNull);
      expect(tester.widget<PushButton>(clearBtn).onPressed, isNull);
    });
  });
}
