import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_warp_drafts.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  const warp = MapWarp(
    id: 'stairs',
    pos: GridPos(x: 1, y: 1),
    targetMapId: 'upper',
    targetPos: GridPos(x: 2, y: 2),
  );
  test('ladder updates only its warp through canonical command and undo', () {
    final map = MapData(
      id: 'lower',
      name: 'Lower',
      version: ProjectVersion.v9,
      size: const GridSize(width: 4, height: 4),
      spatialScene: MapSpatialScene(width: 4, depth: 4),
      warps: [warp],
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: map.id),
    );
    final commands = WarpEditingCommands(
      document,
      const ProjectManifest(name: 'Climb', maps: [], tilesets: []),
    );
    final draft = MapWarpLadderDraft(warp);
    expect(draft.value, isNull);
    draft.mode = 'up';
    expect(draft.invalid, isFalse);
    commands.configureLadder(warp.id, draft.value);
    expect(
      document.current.warps.single,
      warp.copyWith(ladder: MapWarpLadder()),
    );
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, map);
    commands.configureLadder(
      warp.id,
      MapWarpLadder(direction: MapWarpLadderDirection.down),
    );
    commands.retarget(warp.id, triggerMode: MapWarpTriggerMode.sceneOnly);
    expect(document.current.warps.single.ladder, isNull);
  });

  test(
    'ladder keeps precise untouched duration and refuses invalid values',
    () {
      final precise = MapWarpLadder(durationSeconds: .0254);
      final draft = MapWarpLadderDraft(warp.copyWith(ladder: precise));
      expect(draft.duration, '25');
      expect(draft.value, precise);
      draft.durationTouched = true;
      draft.duration = '350';
      expect(draft.value!.durationSeconds, .35);
      for (final value in ['0', '10001', 'NaN', 'text']) {
        draft.duration = value;
        expect(draft.invalid, isTrue);
      }
      draft.duration = '350';
      for (final value in ['0', '17', 'NaN', 'text']) {
        draft.height = value;
        expect(draft.invalid, isTrue);
      }
      draft.reset(warp);
      expect(draft.value, isNull);
      expect(draft.durationTouched, isFalse);
    },
  );
}
