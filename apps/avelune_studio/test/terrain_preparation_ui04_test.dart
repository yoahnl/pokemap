import 'package:avelune_studio/features/terrains/application/terrain_draft_controller.dart';
import 'package:avelune_studio/features/terrains/domain/terrain_draft_compatibility.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  test(
    'recognized structure does not overwrite an unrecognized pending guide',
    () {
      final controller = terrainDraft();
      assignAll(controller);
      final manifest = publishFixture(controller);
      final preset = manifest.smartTileCatalog.presets.single;
      final draft = terrainDraftForPreset(manifest, preset)!;
      final unsupported = draft.copyWith(guideId: 'advanced-guide');
      expect(
        recognizeSmartTileAuthoringGuide(manifest, unsupported),
        'avelune-cardinal4-v1',
      );
      expect(
        terrainDraftCompatibilityProblem(manifest, unsupported),
        advancedTerrainPreparationMessage,
      );
      expect(
        editableTerrainDraft(manifest, preset, localDrafts: [unsupported]),
        isNull,
      );
      expect(unsupported.guideId, 'advanced-guide');
      expect(terrainDraftCompatibilityProblem(manifest, draft), isNull);
    },
  );

  test('examining missing contexts selects every cardinal configuration', () {
    final controller = terrainDraft();
    for (var mask = 0; mask < 16; mask++) {
      controller.inspect(GridPos(x: 2 + mask % 4 * 4, y: 2 + mask ~/ 4 * 4));
      expect(controller.selectedRule, mask);
      expect(controller.frameFor(mask), isNull);
    }
    controller.inspect(const GridPos(x: -1, y: 99));
    expect(controller.selectedRule, 15);
    expect(controller.canUndo, isFalse);
  });

  test('assignment removal undo redo are local and history is bounded', () {
    final controller = terrainDraft();
    controller.assign(2, 1);
    final assigned = controller.draft;
    controller.removeAssignment();
    expect(controller.assignedCount, 0);
    controller.undo();
    expect(controller.draft, assigned);
    controller.redo();
    expect(controller.frameFor(0), isNull);
    controller.undo();
    controller.assign(3, 2);
    expect(controller.canRedo, isFalse);
    expect(controller.frameFor(0)!.column, 3);
    for (var i = 0; i < TerrainDraftController.historyLimit + 10; i++) {
      controller.rename('Terrain $i');
    }
    var count = 0;
    while (controller.canUndo) {
      controller.undo();
      count++;
    }
    expect(count, TerrainDraftController.historyLimit);
  });

  test('continuous scratch strokes and clear do not alter associations', () {
    final controller = terrainDraft();
    assignAll(controller);
    final associations = controller.draft;
    controller.clearScratch();
    controller.paintLine(const GridPos(x: 2, y: 2), const GridPos(x: 8, y: 2));
    controller.paintLine(const GridPos(x: 8, y: 2), const GridPos(x: 8, y: 6));
    controller.paintLine(const GridPos(x: 5, y: 2), const GridPos(x: 5, y: 6));
    controller.inspect(const GridPos(x: 8, y: 2));
    expect(controller.selectedRule, 12);
    controller.inspect(const GridPos(x: 5, y: 2));
    expect(controller.selectedRule, 14);
    expect(controller.scratch, hasLength(15));
    controller.paintLine(
      const GridPos(x: 2, y: 2),
      const GridPos(x: 8, y: 2),
      erase: true,
    );
    expect(controller.scratch, hasLength(8));
    controller.clearScratch();
    expect(controller.resolved.every((r) => r.ruleId == null), isTrue);
    expect(controller.draft, associations);
    expect(controller.canUndo, isTrue);
  });
}
