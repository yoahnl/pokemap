import 'dart:async';

import 'package:avelune_studio/features/terrains/application/terrain_scratch_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'terrain_creation_test.dart'
    show terrainDraft, assignAll, publishFixture;

void main() {
  test('source assignment scratch inspection and publication retain the saved preset', () async {
    final model = terrainDraft();
    assignAll(model);
    model.selectedRule = 3;
    model.assignSelectedFrame(const TilesetSourceRect(x: 0, y: 0));
    expect(model.frameFor(3)!.column, 0);
    expect(model.frameFor(3)!.row, 0);
    final scratch = TerrainScratchEditingSession(() => model);
    scratch.update(const GridPos(x: 14, y: 14), TerrainScratchTool.inspect);
    scratch.end();
    expect(model.selectedRule, 15);
    final gate = Completer<void>();
    final actions = <String>[];
    final pending = model.save((action, parameters) async {
      actions.add(action);
      if (action.endsWith('upsert')) await gate.future;
      return publishFixture(model);
    }, publish: true);
    expect(model.busy, isTrue);
    expect(model.publishedPreset, isNull);
    expect(
      await model.save((_, _) async => model.manifest, publish: true),
      isFalse,
    );
    gate.complete();
    expect(await pending, isTrue);
    expect(actions, [
      'smart_tile.preset.draft.upsert',
      'smart_tile.preset.publish',
    ]);
    expect(model.publishedPreset!.id, model.draft.targetPresetId);
  });

  test('source assignment advances only from an unassigned selected rule', () {
    final model = terrainDraft();
    model.selectedRule = 3;
    model.assignSelectedFrame(
      const TilesetSourceRect(x: 0, y: 0),
      advanceMissing: true,
    );
    expect(model.frameFor(3), isNotNull);
    expect(model.selectedRule, 4);
    model.selectedRule = 3;
    model.assignSelectedFrame(
      const TilesetSourceRect(x: 1, y: 0),
      advanceMissing: true,
    );
    expect(model.selectedRule, 3);
    model.selectedRule = 5;
    model.assignSelectedFrame(const TilesetSourceRect(x: 0, y: 0));
    expect(model.selectedRule, 5);
  });

  test('outer corner assignment expands topology with one-step undo', () {
    final model = terrainDraft();
    model.selectedRule = 16;
    model.assignSelectedFrame(const TilesetSourceRect(x: 0, y: 0));
    expect(model.draft.rules, hasLength(20));
    expect(model.frameFor(16), isNotNull);
    model.undo();
    expect(model.draft.rules, hasLength(16));
    expect(model.frameFor(16), isNull);
  });
}
