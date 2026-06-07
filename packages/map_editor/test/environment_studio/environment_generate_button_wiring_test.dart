// ignore_for_file: prefer_const_constructors — fixtures MapData volontairement non const pour lisibilité

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/ui/panels/environment_layer_inspector_panel.dart';
import 'package:map_editor/src/ui/panels/map_inspector_panel.dart';

import '../shell_chrome_test_harness.dart';

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

ProjectManifest _manifest({List<EnvironmentPreset>? presets}) {
  return buildShellChromeProject(
    environmentPresets: presets ?? [_preset()],
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

EnvironmentArea _area({
  required String id,
  required int w,
  required int h,
  List<bool>? cells,
  List<String>? generatedPlacementIds,
  String presetId = 'preset1',
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
  group('Lot 25 — EditorNotifier.generateEnvironmentAreaPlacements', () {
    test('chemin heureux : placements, dirty, layer actif, masque edit arrêté',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      const n = 4;
      final area = _area(id: 'area1', w: 2, h: 2);
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
        tiles: List<int>.filled(n, 0),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/tmp/lot25',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area1',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.generateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final s = container.read(editorNotifierProvider);
      expect(s.activeLayerId, 'env');
      expect(s.selectedEnvironmentAreaId, 'area1');
      expect(s.environmentMaskEditMode, isNull);
      expect(s.isDirty, isTrue);
      expect(s.activeMap!.placedElements, isNotEmpty);
      final envOut = s.activeMap!.layers.first as EnvironmentLayer;
      expect(envOut.content.areas.single.generatedPlacementIds, isNotEmpty);
      expect(s.statusMessage, contains('placement'));
    });

    test('masque vide : aucun placement, message sans mutation', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final cells = List<bool>.filled(4, false);
      final area = _area(id: 'area1', w: 2, h: 2, cells: cells);
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
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.generateEnvironmentAreaPlacements(
        environmentLayerId: 'env',
        areaId: 'area1',
      );
      final s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements, isEmpty);
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isEmpty,
      );
      expect(s.statusMessage, contains('Aucun placement'));
    });

    test('déjà généré : pas de nouveau placement', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area(
        id: 'area1',
        w: 2,
        h: 2,
        generatedPlacementIds: const ['old'],
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
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      final before = container.read(editorNotifierProvider).activeMap!;
      container
          .read(editorNotifierProvider.notifier)
          .generateEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'area1',
          );
      final s = container.read(editorNotifierProvider);
      expect(identical(s.activeMap, before), isTrue);
      expect(s.activeMap!.placedElements, isEmpty);
      expect(s.statusMessage, contains('déjà'));
    });

    test('cible TileLayer absente : erreur, pas de placement', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area(id: 'area1', w: 2, h: 2);
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: null,
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      container
          .read(editorNotifierProvider.notifier)
          .generateEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'area1',
          );
      final s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements, isEmpty);
      expect(s.errorMessage, isNotNull);
      expect(s.errorMessage!, contains('générer'));
    });

    test('apply échoue : conflit id placement existant', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final area = _area(id: 'area1', w: 2, h: 2);
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
      final blocker = MapPlacedElement(
        id: 'env_gen_area1_0_0_e1',
        layerId: 'tiles',
        elementId: 'e1',
        pos: const GridPos(x: 1, y: 1),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
        placedElements: [blocker],
      );
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      final before = container.read(editorNotifierProvider).activeMap!;
      container
          .read(editorNotifierProvider.notifier)
          .generateEnvironmentAreaPlacements(
            environmentLayerId: 'env',
            areaId: 'area1',
          );
      final s = container.read(editorNotifierProvider);
      expect(identical(s.activeMap, before), isTrue);
      expect(s.activeMap!.placedElements.length, 1);
      expect(s.errorMessage, contains('appliquer'));
    });
  });

  group('Lot 25 — EnvironmentLayerInspectorPanel Generate', () {
    testWidgets('sans cible : bouton désactivé + texte cible', (tester) async {
      final area = _area(id: 'area1', w: 2, h: 2);
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: null,
          areas: [area],
        ),
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
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
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Choisissez un TileLayer cible avant de générer.'),
        findsOneWidget,
      );
      final genBtn = tester.widget<PushButton>(
        find.byKey(const Key('env-area-generate-area1')),
      );
      expect(genBtn.onPressed, isNull);
    });

    testWidgets('cible ok masque vide : désactivé + texte masque', (
      tester,
    ) async {
      final cells = List<bool>.filled(4, false);
      final area = _area(id: 'area1', w: 2, h: 2, cells: cells);
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
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
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
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Peignez le masque avant de générer.'),
        findsOneWidget,
      );
      final genBtn = tester.widget<PushButton>(
        find.byKey(const Key('env-area-generate-area1')),
      );
      expect(genBtn.onPressed, isNull);
    });

    testWidgets('cible tileset incompatible : bouton désactivé', (
      tester,
    ) async {
      final area = _area(id: 'area1', w: 2, h: 2);
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
        tilesetId: 'cliff',
        tiles: List<int>.filled(4, 0),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
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
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<Text>(find.byKey(const Key('env-area-generate-hint-area1')))
            .data,
        'Le TileLayer cible utilise un tileset incompatible avec ce preset.',
      );
      final genBtn = tester.widget<PushButton>(
        find.byKey(const Key('env-area-generate-area1')),
      );
      expect(genBtn.onPressed, isNull);
    });

    testWidgets('clic Générer : placements + bouton désactivé ensuite', (
      tester,
    ) async {
      final area = _area(id: 'area1', w: 2, h: 2);
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
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'env',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1100));
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
                  height: 1100,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final genFinder = find.byKey(const Key('env-area-generate-area1'));
      expect(tester.widget<PushButton>(genFinder).onPressed, isNotNull);
      await tester.ensureVisible(genFinder);
      await tester.pumpAndSettle();
      await tester.tap(genFinder);
      await tester.pumpAndSettle();
      final s = container.read(editorNotifierProvider);
      expect(s.activeMap!.placedElements, isNotEmpty);
      expect(
        (s.activeMap!.layers.first as EnvironmentLayer)
            .content
            .areas
            .single
            .generatedPlacementIds,
        isNotEmpty,
      );
      await tester.pumpAndSettle();
      expect(tester.widget<PushButton>(genFinder).onPressed, isNull);
      expect(
          find.byKey(const Key('env-area-regenerate-area1')), findsOneWidget);
    });

    testWidgets(
        'TileLayer inspector active Générer avec une seule area effective',
        (tester) async {
      final area = _area(id: 'area1', w: 2, h: 2);
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [tile, env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'tiles',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1100));
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
                  height: 1100,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final generateText = find.text('Générer dans ce layer');
      expect(generateText, findsOneWidget);
      final button = tester.widget<CupertinoButton>(
        find.ancestor(
          of: generateText,
          matching: find.byType(CupertinoButton),
        ),
      );
      expect(button.onPressed, isNotNull);

      await tester.ensureVisible(generateText);
      await tester.pumpAndSettle();
      await tester.tap(generateText);
      await tester.pumpAndSettle();

      final state = container.read(editorNotifierProvider);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area1');
      expect(state.activeMap!.placedElements, isNotEmpty);
    });

    testWidgets(
        'TileLayer inspector désactive Régénérer et Shuffle sans placements générés',
        (tester) async {
      final area = _area(id: 'area1', w: 2, h: 2);
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [tile, env],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'tiles',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1100));
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
                  height: 1100,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(_cupertinoButtonFor(tester, 'Générer dans ce layer').onPressed,
          isNotNull);
      expect(_cupertinoButtonFor(tester, 'Régénérer').onPressed, isNull);
      expect(_cupertinoButtonFor(tester, 'Shuffle').onPressed, isNull);
    });

    testWidgets(
        'TileLayer inspector active et stoppe la suppression individuelle',
        (tester) async {
      final area = _area(
        id: 'area1',
        w: 2,
        h: 2,
        generatedPlacementIds: const ['generated'],
      );
      final tile = TileLayer(
        id: 'tiles',
        name: 'T',
        tiles: List<int>.filled(4, 0),
      );
      final env = MapLayer.environment(
        id: 'env',
        name: 'E',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [area],
        ),
      );
      final generated = MapPlacedElement(
        id: 'generated',
        layerId: 'tiles',
        elementId: 'e1',
        pos: const GridPos(x: 1, y: 1),
      );
      final map = MapData(
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [tile, env],
        placedElements: [generated],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
        activeMap: map,
        activeMapPath: 'maps/x.json',
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area1',
        savedMapSnapshot: map,
      );
      await tester.binding.setSurfaceSize(const Size(520, 1300));
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
                  height: 1300,
                  child: MapInspectorPanel(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final startDelete = find.text('Supprimer un élément généré');
      expect(startDelete, findsOneWidget);
      expect(
          _cupertinoButtonFor(tester, 'Supprimer un élément généré').onPressed,
          isNotNull);

      await tester.ensureVisible(startDelete);
      await tester.pumpAndSettle();
      await tester.tap(startDelete);
      await tester.pumpAndSettle();

      var state = container.read(editorNotifierProvider);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area1');
      expect(state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedDelete);
      expect(find.text('Suppression active'), findsOneWidget);
      expect(find.text('Arrêter la suppression'), findsOneWidget);

      final stopDelete = find.text('Arrêter la suppression');
      await tester.ensureVisible(stopDelete);
      await tester.pumpAndSettle();
      await tester.tap(stopDelete);
      await tester.pumpAndSettle();

      state = container.read(editorNotifierProvider);
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area1');
      expect(state.environmentMaskEditMode, isNull);
    });

    testWidgets('preset manifest introuvable : désactivé', (tester) async {
      final area = _area(id: 'area1', w: 2, h: 2, presetId: 'fantome');
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
        id: 'm1',
        name: 'M1',
        size: const GridSize(width: 2, height: 2),
        tilesetId: 'tsA',
        layers: [env, tile],
      );
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: '/r',
        project: _manifest(),
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
                  layer: env as EnvironmentLayer,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const Key('env-area-card-preset-missing-area1')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PushButton>(
                find.byKey(const Key('env-area-generate-area1')))
            .onPressed,
        isNull,
      );
    });
  });
}

CupertinoButton _cupertinoButtonFor(WidgetTester tester, String label) {
  return tester.widget<CupertinoButton>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(CupertinoButton),
    ),
  );
}
