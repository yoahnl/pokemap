import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../application/spatial_terrain_draft_test.dart';

void main() {

  test('terrain animation choices preserve the selected model transform', () {
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
    final draft = TerrainDraftController.resume(
      manifest: base.manifest.copyWith(models3d: [animated]),
      draft: base.draft,
    );
    draft.assignModel(
      animated,
      scale: 1.5,
      offsetX: .25,
      offsetY: .5,
      offsetZ: .75,
      quarterTurns: 1,
    );
    final previous = draft.partFor(0)!;
    expect(draft.setSelectedModelAnimation(0), isTrue);
    final animatedPart = draft.partFor(0)!;
    final source = animatedPart.source as SmartTileModel3dSource;
    expect(source.animationIndex, 0);
    expect(source.scale, 1.5);
    expect(source.offsetX, .25);
    expect(source.offsetY, .5);
    expect(source.offsetZ, .75);
    expect(animatedPart.transform, previous.transform);
    expect(draft.setSelectedModelAnimation(null), isTrue);
    expect(
      (draft.partFor(0)!.source as SmartTileModel3dSource).animationIndex,
      isNull,
    );
    expect(base.manifest.models3d.single.inspection.animations, isEmpty);
  });
}
