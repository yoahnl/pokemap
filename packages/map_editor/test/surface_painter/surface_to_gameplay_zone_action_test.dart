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

  group('Surfable water surface to gameplay zone presenter', () {
    test('builds a greedy movement/surf generation preview from painted cells',
        () {
      final preview = buildSurfableWaterSurfaceGameplayZonePreview(
        map: _mapWithWaterSurface(),
        surfaceLayer: _waterLayer(),
        surfacePresetId: 'water',
        presets: [_surfacePreset(id: 'water', name: 'Water')],
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
              zone.kind == GameplayZoneKind.movement &&
              zone.movement?.requiredMode == MovementMode.surf &&
              zone.movement?.allowedModes.isEmpty == true,
        ),
        isTrue,
      );
      expect(preview.assessment!.coveragePercent, 1);
      expect(preview.assessment!.extraCellRatio, 0);
    });

    test('blocks when selected water surface has no painted placement', () {
      final preview = buildSurfableWaterSurfaceGameplayZonePreview(
        map: _mapWithWaterSurface(),
        surfaceLayer: _waterLayer(),
        surfacePresetId: 'tall_grass',
        presets: [
          _surfacePreset(id: 'water', name: 'Water'),
          _surfacePreset(id: 'tall_grass', name: 'Tall Grass'),
        ],
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

  group('Lava hazard surface to gameplay zone presenter', () {
    test('builds a greedy hazard/lava generation preview from painted cells',
        () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isTrue);
      expect(preview.damagePerStep, 5);
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
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 0,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(preview.plan, isNull);
      expect(
        preview.messages.map((message) => message.title),
        contains('Dégâts par pas invalides'),
      );
    });

    test('blocks when selected lava surface has no painted placement', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'water',
        presets: [
          _surfacePreset(id: 'lava', name: 'Lava'),
          _surfacePreset(id: 'water', name: 'Water'),
        ],
        damagePerStep: 5,
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

    test('blocks when selected lava preset is absent from catalog', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: _mapWithLavaSurface(),
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: const [],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Surface absente du catalogue'),
      );
    });

    test('blocks when map is null', () {
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: null,
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
        damagePerStep: 5,
      );

      expect(preview.canConfirm, isFalse);
      expect(
        preview.status,
        SurfaceGameplayZoneGenerationAssessmentStatus.blocked,
      );
      expect(
        preview.messages.map((message) => message.title),
        contains('Aucune map active'),
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

  group('SurfableWaterSurfaceGameplayZoneDialog', () {
    testWidgets('confirms a ready surfable water plan', (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: SurfableWaterSurfaceGameplayZoneDialog(
              map: _mapWithWaterSurface(),
              surfaceLayer: _waterLayer(),
              surfacePresetId: 'water',
              presets: [_surfacePreset(id: 'water', name: 'Water')],
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
            child: SurfableWaterSurfaceGameplayZoneDialog(
              map: _mapWithWaterSurface(),
              surfaceLayer: _waterLayer(),
              surfacePresetId: 'tall_grass',
              presets: [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
              onConfirm: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Aucune cellule peinte'), findsOneWidget);
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

  group('LavaHazardSurfaceGameplayZoneDialog', () {
    testWidgets('confirms a ready lava hazard plan with default damage',
        (tester) async {
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LavaHazardSurfaceGameplayZoneDialog(
              map: _mapWithLavaSurface(),
              surfaceLayer: _lavaLayer(),
              surfacePresetId: 'lava',
              presets: [_surfacePreset(id: 'lava', name: 'Lava')],
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
        find.byKey(const Key('surface-to-gameplay-zone-lava-damage-field')),
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
      SurfaceGameplayZoneGenerationPlan? confirmedPlan;

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            child: LavaHazardSurfaceGameplayZoneDialog(
              map: _mapWithLavaSurface(),
              surfaceLayer: _lavaLayer(),
              surfacePresetId: 'lava',
              presets: [_surfacePreset(id: 'lava', name: 'Lava')],
              onConfirm: (plan) => confirmedPlan = plan,
            ),
          ),
        ),
      );

      final field = find.byKey(
        const Key('surface-to-gameplay-zone-lava-damage-field'),
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

  group('SurfacePainterPanel behavior action menu', () {
    testWidgets('shows one behavior action and opens behavior choices',
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

      expect(
        find.text('Créer un comportement depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Créer une zone de rencontre'), findsNothing);
      expect(find.text('Rendre cette eau surfable'), findsNothing);

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      expect(find.text('Herbe haute avec rencontres'), findsOneWidget);
      expect(find.text('Eau surfable'), findsOneWidget);
      expect(find.text('Lave dangereuse'), findsOneWidget);
    });

    testWidgets('routes tall grass choice to the encounter dialog',
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

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Herbe haute avec rencontres'));
      await tester.pumpAndSettle();

      expect(
        find.text('Créer une zone de rencontre depuis cette surface'),
        findsOneWidget,
      );
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });

    testWidgets('routes water choice to the surfable water dialog',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: _mapWithWaterSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
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

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eau surfable'));
      await tester.pumpAndSettle();

      expect(find.text('Rendre cette eau surfable'), findsOneWidget);
      expect(find.text('Plan prêt à appliquer'), findsOneWidget);
    });

    testWidgets('routes lava choice to the lava hazard dialog', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final keepAlive = container.listen(editorNotifierProvider, (_, __) {});
      addTearDown(keepAlive.close);
      container.read(editorNotifierProvider.notifier).state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: _mapWithLavaSurface(),
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
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

      await tester.tap(
        find.text('Créer un comportement depuis cette surface'),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lave dangereuse'));
      await tester.pumpAndSettle();

      expect(find.text('Créer une zone de lave dangereuse'), findsOneWidget);
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

  group('EditorNotifier surfable water surface generation', () {
    test(
        'adds multiple movement surf gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
        savedMapSnapshot: initialMap,
      );
      final preview = buildSurfableWaterSurfaceGameplayZonePreview(
        map: initialMap,
        surfaceLayer: _waterLayer(),
        surfacePresetId: 'water',
        presets: [_surfacePreset(id: 'water', name: 'Water')],
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
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });

    test('rejects non-movement plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithWaterSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
        savedMapSnapshot: initialMap,
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.encounter(
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
      final initialMap = _mapWithWaterSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'water', name: 'Water')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'water',
        savedMapSnapshot: initialMap,
      );

      final applied = applySurfableWaterGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.movement(
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

  group('EditorNotifier lava hazard surface generation', () {
    test(
        'adds multiple hazard lava gameplay zones in one mutation and selects first',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );
      final preview = buildLavaHazardSurfaceGameplayZonePreview(
        map: initialMap,
        surfaceLayer: _lavaLayer(),
        surfacePresetId: 'lava',
        presets: [_surfacePreset(id: 'lava', name: 'Lava')],
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
        updatedMap.layers.whereType<SurfaceLayer>().single.placements,
        initialMap.layers.whereType<SurfaceLayer>().single.placements,
      );
    });

    test('rejects non-hazard plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
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

    test('rejects non-lava hazard plans without mutating the map', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.hazard(
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
      final initialMap = _mapWithLavaSurface();
      notifier.state = EditorState(
        project: _projectManifest(
          surfacePresets: [_surfacePreset(id: 'lava', name: 'Lava')],
        ),
        activeMap: initialMap,
        activeLayerId: 'surface-main',
        selectedSurfacePresetId: 'lava',
        savedMapSnapshot: initialMap,
      );

      final applied = applyLavaHazardGameplayZonePlan(
        notifier: notifier,
        plan: _planForBehavior(
          const SurfaceGameplayZoneBehaviorDraft.hazard(
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

MapData _mapWithWaterSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_waterLayer()],
  );
}

MapData _mapWithLavaSurface() {
  return MapData(
    id: 'route_1',
    name: 'Route 1',
    size: const GridSize(width: 8, height: 8),
    layers: [_lavaLayer()],
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

SurfaceLayer _waterLayer() {
  return const SurfaceLayer(
    id: 'surface-main',
    name: 'Surfaces',
    placements: [
      SurfaceCellPlacement(
        x: 2,
        y: 0,
        surfacePresetId: 'water',
      ),
      SurfaceCellPlacement(
        x: 3,
        y: 0,
        surfacePresetId: 'water',
      ),
      SurfaceCellPlacement(
        x: 2,
        y: 1,
        surfacePresetId: 'water',
      ),
    ],
  );
}

SurfaceLayer _lavaLayer() {
  return const SurfaceLayer(
    id: 'surface-main',
    name: 'Surfaces',
    placements: [
      SurfaceCellPlacement(
        x: 4,
        y: 0,
        surfacePresetId: 'lava',
      ),
      SurfaceCellPlacement(
        x: 5,
        y: 0,
        surfacePresetId: 'lava',
      ),
      SurfaceCellPlacement(
        x: 4,
        y: 1,
        surfacePresetId: 'lava',
      ),
    ],
  );
}

ProjectManifest _projectManifest({
  List<ProjectSurfacePreset>? surfacePresets,
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
    surfaceCatalog: ProjectSurfaceCatalog(
      presets: surfacePresets ??
          [_surfacePreset(id: 'tall_grass', name: 'Tall Grass')],
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
