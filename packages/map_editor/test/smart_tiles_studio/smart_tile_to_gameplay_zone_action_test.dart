import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show MaterialApp, Scaffold;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_to_gameplay_zone_action.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_behavior_action_menu.dart';
import 'package:map_editor/src/features/smart_tiles_studio/presentation/smart_tile_to_gameplay_zone_dialog.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_to_gameplay_zone_presenter.dart';
import 'package:map_editor/src/theme/theme.dart';

void main() {
  group('Tall grass Smart Tile to gameplay zone presenter', () {
    test('builds a greedy encounter generation preview from painted cells', () {
      final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: _mapWithTallGrassSmartTile(),
        smartTileLayer: _tallGrassLayer(),
        smartTilePresetId: 'tall_grass',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'tall_grass', name: 'Tall Grass')],
        ),
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
      );
      expect(preview.plan!.generatedZones, hasLength(2));
      expect(
        preview.plan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.encounter &&
              zone.encounter?.encounterTableId == 'route_1_grass' &&
              zone.encounter?.encounterKind == EncounterKind.walk,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('targets only the selected material in a multi-material field', () {
      final cells = List<int>.filled(8 * 8, 0)
        ..[0] = 1
        ..[1] = 2
        ..[2] = 2;
      final basePreset = _smartTilePreset(
        id: 'meadow',
        name: 'Meadow',
      );
      final preset = basePreset.copyWith(
        allowedMaterialIds: const <String>[
          'meadow-material',
          'flowers-material',
        ],
      );
      final layer = SmartTileLayer(
        id: 'smart-tile-main',
        name: 'Meadow',
        presetId: preset.id,
        usage: preset.usage,
        materialPalette: const <String>[
          '',
          'meadow-material',
          'flowers-material',
        ],
        field: SmartTileField.cell(semanticCells: cells),
      );
      final catalog = ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'meadow-material',
            name: 'Meadow',
            connectionGroupId: 'meadow',
          ),
          ProjectSmartTileMaterial(
            id: 'flowers-material',
            name: 'Flowers',
            connectionGroupId: 'flowers',
          ),
        ],
        presets: <ProjectSmartTilePreset>[preset],
      );

      final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: MapData(
          id: 'route_1',
          name: 'Route 1',
          size: const GridSize(width: 8, height: 8),
          layers: <MapLayer>[layer],
        ),
        smartTileLayer: layer,
        smartTilePresetId: preset.id,
        materialId: 'flowers-material',
        catalog: catalog,
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.plan!.source.cells,
        const <GridPos>[GridPos(x: 1, y: 0), GridPos(x: 2, y: 0)],
      );
      expect(preview.plan!.generatedZones, hasLength(1));
      expect(preview.plan!.generatedZones.single.area.size.width, 2);
    });

    test('derives gameplay cells from a painted Wang field', () {
      final semanticCells = List<int>.filled(8 * 8, 0)
        ..[0] = 1
        ..[1] = 1;
      final base = _tallGrassLayer();
      final layer = base.copyWith(
        field: SmartTileField.mixed(
          semanticCells: semanticCells,
          horizontalEdges: List<int>.filled(8 * 9, 0),
          verticalEdges: List<int>.filled(9 * 8, 0),
          corners: List<int>.filled(9 * 9, 0),
        ),
      );
      final map = _mapWithTallGrassSmartTile().copyWith(
        layers: <MapLayer>[layer],
      );

      final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: map,
        smartTileLayer: layer,
        smartTilePresetId: 'tall_grass',
        catalog: _smartTileCatalog(
          presets: <ProjectSmartTilePreset>[
            _smartTilePreset(id: 'tall_grass', name: 'Tall Grass').copyWith(
              topology: SmartTileTopology.wang8,
              templateHint: SmartTileTemplateHint.mixed256,
            ),
          ],
        ),
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.plan!.source.cells,
        const <GridPos>[GridPos(x: 0, y: 0), GridPos(x: 1, y: 0)],
      );
    });

    test('blocks confirmation when encounterTableId is empty', () {
      final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: _mapWithTallGrassSmartTile(),
        smartTileLayer: _tallGrassLayer(),
        smartTilePresetId: 'tall_grass',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'tall_grass', name: 'Tall Grass')],
        ),
        encounterTableId: '   ',
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(preview.plan, isNull);
      expect(
        preview.messages.map((message) => message.title),
        contains('Table de rencontres requise'),
      );
    });

    test('blocks when selected Smart Tile has no painted placement', () {
      final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: _mapWithTallGrassSmartTile(),
        smartTileLayer: _tallGrassLayer(),
        smartTilePresetId: 'water',
        catalog: _smartTileCatalog(
          presets: [
            _smartTilePreset(id: 'tall_grass', name: 'Tall Grass'),
            _smartTilePreset(id: 'water', name: 'Water'),
          ],
        ),
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Preset Smart Tile indisponible'),
      );
    });
  });

  group('Surfable water Smart Tile to gameplay zone presenter', () {
    test('builds a greedy movement/surf generation preview from painted cells',
        () {
      final preview = buildSurfableWaterSmartTileGameplayZonePreview(
        map: _mapWithWaterSmartTile(),
        smartTileLayer: _waterLayer(),
        smartTilePresetId: 'water',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'water', name: 'Water')],
        ),
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
      );
      expect(preview.plan!.generatedZones, hasLength(2));
      expect(
        preview.plan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.movement &&
              zone.movement?.requiredMode == MovementMode.surf &&
              zone.movement?.allowedModes.isEmpty == true,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('blocks when selected water Smart Tile has no painted placement', () {
      final preview = buildSurfableWaterSmartTileGameplayZonePreview(
        map: _mapWithWaterSmartTile(),
        smartTileLayer: _waterLayer(),
        smartTilePresetId: 'tall_grass',
        catalog: _smartTileCatalog(
          presets: [
            _smartTilePreset(id: 'water', name: 'Water'),
            _smartTilePreset(id: 'tall_grass', name: 'Tall Grass'),
          ],
        ),
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Preset Smart Tile indisponible'),
      );
    });
  });

  group('Lava hazard Smart Tile to gameplay zone presenter', () {
    test('builds a greedy hazard/lava generation preview from painted cells',
        () {
      final preview = buildLavaHazardSmartTileGameplayZonePreview(
        map: _mapWithLavaSmartTile(),
        smartTileLayer: _lavaLayer(),
        smartTilePresetId: 'lava',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isTrue);
      expect(preview.damagePerStep, 5);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
      );
      expect(preview.plan!.generatedZones, hasLength(2));
      expect(
        preview.plan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.hazard &&
              zone.hazard?.hazardKind == HazardKind.lava &&
              zone.hazard?.damagePerStep == 5,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('blocks when damagePerStep is not positive', () {
      final preview = buildLavaHazardSmartTileGameplayZonePreview(
        map: _mapWithLavaSmartTile(),
        smartTileLayer: _lavaLayer(),
        smartTilePresetId: 'lava',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        damagePerStep: 0,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(preview.plan, isNull);
      expect(
        preview.messages.map((message) => message.title),
        contains('Dégâts par pas invalides'),
      );
    });

    test('blocks when selected lava Smart Tile has no painted placement', () {
      final preview = buildLavaHazardSmartTileGameplayZonePreview(
        map: _mapWithLavaSmartTile(),
        smartTileLayer: _lavaLayer(),
        smartTilePresetId: 'water',
        catalog: _smartTileCatalog(
          presets: [
            _smartTilePreset(id: 'lava', name: 'Lava'),
            _smartTilePreset(id: 'water', name: 'Water'),
          ],
        ),
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Preset Smart Tile indisponible'),
      );
    });

    test('blocks when selected lava preset is absent from catalog', () {
      final preview = buildLavaHazardSmartTileGameplayZonePreview(
        map: _mapWithLavaSmartTile(),
        smartTileLayer: _lavaLayer(),
        smartTilePresetId: 'lava',
        catalog: const ProjectSmartTileCatalog.empty(),
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Preset Smart Tile indisponible'),
      );
    });

    test('blocks when map is null', () {
      final preview = buildLavaHazardSmartTileGameplayZonePreview(
        map: null,
        smartTileLayer: _lavaLayer(),
        smartTilePresetId: 'lava',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SmartTileGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune map active'),
      );
    });
  });

  group('SmartTileToGameplayZoneDialog', () {
    testWidgets('requires an encounter table id before confirming',
        (tester) async {
      SmartTileGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SmartTileToGameplayZoneDialog(
              map: _mapWithTallGrassSmartTile(),
              smartTileLayer: _tallGrassLayer(),
              smartTilePresetId: 'tall_grass',
              catalog: _smartTileCatalog(
                presets: [
                  _smartTilePreset(id: 'tall_grass', name: 'Tall Grass')
                ],
              ),
              encounterTables: const [],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(
        find.text('Créer une zone de rencontre depuis ce Smart Tile'),
        findsOneWidget,
      );
      expect(find.text('Table de rencontres requise'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoDialogAction>(
              find.widgetWithText(CupertinoDialogAction, 'Créer les zones'),
            )
            .onPressed,
        isNull,
      );
      expect(confirmedPlan, isNull);

      await tester.enterText(
        find.byKey(
            const Key('smart-tile-to-gameplay-zone-encounter-table-field')),
        'route_1_grass',
      );
      await tester.pump();

      expect(find.text('Plan prêt à appliquer'), findsOneWidget);

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer les zones'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(confirmedPlan!.generatedZones, hasLength(2));
    });

    testWidgets('announces synchronization for an existing binding',
        (tester) async {
      final baseMap = _mapWithTallGrassSmartTile();
      final catalog = _smartTileCatalog(
        presets: [_smartTilePreset(id: 'tall_grass', name: 'Tall Grass')],
      );
      final existing = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: baseMap,
        smartTileLayer: _tallGrassLayer(),
        smartTilePresetId: 'tall_grass',
        catalog: catalog,
        encounterTableId: 'route_1_grass',
      ).plan!;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SmartTileToGameplayZoneDialog(
              map: baseMap.copyWith(gameplayZones: existing.generatedZones),
              smartTileLayer: _tallGrassLayer(),
              smartTilePresetId: 'tall_grass',
              catalog: catalog,
              encounterTables: const [
                ProjectEncounterTable(
                  id: 'route_1_grass',
                  name: 'Route 1 Grass',
                  encounterKind: EncounterKind.walk,
                ),
              ],
              onConfirm: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Remplacées : '), findsOneWidget);
      expect(find.text('Synchroniser les zones'), findsOneWidget);
    });
  });

  group('SurfableWaterSmartTileGameplayZoneDialog', () {
    testWidgets('confirms a ready surfable water plan', (tester) async {
      SmartTileGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfableWaterSmartTileGameplayZoneDialog(
              map: _mapWithWaterSmartTile(),
              smartTileLayer: _waterLayer(),
              smartTilePresetId: 'water',
              catalog: _smartTileCatalog(
                presets: [_smartTilePreset(id: 'water', name: 'Water')],
              ),
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Mode : '), findsOneWidget);
      expect(find.text('Surf'), findsOneWidget);
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer la zone Surf'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(confirmedPlan!.generatedZones, hasLength(2));
    });

    testWidgets('disables confirmation when the water plan is blocked',
        (tester) async {
      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfableWaterSmartTileGameplayZoneDialog(
              map: _mapWithWaterSmartTile(),
              smartTileLayer: _waterLayer(),
              smartTilePresetId: 'tall_grass',
              catalog: _smartTileCatalog(
                presets: [
                  _smartTilePreset(id: 'tall_grass', name: 'Tall Grass')
                ],
              ),
              onConfirm: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Preset Smart Tile indisponible'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoDialogAction>(
              find.widgetWithText(
                CupertinoDialogAction,
                'Créer la zone Surf',
              ),
            )
            .onPressed,
        isNull,
      );
    });
  });

  group('LavaHazardSmartTileGameplayZoneDialog', () {
    testWidgets('confirms a ready lava hazard plan with default damage',
        (tester) async {
      SmartTileGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LavaHazardSmartTileGameplayZoneDialog(
              map: _mapWithLavaSmartTile(),
              smartTileLayer: _lavaLayer(),
              smartTilePresetId: 'lava',
              catalog: _smartTileCatalog(
                presets: [_smartTilePreset(id: 'lava', name: 'Lava')],
              ),
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(find.text('Créer une zone de lave dangereuse'), findsOneWidget);
      expect(find.text('Dégâts par pas'), findsOneWidget);
      expect(find.text('Type : '), findsOneWidget);
      expect(find.text('Lave dangereuse'), findsOneWidget);
      final damageField = tester.widget<CupertinoTextField>(
        find.byKey(const Key('smart-tile-to-gameplay-zone-lava-damage-field')),
      );
      expect(damageField.controller?.text, '5');
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer la zone de lave'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(confirmedPlan!.generatedZones, hasLength(2));
      expect(
        confirmedPlan!.generatedZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.hazard &&
              zone.hazard?.hazardKind == HazardKind.lava &&
              zone.hazard?.damagePerStep == 5,
        ),
        isTrue,
      );
    });

    testWidgets('requires positive damage and uses edited damage in the plan',
        (tester) async {
      SmartTileGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LavaHazardSmartTileGameplayZoneDialog(
              map: _mapWithLavaSmartTile(),
              smartTileLayer: _lavaLayer(),
              smartTilePresetId: 'lava',
              catalog: _smartTileCatalog(
                presets: [_smartTilePreset(id: 'lava', name: 'Lava')],
              ),
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      final field = find.byKey(
        const Key('smart-tile-to-gameplay-zone-lava-damage-field'),
      );
      await tester.enterText(field, '0');
      await tester.pump();

      expect(find.text('Dégâts par pas invalides'), findsOneWidget);
      expect(
        tester
            .widget<CupertinoDialogAction>(
              find.widgetWithText(
                CupertinoDialogAction,
                'Créer la zone de lave',
              ),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(field, '8');
      await tester.pump();

      final createAction = tester.widget<CupertinoDialogAction>(
        find.widgetWithText(CupertinoDialogAction, 'Créer la zone de lave'),
      );
      expect(createAction.onPressed, isNotNull);
      createAction.onPressed!();

      expect(confirmedPlan, isNotNull);
      expect(
        confirmedPlan!.generatedZones.every(
          (zone) => zone.hazard?.damagePerStep == 8,
        ),
        isTrue,
      );
    });
  });

  group('SmartTileBehaviorActionMenu', () {
    testWidgets('opens the no-code choices and routes tall grass',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, _) {});
      addTearDown(keepAlive.close);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithTallGrassSmartTile();
      final project = _projectManifest();
      notifier.state = EditorState(
        project: project,
        activeMap: map,
        activeLayerId: 'smart-tile-main',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: PokeMapTheme.light(),
            home: Scaffold(
              body: SmartTileBehaviorActionMenu(
                map: map,
                smartTileLayer: _tallGrassLayer(),
                smartTilePresetId: 'tall_grass',
                materialId: 'tall_grass-material',
                catalog: project.smartTileCatalog,
                encounterTables: project.encounterTables,
                notifier: notifier,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Créer un comportement'), findsOneWidget);
      expect(find.text('Créer une zone de rencontre'), findsNothing);
      expect(find.text('Rendre cette eau surfable'), findsNothing);

      await tester.tap(find.text('Créer un comportement'));
      await tester.pumpAndSettle();

      expect(find.text('Herbe haute avec rencontres'), findsOneWidget);
      expect(find.text('Eau surfable'), findsOneWidget);
      expect(find.text('Lave dangereuse'), findsOneWidget);
      await tester.tap(find.text('Herbe haute avec rencontres'));
      await tester.pumpAndSettle();

      expect(
        find.text('Créer une zone de rencontre depuis ce Smart Tile'),
        findsOneWidget,
      );
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });
  });

  group('EditorNotifier tall grass Smart Tile generation', () {
    test(
        'adds multiple encounter gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );
      final preview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: initialMap,
        smartTileLayer: _tallGrassLayer(),
        smartTilePresetId: 'tall_grass',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'tall_grass', name: 'Tall Grass')],
        ),
        encounterTableId: 'route_1_grass',
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: preview.plan!,
      );

      final state = container.read(editorNotifierProvider);
      final updatedMap = state.activeMap!;
      expect(applied, isTrue);
      expect(updatedMap.gameplayZones, hasLength(2));
      expect(
        updatedMap.gameplayZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.encounter &&
              zone.encounter?.encounterTableId == 'route_1_grass' &&
              zone.encounter?.encounterKind == EncounterKind.walk,
        ),
        isTrue,
      );
      expect(state.selectedGameplayZoneId, updatedMap.gameplayZones.first.id);
      expect(state.isDirty, isTrue);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.canUndoMap, isTrue);
      expect(
        updatedMap.layers.whereType<SmartTileLayer>().single.field,
        initialMap.layers.whereType<SmartTileLayer>().single.field,
      );
    });

    test('resynchronizes painted cells without deleting manual zones', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSmartTile();
      final catalog = _smartTileCatalog(
        presets: [_smartTilePreset(id: 'tall_grass', name: 'Tall Grass')],
      );
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );
      final firstPreview = buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: initialMap,
        smartTileLayer: _tallGrassLayer(),
        smartTilePresetId: 'tall_grass',
        catalog: catalog,
        encounterTableId: 'route_1_grass',
      );
      expect(
        applyTallGrassEncounterGameplayZonePlan(
          notifier: notifier,
          plan: firstPreview.plan!,
        ),
        isTrue,
      );

      const manualZone = MapGameplayZone(
        id: 'manual-zone',
        name: 'Manuelle',
        kind: GameplayZoneKind.encounter,
        area: MapRect(
          pos: GridPos(x: 7, y: 7),
          size: GridSize(width: 1, height: 1),
        ),
        encounter: EncounterZonePayload(
          encounterTableId: 'manual-table',
        ),
      );
      final repaintedLayer = _smartTileLayer(
        presetId: 'tall_grass',
        paintedCellIndexes: const <int>[9, 10, 17, 18],
      );
      final repaintedMap = notifier.state.activeMap!.copyWith(
        layers: <MapLayer>[repaintedLayer],
        gameplayZones: <MapGameplayZone>[
          ...notifier.state.activeMap!.gameplayZones,
          manualZone,
        ],
      );
      notifier.state = notifier.state.copyWith(activeMap: repaintedMap);
      final synchronizationPreview =
          buildTallGrassEncounterSmartTileGameplayZonePreview(
        map: repaintedMap,
        smartTileLayer: repaintedLayer,
        smartTilePresetId: 'tall_grass',
        catalog: catalog,
        encounterTableId: 'route_1_grass',
      );

      expect(synchronizationPreview.isSynchronization, isTrue);
      expect(synchronizationPreview.existingZoneCount, 2);
      expect(synchronizationPreview.generatedZoneCount, 1);
      expect(
        applyTallGrassEncounterGameplayZonePlan(
          notifier: notifier,
          plan: synchronizationPreview.plan!,
        ),
        isTrue,
      );

      final zones = notifier.state.activeMap!.gameplayZones;
      expect(zones, hasLength(2));
      expect(zones, contains(manualZone));
      final generated = zones.singleWhere((zone) => zone.id != manualZone.id);
      expect(
        generated.area,
        const MapRect(
          pos: GridPos(x: 1, y: 1),
          size: GridSize(width: 2, height: 2),
        ),
      );
      expect(generated.smartTileProvenance, isNotNull);
      expect(notifier.state.mapUndoStack, hasLength(2));
    });

    test('rejects non-encounter plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.movement(
            MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects non-walk encounter plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.encounter(
            EncounterZonePayload(
              encounterTableId: 'route_1_surf',
              encounterKind: EncounterKind.surf,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });
  });

  group('EditorNotifier surfable water Smart Tile generation', () {
    test(
        'adds multiple movement surf gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );
      final preview = buildSurfableWaterSmartTileGameplayZonePreview(
        map: initialMap,
        smartTileLayer: _waterLayer(),
        smartTilePresetId: 'water',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'water', name: 'Water')],
        ),
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: preview.plan!,
      );

      final state = container.read(editorNotifierProvider);
      final updatedMap = state.activeMap!;
      expect(applied, isTrue);
      expect(updatedMap.gameplayZones, hasLength(2));
      expect(
        updatedMap.gameplayZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.movement &&
              zone.movement?.requiredMode == MovementMode.surf &&
              zone.movement?.allowedModes.isEmpty == true,
        ),
        isTrue,
      );
      expect(state.selectedGameplayZoneId, updatedMap.gameplayZones.first.id);
      expect(state.isDirty, isTrue);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.canUndoMap, isTrue);
      expect(
        updatedMap.layers.whereType<SmartTileLayer>().single.field,
        initialMap.layers.whereType<SmartTileLayer>().single.field,
      );
    });

    test('rejects non-movement plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.encounter(
            EncounterZonePayload(
              encounterTableId: 'route_1_grass',
              encounterKind: EncounterKind.walk,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects movement plans that do not require surf without mutating',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.movement(
            MovementZonePayload(requiredMode: MovementMode.walk),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });
  });

  group('EditorNotifier lava hazard Smart Tile generation', () {
    test(
        'adds multiple hazard lava gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );
      final preview = buildLavaHazardSmartTileGameplayZonePreview(
        map: initialMap,
        smartTileLayer: _lavaLayer(),
        smartTilePresetId: 'lava',
        catalog: _smartTileCatalog(
          presets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        damagePerStep: 5,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: preview.plan!,
      );

      final state = container.read(editorNotifierProvider);
      final updatedMap = state.activeMap!;
      expect(applied, isTrue);
      expect(updatedMap.gameplayZones, hasLength(2));
      expect(
        updatedMap.gameplayZones.every(
          (zone) =>
              zone.kind == GameplayZoneKind.hazard &&
              zone.hazard?.hazardKind == HazardKind.lava &&
              zone.hazard?.damagePerStep == 5,
        ),
        isTrue,
      );
      expect(state.selectedGameplayZoneId, updatedMap.gameplayZones.first.id);
      expect(state.isDirty, isTrue);
      expect(state.mapUndoStack, hasLength(1));
      expect(state.canUndoMap, isTrue);
      expect(
        updatedMap.layers.whereType<SmartTileLayer>().single.field,
        initialMap.layers.whereType<SmartTileLayer>().single.field,
      );
    });

    test('rejects non-hazard plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.movement(
            MovementZonePayload(requiredMode: MovementMode.surf),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects non-lava hazard plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.hazard(
            HazardZonePayload(
              hazardKind: HazardKind.poison,
              damagePerStep: 5,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });

    test('rejects lava hazard plans without positive damage', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSmartTile();
      notifier.state = EditorState(
        project: _projectManifest(
          smartTilePresets: [_smartTilePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'smart-tile-main',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SmartTileGameplayZoneBehaviorDraft.hazard(
            HazardZonePayload(
              hazardKind: HazardKind.lava,
              damagePerStep: 0,
            ),
          ),
        ),
      );

      final state = container.read(editorNotifierProvider);
      expect(applied, isFalse);
      expect(state.activeMap, initialMap);
      expect(state.activeMap!.gameplayZones, isEmpty);
      expect(state.mapUndoStack, isEmpty);
      expect(state.selectedGameplayZoneId, isNull);
      expect(state.isDirty, isFalse);
    });
  });
}

SmartTileGameplayZoneGenerationPlan _planForBehavior(
  SmartTileGameplayZoneBehaviorDraft behavior,
) {
  return createSmartTileGameplayZoneGenerationPlan(
    source: SmartTileGameplayZoneGenerationSource(
      smartTileLayerId: 'smart-tile-main',
      smartTileLayerName: 'Surfaces',
      smartTilePresetId: 'tall_grass',
      materialId: 'grass',
      cells: const [
        GridPos(x: 0, y: 0),
        GridPos(x: 2, y: 0),
      ],
      mapSize: const GridSize(width: 8, height: 8),
    ),
    behavior: behavior,
    strategy: SmartTileGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'tall-grass-encounter',
    zoneNamePrefix: 'Tall Grass - Rencontre',
  );
}

MapData _mapWithTallGrassSmartTile() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_tallGrassLayer()],
  );
}

MapData _mapWithWaterSmartTile() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_waterLayer()],
  );
}

MapData _mapWithLavaSmartTile() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_lavaLayer()],
  );
}

SmartTileLayer _tallGrassLayer() {
  return _smartTileLayer(
    presetId: 'tall_grass',
    paintedCellIndexes: const <int>[0, 1, 8],
  );
}

SmartTileLayer _waterLayer() {
  return _smartTileLayer(
    presetId: 'water',
    paintedCellIndexes: const <int>[2, 3, 10],
  );
}

SmartTileLayer _lavaLayer() {
  return _smartTileLayer(
    presetId: 'lava',
    paintedCellIndexes: const <int>[4, 5, 12],
  );
}

SmartTileLayer _smartTileLayer({
  required String presetId,
  required List<int> paintedCellIndexes,
}) {
  final semanticCells = List<int>.filled(8 * 8, 0);
  for (final index in paintedCellIndexes) {
    semanticCells[index] = 1;
  }
  return SmartTileLayer(
    id: 'smart-tile-main',
    name: 'Smart Tiles',
    presetId: presetId,
    usage: SmartTileUsage.forestSurface,
    materialPalette: <String>['', '$presetId-material'],
    field: SmartTileField.cell(semanticCells: semanticCells),
  );
}

ProjectManifest _projectManifest({
  List<ProjectSmartTilePreset>? smartTilePresets,
}) {
  return ProjectManifest(
    name: 'Demo',
    maps: const [],
    tilesets: const [],
    encounterTables: const [
      ProjectEncounterTable(
        id: 'route_1_grass',
        name: 'Route 1 Grass',
        encounterKind: EncounterKind.walk,
      ),
    ],
    smartTileCatalog: _smartTileCatalog(
      presets: smartTilePresets ??
          <ProjectSmartTilePreset>[
            _smartTilePreset(id: 'tall_grass', name: 'Tall Grass'),
          ],
    ),
  );
}

ProjectSmartTileCatalog _smartTileCatalog({
  required List<ProjectSmartTilePreset> presets,
}) {
  return ProjectSmartTileCatalog(
    materials: <ProjectSmartTileMaterial>[
      for (final preset in presets)
        ProjectSmartTileMaterial(
          id: preset.defaultMaterialId,
          name: '${preset.name} material',
          connectionGroupId: preset.id,
        ),
    ],
    presets: presets,
  );
}

ProjectSmartTilePreset _smartTilePreset({
  required String id,
  required String name,
}) {
  return ProjectSmartTilePreset(
    id: id,
    name: name,
    usage: SmartTileUsage.forestSurface,
    topology: SmartTileTopology.uniform,
    templateHint: SmartTileTemplateHint.simple,
    status: SmartTilePresetStatus.published,
    coveragePolicy: SmartTileCoveragePolicy.complete,
    coverageProfile: const SmartTileCoverageProfile(
      mode: SmartTileCoverageMode.template,
    ),
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: '$id-material',
    allowedMaterialIds: <String>['$id-material'],
  );
}
