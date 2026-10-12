import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_model_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_spatial_preview_map.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/spatial_map_editor.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_terrain_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_canvas_stroke.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_brush_selection.dart';
import 'package:avelune_studio/features/map_workspace/application/spatial_terrain_stroke.dart';
import 'package:avelune_studio/presentation/features/resources/resource_creation_buttons.dart';
import 'package:avelune_studio/presentation/features/resources/resource_terrain_preview.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_editor_screen.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_model_part_controls.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_scratch_view.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_render_3d/map_render_3d.dart';

import '../application/spatial_terrain_draft_test.dart'
    show spatialPathDraft, spatialPathModel;
import '../support/map_workspace_fixture.dart';
import '../terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  for (final previousMode in [
    SpatialTerrainMode.relief,
    SpatialTerrainMode.ramp,
  ]) {
    testWidgets(
      'choosing a model path after ${previousMode.name} paints cells without changing height',
      (tester) async {
        final draft = spatialPathDraft();
        final preset = draft.previewPreset;
        final project = draft.manifest.copyWith(
          elements: const [],
          tilesets: const [],
          settings: draft.manifest.settings.copyWith(
            spatialCamera: SpatialCameraProfile(),
          ),
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: draft.draft.materials,
            presets: [preset],
          ),
        );
        final map = MapData(
          id: 'a',
          name: 'Pilote',
          version: ProjectVersion.v9,
          size: const GridSize(width: 8, height: 8),
          spatialScene: MapSpatialScene(width: 8, depth: 8),
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        final controller =
            MapWorkspaceController(workspaceSession, WorkspaceMemoryPort())
              ..project = project
              ..active = document;
        final view = MapWorkspaceViewState()
          ..spatialTerrainMode = previousMode
          ..spatialTerrainLevel = 4;
        addTearDown(controller.dispose);
        addTearDown(view.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  Builder(
                    builder: (context) => StudioButton(
                      label: 'Choisir herbes',
                      onPressed: () => useResourceOnMap(
                        context: context,
                        workspace: controller,
                        item: ResourceItem(
                          id: preset.id,
                          name: preset.name,
                          kind: ResourceKind.terrains,
                          terrain: preset,
                        ),
                        visuals: _SpatialVisuals(),
                        view: () => view,
                      ),
                    ),
                  ),
                  Expanded(
                    child: SpatialMapEditor(
                      document: document,
                      controller: controller,
                      project: project,
                      visuals: _SpatialVisuals(),
                      view: view,
                      onChanged: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.tap(find.text('Choisir herbes'));
        await tester.pump();
        expect(view.spatialTerrainMode, SpatialTerrainMode.ground);
        expect(view.spatialTerrainLevel, 4);
        final scene = tester.widget<SpatialSceneView>(
          find.byType(SpatialSceneView),
        );
        expect(scene.onDragStart!(2, 3, null), isTrue, reason: document.error);
        scene.onDragEnd!();
        expect(
          document.current.spatialScene!.heightLevels,
          map.spatialScene!.heightLevels,
        );
        expect(
          document.current.layers.whereType<SmartTileLayer>(),
          hasLength(1),
        );
        expect(
          resolveSpatialSmartTileInstances(
            map: document.current,
            catalog: project.smartTileCatalog,
          ),
          hasLength(1),
        );
        expect(document.current.spatialScene!.instances, isEmpty);
        document.restore(redo: false);
        expect(document.current, map);
        await tester.pumpWidget(const SizedBox());
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final spatial in [false, true]) {
    testWidgets(
      'material picker paints the allowed choice and resets with another preset in ${spatial ? '3D' : '2D'}',
      (tester) async {
        await tester.binding.setSurfaceSize(const Size(1200, 800));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final draft = terrainDraft();
        assignAll(draft);
        final spatialDraft = spatialPathDraft();
        final base = spatial ? spatialDraft.manifest : publishFixture(draft);
        final original = spatial
            ? spatialDraft.previewPreset
            : base.smartTileCatalog.presets.single;
        final preset = original.copyWith(
          allowedMaterialIds: [original.defaultMaterialId, 'paving'],
          rules: [
            ...original.rules,
            for (final rule in original.rules)
              rule.copyWith(
                id: '${rule.id}-paving',
                centerMatch: const SmartTileSlotMatch.material('paving'),
              ),
          ],
        );
        final next = original.copyWith(id: 'another', name: 'Autre chemin');
        final project = base.copyWith(
          elements: spatial ? const [] : base.elements,
          tilesets: spatial ? const [] : base.tilesets,
          settings: spatial
              ? base.settings.copyWith(spatialCamera: SpatialCameraProfile())
              : base.settings,
          smartTileCatalog: ProjectSmartTileCatalog(
            atlases: base.smartTileCatalog.atlases,
            presets: [preset, next],
            materials: [
              ...(spatial
                  ? spatialDraft.draft.materials
                  : base.smartTileCatalog.materials),
              const ProjectSmartTileMaterial(
                id: 'paving',
                name: 'Pavés de pierre',
                connectionGroupId: 'paving',
              ),
            ],
          ),
        );
        final map = MapData(
          id: 'a',
          name: 'Pilote',
          version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
          size: const GridSize(width: 8, height: 8),
          spatialScene: spatial ? MapSpatialScene(width: 8, depth: 8) : null,
        );
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
        );
        final view = MapWorkspaceViewState()..prepareTerrainPainting(preset);
        addTearDown(view.dispose);
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            home: Scaffold(
              body: MapTerrainToolPanel(
                document: document,
                project: project,
                visuals: spatial
                    ? _PendingModelVisuals()
                    : WorkspaceTestVisuals(),
                view: view,
                onChanged: () {},
              ),
            ),
          ),
        );
        final picker = find.byKey(const ValueKey('terrain-material-picker'));
        await tester.tap(picker);
        await tester.pump(const Duration(milliseconds: 300));
        await tester.tap(find.text('Pavés de pierre').last);
        await tester.pump(const Duration(milliseconds: 300));
        expect(view.terrainMaterialId, 'paving');
        final stroke = MapCanvasStroke.start(
          map: document.current,
          project: project,
          view: view,
          commands: MapEditingCommands(document, project),
          origin: const GridPos(x: 2, y: 3),
        )!;
        document.commit(stroke.commit());
        expect(
          smartTileMaterialIdAt(
            document.current.layers.whereType<SmartTileLayer>().single,
            mapSize: map.size,
            x: 2,
            y: 3,
          ),
          'paving',
        );
        document.restore(redo: false);
        expect(document.current, map);
        view.prepareTerrainPainting(preset);
        expect(view.terrainMaterialId, 'paving');
        view.prepareTerrainPainting(next);
        expect(view.terrainMaterialId, next.defaultMaterialId);
        expect(view.spatialTerrainMode, SpatialTerrainMode.ground);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('absolute model height is labelled independently of relief', (
    tester,
  ) async {
    final part = SmartTileVisualPart(
      source: const SmartTileVisualSource.model3d(
        modelId: 'water',
        offsetY: -2.25,
        followTerrain: false,
      ),
    );
    double? appliedHeight;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: TerrainModelPartControls(
            part: part,
            onApply: (_, _, height, _, _) => appliedHeight = height,
          ),
        ),
      ),
    );
    expect(find.text('Hauteur absolue'), findsOneWidget);
    expect(
      find.text('En unités de carte, indépendante du relief'),
      findsOneWidget,
    );
    expect(find.text('Décalage vertical'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('terrain-model-apply')));
    expect(appliedHeight, -2.25);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'creation chooses a project model through the shared family picker',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final model = spatialPathDraft();
      final project = model.manifest.copyWith(
        models3d: [
          ...model.manifest.models3d,
          spatialPathModel('private', name: 'Herbe privée'),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(
              id: 'grass',
              name: 'Hautes herbes',
              parentId: 'vegetation',
            ),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'oak',
              familyId: 'grass',
              role: ResourceLibraryRole.component,
            ),
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'private',
              familyId: 'grass',
              mapId: 'a',
            ),
          ],
        ),
      );
      ResourceItem? picked;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: Builder(
              builder: (context) => StudioButton(
                label: 'Créer un chemin',
                onPressed: () => chooseResourceSource(
                  context: context,
                  project: project,
                  visuals: WorkspaceTestVisuals(),
                  onChosen: (item) => picked = item,
                  onImport: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Créer un chemin'));
      await tester.pumpAndSettle();
      expect(find.text('Choisir le modèle du chemin'), findsOneWidget);
      expect(find.text('Herbe privée'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('resource-source-families')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('resource-nature-family-grass')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('path-source-oak')));
      await tester.pumpAndSettle();
      expect(picked!.canonicalKind, 'model3d');
      expect(picked!.id, 'oak');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'spatial atelier validates source transforms, publishes through canonical callbacks and keeps atlas absent',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(1500, 1100));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final model = spatialPathDraft();
      final actions = <String>[];
      ProjectSmartTilePreset? used;
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: Scaffold(
            body: TerrainEditorScreen(
              controller: model,
              image: const SizedBox(),
              frameBuilder: (_, _) =>
                  throw StateError('A model path cannot request image frames'),
              visuals: WorkspaceTestVisuals(),
              onMutate: (action, parameters) async {
                actions.add(action);
                if (action.endsWith('upsert')) {
                  return model.manifest.copyWith(
                    smartTileCatalog: ProjectSmartTileCatalog(
                      drafts: [
                        ProjectSmartTileAuthoringDraft.fromJson(
                          parameters['draft'] as Map<String, dynamic>,
                        ),
                      ],
                    ),
                  );
                }
                final compiled = compileSmartTileAuthoringDraft(
                  draft: model.draft,
                  catalog: model.manifest.smartTileCatalog,
                  manifest: model.manifest,
                ) as SmartTileDraftCompilationSuccess;
                return model.manifest.copyWith(
                  smartTileCatalog: ProjectSmartTileCatalog(
                    materials: compiled.materials,
                    atlases: compiled.atlases,
                    presets: [compiled.preset],
                    drafts: [model.draft],
                  ),
                );
              },
              onUse: (preset) => used = preset,
              onClose: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('atlas-selection')), findsNothing);
      Finder field(String id) => find.descendant(
        of: find.byKey(ValueKey(id)),
        matching: find.byType(TextField),
      );
      await tester.enterText(field('terrain-model-scale'), 'NaN');
      await tester.tap(find.byKey(const ValueKey('terrain-model-apply')));
      expect((model.partFor(0)!.source as SmartTileModel3dSource).scale, 1);
      await tester.enterText(field('terrain-model-scale'), '1,5');
      await tester.enterText(field('terrain-model-offset-x'), 'Infinity');
      await tester.pump();
      expect(
        tester
            .widget<StudioButton>(
              find.byKey(const ValueKey('terrain-model-apply')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('terrain-model-apply')));
      expect((model.partFor(0)!.source as SmartTileModel3dSource).scale, 1);
      await tester.enterText(field('terrain-model-offset-x'), '0,125');
      await tester.enterText(field('terrain-model-offset-z'), '-0,375');
      await tester.enterText(field('terrain-model-height'), '0,2');
      tester
          .widget<StudioSelect>(
            find.widgetWithText(StudioSelect, 'Rotation de la pièce'),
          )
          .onChanged!('1');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('terrain-model-apply')));
      await tester.pump();
      expect(model.partFor(0)!.transform.quarterTurns, 1);
      expect((model.partFor(0)!.source as SmartTileModel3dSource).scale, 1.5);
      expect(
        (model.partFor(0)!.source as SmartTileModel3dSource).offsetX,
        .125,
      );
      expect(
        (model.partFor(0)!.source as SmartTileModel3dSource).offsetZ,
        -.375,
      );
      await tester.tap(find.text('Publier et peindre'));
      await tester.pumpAndSettle();
      expect(actions, [
        'smart_tile.preset.draft.upsert',
        'smart_tile.preset.publish',
      ]);
      expect(model.error, isNull, reason: model.error);
      expect(used!.id, 'grass');
      expect(model.manifest.smartTileCatalog.atlases, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'trial and library preview consume native models with the exact semantic paint mask',
    (tester) async {
      final model = spatialPathDraft()..clearScratch();
      final visuals = _SpatialVisuals();
      void refresh() {}
      Widget trial(String tool) => MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            child: TerrainScratchView(
              controller: model,
              frameBuilder: (_, _) => throw StateError(
                'Image preview is forbidden for model paths',
              ),
              visuals: visuals,
              onChanged: refresh,
              tool: tool,
            ),
          ),
        ),
      );
      await tester.pumpWidget(trial('Peindre'));
      SpatialSceneView scene() =>
          tester.widget<SpatialSceneView>(find.byType(SpatialSceneView));
      expect(scene().scene.instances, isEmpty);
      expect(scene().onDragStart!(2, 4, null), isTrue);
      scene().onDragUpdate!((5, 4));
      scene().onDragEnd!();
      await tester.pumpWidget(trial('Peindre'));
      expect(scene().scene.instances.length, 4);
      expect(
        scene().scene.instances
            .map((instance) => (instance.position.x, instance.position.z))
            .toSet(),
        {(2.5, 4.5), (3.5, 4.5), (4.5, 4.5), (5.5, 4.5)},
      );
      await tester.pumpWidget(trial('Gommer'));
      scene().onCell(3, 4);
      await tester.pumpWidget(trial('Examiner'));
      expect(scene().scene.instances.length, 3);
      scene().onCell(2, 4);
      expect(model.selectedRule, 0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.square(
              dimension: 200,
              child: ResourceTerrainPreview(
                preset: model.previewPreset,
                project: scene().groundProject!,
                visuals: visuals,
                size: 200,
              ),
            ),
          ),
        ),
      );
      expect(scene().scene.instances.length, 9);
      expect(
        scene().scene.instances.every((instance) => instance.modelId == 'oak'),
        isTrue,
      );
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'model paths preserve dimensions and expose paint in the shared catalogue',
    () {
      final model = spatialPathDraft();
      final item = ResourceItem(
        id: 'grass',
        name: 'Herbes',
        kind: ResourceKind.terrains,
        terrain: model.previewPreset,
      );
      expect(item.compatibleWith(ProjectDimension.twoD), isFalse);
      expect(item.compatibleWith(ProjectDimension.threeD), isTrue);
      expect(
        resourceCatalog(model.manifest)
            .firstWhere((item) => item.model3d != null)
            .usages,
        contains(ResourceCatalogUsage.paint),
      );
    },
  );

  testWidgets(
    'painted model pieces guide selection back to terrain without storing objects',
    (tester) async {
      final model = spatialPathDraft()..clearScratch();
      model.paint(const GridPos(x: 2, y: 3));
      final preview = terrainSpatialPreviewMap(
        project: model.manifest,
        preset: model.previewPreset,
        size: 17,
        cells: model.scratch,
        materials: model.draft.materials,
      );
      final derived = preview.map.spatialScene!.instances.single;
      final map = preview.map.copyWith(
        spatialScene: preview.map.spatialScene!.copyWith(instances: []),
      );
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
      );
      final commands = SpatialModelEditingCommands(document, preview.project);
      final view = MapWorkspaceViewState()..tool = StudioMapTool.select;
      final controller = MapWorkspaceController(
        workspaceSession,
        WorkspaceMemoryPort(),
      );
      addTearDown(view.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SpatialMapEditor(
              document: document,
              controller: controller,
              project: preview.project,
              visuals: _SpatialVisuals(),
              view: view,
              onChanged: () {},
            ),
          ),
        ),
      );
      final scene = tester.widget<SpatialSceneView>(
        find.byType(SpatialSceneView),
      );
      final hit = SpatialSceneContentHit(
        kind: SpatialSceneContentKind.model,
        id: derived.id,
        cell: (2, 3),
      );
      expect(scene.onDragStart!(2, 3, hit), isFalse);
      expect(document.error, contains('Terrains et son calque'));
      scene.onContent!(hit);
      expect(document.current, same(map));
      expect(document.undoCount, 0);
      expect(document.current.spatialScene!.instances, isEmpty);
      expect(commands.selected(derived.id), isNull);
      expect(() => commands.update(derived.id, x: 5), throwsStateError);
      expect(() => commands.delete(derived.id), throwsStateError);
      expect(() => commands.duplicate(derived.id), throwsStateError);
      await tester.pumpWidget(const SizedBox());
      expect(tester.takeException(), isNull);
    },
  );
}

class _SpatialVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  @override
  Future<Uint8List> readModel(String modelId) async => Uint8List(0);
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}

class _PendingModelVisuals extends _SpatialVisuals {
  final source = Completer<Uint8List>();
  @override
  Future<Uint8List> readModel(String modelId) => source.future;
}
