import 'dart:convert';
import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'spatial_terrain_draft_fixtures.dart';
export 'spatial_terrain_draft_fixtures.dart';

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

  test('unit models compile without an atlas and keep their draft through JSON', () {
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
}
