import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/surface_painter/surface_palette_panel.dart';
import 'package:map_editor/src/features/surface_painter/surface_to_gameplay_zone_action.dart';
import 'package:map_editor/src/features/surface_painter/surface_to_gameplay_zone_dialog.dart';
import 'package:map_editor/src/features/surface_painter/surface_to_gameplay_zone_presenter.dart';

void main() {
  group('Tall grass surface to gameplay zone presenter', () {
    test('builds a greedy encounter generation preview from painted cells', () {
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: _mapWithTallGrassSurface(),
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'tall_grass',
        presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isTrue);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.ready,
      );
      expect(preview.plan, isNotNull);
      expect(
        preview.plan!.strategy,
        SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
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

    test('blocks confirmation when encounterTableId is empty', () {
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: _mapWithTallGrassSurface(),
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'tall_grass',
        presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
        encounterTableId: '   ',
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(preview.plan, isNull);
      expect(
        preview.messages.map((message) => message.title),
        contains('Table de rencontres requise'),
      );
    });

    test('blocks when selected surface has no painted placement', () {
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: _mapWithTallGrassSurface(),
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'water',
        presets: [
          _surfacePreset(id: 'tall_grass', name: 'Tall Grass'),
          _surfacePreset(id: 'water', name: 'Water'),
        ],
        encounterTableId: 'route_1_grass',
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune cellule peinte'),
      );
    });
  });

  group('SurfaceToGameplayZoneDialog', () {
    testWidgets('requires an encounter table id before confirming',
        (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfaceToGameplayZoneDialog(
              map: _mapWithTallGrassSurface(),
              surfaceLayer: _tallGrassLayer(),
              surfacePresetId: 'tall_grass',
              presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
              encounterTables: const [],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      expect(
        find.text('Créer une zone de rencontre depuis cette surface'),
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
        find.byKey(const Key('surface-to-gameplay-zone-encounter-table-field')),
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
  });

  group('SurfacePainterPanel action entry', () {
    testWidgets('opens the encounter generation dialog from the surface panel',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(),
        activeMap: _mapWithTallGrassSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const CupertinoApp(
            home: CupertinoPageScaffold(
              child: SurfacePainterPanel(embedded: true),
            ),
          ),
        ),
      );

      expect(find.text('Créer une zone de rencontre'), findsOneWidget);

      await tester.tap(find.text('Créer une zone de rencontre'));
      await tester.pumpAndSettle();

      expect(
        find.text('Créer une zone de rencontre depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });
  });

  group('EditorNotifier tall grass surface generation', () {
    test(
        'adds multiple encounter gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSurface();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
        savedMapSnapshot: initialMap,
      );
      final preview = buildTallGrassEncounterSurfaceGameplayZonePreview(
        map: initialMap,
        surfaceLayer: _tallGrassLayer(),
        surfacePresetId: 'tall_grass',
        presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
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
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });

    test('rejects non-encounter plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithTallGrassSurface();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
        savedMapSnapshot: initialMap,
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.movement(
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
      final initialMap = _mapWithTallGrassSurface();
      notifier.state = EditorState(
        project: _projectManifest(),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'tall_grass',
        savedMapSnapshot: initialMap,
      );

      final applied = applyTallGrassEncounterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.encounter(
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
}

SurfaceGameplayZoneGenerationPlan _planForBehavior(
  SurfaceGameplayZoneBehaviorDraft behavior,
) {
  return createSurfaceGameplayZoneGenerationPlan(
    source: SurfaceGameplayZoneGenerationSource(
      surfaceLayerId: 'surface-main',
      surfaceLayerName: 'Surfaces',
      surfacePresetId: 'tall_grass',
      cells: const [
        GridPos(x: 0, y: 0),
        GridPos(x: 2, y: 0),
      ],
      mapSize: const GridSize(width: 8, height: 8),
    ),
    behavior: behavior,
    strategy: SurfaceGameplayZoneGenerationStrategy.greedyRectangles,
    zoneIdPrefix: 'tall-grass-encounter',
    zoneNamePrefix: 'Tall Grass - Rencontre',
  );
}

MapData _mapWithTallGrassSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_tallGrassLayer()],
  );
}

SurfaceLayer _tallGrassLayer() {
  return const SurfaceLayer(
    id: 'surface-main',
    name: 'Surfaces',
    placements: [
      SurfaceCellPlacement(
        x: 0,
        y: 0,
        surfacePresetId: 'tall_grass',
      ),
      SurfaceCellPlacement(
        x: 1,
        y: 0,
        surfacePresetId: 'tall_grass',
      ),
      SurfaceCellPlacement(
        x: 0,
        y: 1,
        surfacePresetId: 'tall_grass',
      ),
    ],
  );
}

ProjectManifest _projectManifest() {
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
    surfaceCatalog: ProjectSurfaceCatalog(
      presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
    ),
  );
}

ProjectSurfacePreset _surfacePreset({
  required String id,
  required String name,
}) {
  return ProjectSurfacePreset(
    id: id,
    name: name,
    variantAnimations: SurfaceVariantAnimationRefSet(
      refs: [
        SurfaceVariantAnimationRef(
          role: SurfaceVariantRole.isolated,
          animationId: '$id-isolated',
        ),
      ],
    ),
  );
}
