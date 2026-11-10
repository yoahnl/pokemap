import 'package:avelune_studio/features/terrains/application/terrain_scratch_editing_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'spatial_terrain_draft_test.dart' show spatialPathDraft;

void main() {
  test(
    'scratch strokes interpolate while active and never bridge ended gestures',
    () {
      final model = spatialPathDraft()..clearScratch();
      final session = TerrainScratchEditingSession(() => model);
      session.begin(const GridPos(x: 2, y: 4), TerrainScratchTool.paint);
      session.update(const GridPos(x: 5, y: 4), TerrainScratchTool.paint);
      expect(model.scratch, {for (var x = 2; x <= 5; x++) GridPos(x: x, y: 4)});
      session.end();
      session.cell(const GridPos(x: 10, y: 4), TerrainScratchTool.paint);
      expect(model.scratch.length, 5);
      expect(model.scratch, contains(const GridPos(x: 10, y: 4)));
      expect(model.scratch, isNot(contains(const GridPos(x: 6, y: 4))));
    },
  );

  test(
    'scratch inspection is read only and erase removes only its chosen cells',
    () {
      final model = spatialPathDraft()..clearScratch();
      final session = TerrainScratchEditingSession(() => model);
      session.begin(const GridPos(x: 2, y: 4), TerrainScratchTool.paint);
      session.update(const GridPos(x: 5, y: 4), TerrainScratchTool.paint);
      session.end();
      final before = {...model.scratch};
      final draft = model.draft;
      session.cell(const GridPos(x: 2, y: 4), TerrainScratchTool.inspect);
      expect(model.scratch, before);
      expect(model.draft, draft);
      session.cell(const GridPos(x: 3, y: 4), TerrainScratchTool.erase);
      expect(model.scratch, before..remove(const GridPos(x: 3, y: 4)));
      expect(model.draft, draft);
    },
  );
}
