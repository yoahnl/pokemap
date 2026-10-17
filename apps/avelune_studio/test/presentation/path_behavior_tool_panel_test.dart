import 'dart:async';
import 'dart:typed_data';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_terrain_tool_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/presentation/features/terrains/terrain_source_panel.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_select.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('path behavior can be configured before painting and undone', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final draft = spatialPathDraft();
    final preset = draft.previewPreset.copyWith(
      status: SmartTilePresetStatus.published,
    );
    final project = draft.manifest.copyWith(
      version: ProjectVersion.v9,
      elements: const [],
      tilesets: const [],
      settings: draft.manifest.settings.copyWith(
        spatialCamera: SpatialCameraProfile(),
      ),
      maps: const [
        ProjectMapEntry(id: 'a', name: 'Map', relativePath: 'maps/a.json'),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: draft.draft.materials,
        presets: [preset],
      ),
      encounterTables: const [
        ProjectEncounterTable(
          id: 'grass',
          name: 'Herbes de la route',
          encounterKind: EncounterKind.walk,
          entries: [
            ProjectEncounterEntry(speciesId: 'zubat', minLevel: 2, maxLevel: 4),
          ],
        ),
      ],
    );
    final map = MapData(
      version: ProjectVersion.v9,
      id: 'a',
      name: 'Map',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r0'),
    );
    final view = MapWorkspaceViewState()..prepareTerrainPainting(preset);
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, refresh) => MapTerrainToolPanel(
              document: document,
              project: project,
              visuals: _PathVisuals(),
              view: view,
              onChanged: () => refresh(() {}),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('path-animation-activation')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Au passage').last);
    await tester.pump(const Duration(seconds: 1));
    expect(document.error, isNull);
    final layer = document.current.layers.whereType<SmartTileLayer>().single;
    expect(layer.animationActivation, SmartTileAnimationActivation.onEnter);
    expect(smartTileSemanticCells(layer).every((value) => value == 0), true);
    await tester.tap(find.byKey(const ValueKey('path-encounter-table')));
    await tester.pump(const Duration(seconds: 1));
    await tester.tap(find.text('Herbes de la route').last);
    await tester.pump(const Duration(seconds: 1));
    expect(document.error, isNull);
    final configured = document.current.layers
        .whereType<SmartTileLayer>()
        .single;
    expect(configured.encounterBehavior!.encounter.encounterTableId, 'grass');
    expect(configured.encounterBehavior!.materialId, preset.defaultMaterialId);
    expect(document.current.gameplayZones, isEmpty);
    MapValidator.validate(document.current, projectDialogueContext: project);
    final select = tester.widget<StudioSelect>(
      find.byKey(const ValueKey('path-encounter-table')),
    );
    select.onChanged!('');
    await tester.pump(const Duration(seconds: 1));
    expect(
      document.current.layers
          .whereType<SmartTileLayer>()
          .single
          .encounterBehavior,
      isNull,
    );
    document.restore(redo: false);
    expect(
      document.current.layers
          .whereType<SmartTileLayer>()
          .single
          .encounterBehavior,
      configured.encounterBehavior,
    );
    expect(document.current.spatialScene, map.spatialScene);
  });

  testWidgets(
    'resource animation picker selects a clip and keeps static models explicit',
    (tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final base = spatialPathDraft();
      final original = base.manifest.models3d.single;
      final animated = ProjectModel3dEntry(
        id: original.id,
        name: original.name,
        sourceAssetId: original.sourceAssetId,
        relativePath: original.relativePath,
        inspection: Model3dInspection(
          bounds: original.inspection.bounds,
          meshCount: 1,
          triangleCount: 4,
          animations: [
            Model3dAnimation(index: 0, name: 'Passage', durationSeconds: .6),
          ],
        ),
      );
      var draft = TerrainDraftController.resume(
        manifest: base.manifest.copyWith(models3d: [animated]),
        draft: base.draft,
      );
      final name = TextEditingController(text: draft.draft.name);
      final transform = TransformationController();
      addTearDown(name.dispose);
      addTearDown(transform.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, refresh) => SizedBox(
                width: 600,
                child: TerrainSourcePanel(
                  model: draft,
                  name: name,
                  image: const SizedBox(),
                  transform: transform,
                  onChanged: () => refresh(() {}),
                  onAssign: (_) {},
                  frameBuilder: (_, _) => const SizedBox(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('terrain-model-animation')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Passage').last);
      await tester.pumpAndSettle();
      expect(
        (draft.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
        0,
      );
      final select = tester.widget<StudioSelect>(
        find.byKey(const ValueKey('terrain-model-animation')),
      );
      select.onChanged!('');
      await tester.pumpAndSettle();
      expect(
        (draft.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
        isNull,
      );
      draft = base;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 600,
              child: TerrainSourcePanel(
                model: draft,
                name: name,
                image: const SizedBox(),
                transform: transform,
                onChanged: () {},
                onAssign: (_) {},
                frameBuilder: (_, _) => const SizedBox(),
              ),
            ),
          ),
        ),
      );
      expect(
        find.text('Ce modèle ne contient aucune animation.'),
        findsOneWidget,
      );
      expect(
        tester
            .widget<StudioSelect>(
              find.byKey(const ValueKey('terrain-model-animation')),
            )
            .onChanged,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}

class _PathVisuals extends WorkspaceTestVisuals
    implements SpatialWorkspaceVisuals {
  final source = Completer<Uint8List>();
  @override
  Future<Uint8List> readModel(String modelId) => source.future;
  @override
  Future<Uint8List> readGroundImage(String tilesetId) async => Uint8List(0);
  @override
  Future<SpatialNpcPreview> spatialPreview(MapData map) async =>
      SpatialNpcPreview({}, () {});
}
