import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_warp_target_session.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';

const zoneArea = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 4),
);

void main() {
  late MapSelectionOwnerHarness h;
  setUp(() => h = MapSelectionOwnerHarness.of(workspaceProject));
  tearDown(() => h.dispose());

  test('undo restores the previous sign title without a new history entry', () {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    commands.updateSign(sign.id, title: 'Quai numéro 3');
    commands.updateSign(sign.id, title: 'Quai revu');
    expect(commands.selected(sign.id)!.sign!.title, 'Quai revu');
    final steps = h.document.undoCount;
    h.document.restore(redo: false);
    expect(commands.selected(sign.id)!.sign!.title, 'Quai numéro 3');
    expect(h.document.undoCount, steps - 1);
    expect(h.document.canRedo, isTrue);
  });

  test('undo restores the previous gameplay zone name', () {
    final commands = GameplayZoneEditingCommands(h.document, h.project);
    final zone = commands.place(GameplayZoneKind.encounter, zoneArea);
    commands.rename(zone.id, 'Herbes du quai');
    expect(commands.selected(zone.id)!.name, 'Herbes du quai');
    h.document.restore(redo: false);
    expect(commands.selected(zone.id)!.name, 'Zone de rencontres');
  });

  test('redo restores the changed sign title', () {
    final commands = MapEntityEditingCommands(h.document, h.project);
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 4, y: 4));
    commands.updateSign(sign.id, title: 'Quai revu');
    h.document.restore(redo: false);
    h.document.restore(redo: true);
    expect(commands.selected(sign.id)!.sign!.title, 'Quai revu');
  });

  test(
    'a sign edit targets its captured identity and preserves the other sign',
    () {
      final commands = MapEntityEditingCommands(h.document, h.project);
      final first = commands.place(
        MapEntityKind.sign,
        const GridPos(x: 4, y: 4),
      );
      final second = commands.place(
        MapEntityKind.sign,
        const GridPos(x: 9, y: 2),
      );
      commands.updateSign(first.id, title: 'Premier');
      commands.updateSign(second.id, title: 'Second');
      commands.updateSign(first.id, title: 'Saisie du premier');
      expect(commands.selected(first.id)!.sign!.title, 'Saisie du premier');
      expect(commands.selected(second.id)!.sign!.title, 'Second');
    },
  );

  test('an invalid arrival coordinate preserves the target and valid input remains possible', () {
    final commands = WarpEditingCommands(h.document, h.project);
    final warp = commands.place(
      workspaceEntries.firstWhere((entry) => entry.id == 'b'),
      const GridPos(x: 3, y: 3),
    );
    commands.retarget(warp.id, targetPos: const GridPos(x: 5, y: 2));
    final session = MapWarpTargetSession(
      h.document,
      h.project,
      commands.selected(warp.id)!,
    );
    addTearDown(session.dispose);
    final before = h.document.current;
    expect(session.commitTarget('abc', horizontal: true), isFalse);
    expect(h.document.current, same(before));
    expect(h.document.error, contains('nombres positifs'));
    expect(session.commitTarget('7', horizontal: true), isTrue);
    expect(commands.selected(warp.id)!.targetPos, const GridPos(x: 7, y: 2));
  });
}
