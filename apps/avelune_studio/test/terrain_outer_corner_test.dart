import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'terrain_creation_test.dart' show terrainDraft;

void main() {
  test('outer corner uses its own source and survives a published draft', () {
    final controller = terrainDraft();
    controller.selectedRule = 16;
    controller.assign(2, 1);
    expect(controller.draft.topology, SmartTileTopology.blob8);
    expect(controller.draft.rules, hasLength(20));
    expect(controller.frameFor(16)?.column, 2);
    expect(
      terrainDraftCompatibilityProblem(controller.manifest, controller.draft),
      isNull,
    );
    final reopened = TerrainDraftController.resume(
      manifest: controller.manifest,
      draft: ProjectSmartTileAuthoringDraft.fromJson(controller.draft.toJson()),
    );
    expect(reopened.frameFor(16)?.column, 2);
    reopened.clearScratch();
    for (var y = 5; y <= 7; y++) {
      for (var x = 5; x <= 7; x++) {
        if (x != 5 || y != 5) reopened.paint(GridPos(x: x, y: y));
      }
    }
    reopened.inspect(const GridPos(x: 6, y: 6));
    expect(reopened.selectedRule, 16);
    expect(
      reopened.resolved[6 + 6 * TerrainDraftController.scratchSize].ruleId,
      'connection-16',
    );
  });
}
