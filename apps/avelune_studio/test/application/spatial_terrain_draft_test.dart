import 'dart:convert';

import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_spatial_preview_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/spatial_environment_fixture.dart';

TerrainDraftController spatialPathDraft() {
  final project = spatialEnvironmentProject();
  return TerrainDraftController.spatial(
    manifest: project,
    model: project.models3d.single,
    id: 'grass',
  );
}

ProjectModel3dEntry spatialPathModel(
  String id, {
  String name = 'Herbe locale',
}) {
  final source = spatialEnvironmentProject().models3d.single;
  return ProjectModel3dEntry(
    id: id,
    name: name,
    sourceAssetId: '$id-source',
    relativePath: 'assets/models3d/$id.glb',
    inspection: source.inspection,
  );
}

void main() {
  test('model animation selection, clearing and geometry edits preserve draft intent', () {
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
    final project = base.manifest.copyWith(models3d: [animated]);
    final draft = TerrainDraftController.resume(
      manifest: project,
      draft: base.draft,
    );
    draft.assignModel(
      animated,
      scale: 1.5,
      offsetX: .125,
      offsetY: .2,
      offsetZ: -.375,
      quarterTurns: 2,
      animationIndex: 0,
      changeAnimation: true,
    );
    final selected = draft.draft;
    final part = draft.partFor(0)!;
    expect((part.source as SmartTileModel3dSource).animationIndex, 0);
    expect(
      compileSmartTileAuthoringDraft(
        draft: selected,
        catalog: project.smartTileCatalog,
        manifest: project,
      ),
      isA<SmartTileDraftCompilationSuccess>(),
    );
    draft.assignModel(
      animated,
      scale: 1.5,
      offsetX: .125,
      offsetY: .2,
      offsetZ: -.375,
      quarterTurns: 2,
    );
    expect(draft.draft, selected);
    draft.assignModel(animated, animationIndex: 7, changeAnimation: true);
    expect(draft.draft, selected);
    draft.assignModel(
      animated,
      scale: 1.5,
      offsetX: .125,
      offsetY: .2,
      offsetZ: -.375,
      quarterTurns: 2,
      changeAnimation: true,
    );
    expect(
      draft.partFor(0),
      part.copyWith(
        source: (part.source as SmartTileModel3dSource).copyWith(
          animationIndex: null,
        ),
      ),
    );
    draft.undo();
    expect(draft.draft, selected);
    draft.redo();
    expect(
      (draft.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
      isNull,
    );
  });

  test('unit models compile without an atlas and painted cells produce native instances', () {
    final model = spatialPathDraft();
    expect(model.uniform, isTrue);
    expect(model.draft.atlases, isEmpty);
    expect(model.draft.sourceTilesetIds, isEmpty);
    expect(model.draft.primaryAtlasId, isNull);
    expect(model.draft.templateHint, SmartTileTemplateHint.simple);
    final compilation = compileSmartTileAuthoringDraft(
      draft: model.draft,
      catalog: model.manifest.smartTileCatalog,
      manifest: model.manifest,
    );
    expect(
      compilation,
      isA<SmartTileDraftCompilationSuccess>(),
      reason: compilation.toString(),
    );
    expect(
      ProjectSmartTileAuthoringDraft.fromJson(
        jsonDecode(jsonEncode(model.draft.toJson())) as Map<String, dynamic>,
      ),
      model.draft,
    );
    model.clearScratch();
    model.paintLine(const GridPos(x: 2, y: 3), const GridPos(x: 5, y: 3));
    model.paint(const GridPos(x: 3, y: 3), erase: true);
    model.assignModel(
      model.manifest.models3d.single,
      scale: 1.5,
      offsetX: .125,
      offsetY: .2,
      offsetZ: -.375,
      quarterTurns: 1,
    );
    final preview = terrainSpatialPreviewMap(
      project: model.manifest,
      preset: model.previewPreset,
      size: 17,
      cells: model.scratch,
      materials: model.draft.materials,
    );
    expect(
      preview.map.spatialScene!.instances
          .map((instance) => (instance.position.x, instance.position.z))
          .toSet(),
      {(2.875, 3.625), (4.875, 3.625), (5.875, 3.625)},
    );
    for (final instance in preview.map.spatialScene!.instances) {
      expect(instance.modelId, 'oak');
      expect(instance.scale, 1.5);
      expect(instance.rotationDegrees, -90);
      expect(instance.position.y, .2);
      expect(instance.blocksMovement, isFalse);
    }
    expect(model.manifest.smartTileCatalog.presets, isEmpty);
    expect(
      (preview.map.layers.single as SmartTileLayer).field.semanticCells
          .where((cell) => cell == 1)
          .length,
      3,
    );
  });

  test(
    'raccords, outer corners and transforms remain undoable and resume exactly',
    () {
      final model = spatialPathDraft();
      final uniform = model.draft;
      model.setSpatialConnections(true);
      expect(model.draft.rules.length, 16);
      model.selectedRule = 18;
      model.assignModel(
        model.manifest.models3d.single,
        scale: .5,
        offsetY: -.1,
        quarterTurns: 3,
      );
      expect(model.draft.rules.length, 20);
      expect(model.draft.topology, SmartTileTopology.blob8);
      expect(model.complete, isFalse);
      expect(model.partFor(18)!.transform.quarterTurns, 3);
      final draft = model.draft;
      final resumed = TerrainDraftController.resume(
        manifest: model.manifest,
        draft: draft,
      );
      expect(resumed.draft, draft);
      model.undo();
      expect(model.draft.rules.length, 16);
      expect(model.selectedRule, 15);
      model.undo();
      expect(model.draft, uniform);
      expect(model.selectedRule, 0);
      model.redo();
      model.redo();
      expect(model.draft, draft);
      expect(
        terrainDraftCompatibilityProblem(model.manifest, model.draft),
        isNull,
      );
    },
  );

  test('published spatial presets preserve metadata and reject unsupported mirroring', () {
    final model = spatialPathDraft();
    final originalPart = model
        .partFor(0)!
        .copyWith(
          source: (model.partFor(0)!.source as SmartTileModel3dSource).copyWith(
            animationIndex: 0,
            followTerrain: false,
            offsetX: .125,
            offsetZ: -.375,
          ),
        );
    final preset = model.previewPreset.copyWith(
      name: 'Herbes',
      categoryId: 'custom',
      sortOrder: 7,
      seedSalt: 19,
      tags: ['hautes'],
      rules: [
        model.previewPreset.rules.single.copyWith(
          id: 'original-rule',
          candidates: [
            model.previewPreset.rules.single.candidates.single.copyWith(
              id: 'original-candidate',
              weight: 3,
              parts: [
                originalPart.copyWith(
                  offsetUnit: SmartTileOffsetUnit.cell,
                  offsetX: 1,
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final project = model.manifest.copyWith(
      models3d: [
        ProjectModel3dEntry(
          id: model.manifest.models3d.single.id,
          name: model.manifest.models3d.single.name,
          sourceAssetId: model.manifest.models3d.single.sourceAssetId,
          relativePath: model.manifest.models3d.single.relativePath,
          inspection: Model3dInspection(
            bounds: model.manifest.models3d.single.inspection.bounds,
            meshCount: 1,
            triangleCount: 4,
            animations: [
              Model3dAnimation(index: 0, name: 'Flow', durationSeconds: 1),
            ],
          ),
        ),
      ],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: model.draft.materials,
        presets: [preset],
      ),
    );
    final draft = editableTerrainDraft(project, preset);
    expect(draft, isNotNull);
    final resumed = TerrainDraftController.resume(
      manifest: project,
      draft: draft!,
    );
    expect(resumed.previewPreset, preset);
    resumed.assignModel(project.models3d.single, quarterTurns: 2);
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).offsetX,
      .125,
    );
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).offsetZ,
      -.375,
    );
    expect(resumed.partFor(0)!.offsetX, 1);
    expect(resumed.partFor(0)!.offsetUnit, SmartTileOffsetUnit.cell);
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
      0,
    );
    expect(
      (resumed.partFor(0)!.source as SmartTileModel3dSource).followTerrain,
      isFalse,
    );
    final mirrored = draft.copyWith(
      rules: [
        draft.rules.single.copyWith(
          candidates: [
            draft.rules.single.candidates.single.copyWith(
              parts: [
                originalPart.copyWith(
                  transform: const SmartTileSpriteTransform(flipX: true),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    expect(
      () => TerrainDraftController.resume(manifest: project, draft: mirrored),
      throwsStateError,
    );
    expect(
      () => TerrainDraftController.resume(
        manifest: project.copyWith(
          settings: const ProjectSettings(dimension: ProjectDimension.twoD),
        ),
        draft: draft,
      ),
      throwsStateError,
    );
  });

  test('shared creation excludes local models and scoped paths accept only their own map sources', () {
    final model = spatialPathDraft();
    final local = spatialPathModel('local');
    final other = spatialPathModel('other');
    final project = model.manifest.copyWith(
      models3d: [...model.manifest.models3d, local, other],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'local',
            familyId: 'vegetation',
            mapId: 'a',
          ),
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'other',
            familyId: 'vegetation',
            mapId: 'b',
          ),
        ],
      ),
    );
    expect(
      () => TerrainDraftController.spatial(
        manifest: project,
        model: local,
        id: 'new',
      ),
      throwsStateError,
    );
    model.manifest = project;
    final original = model.draft;
    model.assignModel(local);
    expect(model.draft, original);
    model.manifest = project.copyWith(
      resourceLibraryCatalog: ResourceLibraryCatalog(
        entries: [
          ...project.resourceLibraryCatalog.entries,
          ResourceLibraryEntry(
            resourceKind: 'smartTilePreset',
            resourceId: 'grass',
            familyId: 'vegetation',
            mapId: 'a',
          ),
        ],
      ),
    );
    model.assignModel(local);
    expect(
      (model.partFor(0)!.source as SmartTileModel3dSource).modelId,
      'local',
    );
    final scoped = model.draft;
    model.assignModel(other);
    expect(model.draft, scoped);
    expect(terrainDraftCompatibilityProblem(model.manifest, scoped), isNull);
  });
}
