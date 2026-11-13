import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/neutral_map_host_fixture.dart';


const free = GridPos(x: 3, y: 12);

void main() {
  MapEntity placeCharacter(NeutralMapHostFixture f) {
    final project = f.maps.project!;
    return CharacterEditingCommands(f.document, project).place(
      project.characters.firstWhere((entry) => entry.id == 'guide'),
      free,
    );
  }

  bool present(NeutralMapHostFixture f, String id) =>
      f.document.current.entities.any((entity) => entity.id == id);

  testWidgets('Delete never acts behind an open context menu', (tester) async {
    final f = await NeutralMapHostFixture.open(tester);
    final npc = placeCharacter(f);
    await f.rightClick(free.x, free.y);
    expect(f.input.contextOpen, isTrue);
    final steps = f.document.undoCount;

    await f.key(LogicalKeyboardKey.delete);
    await f.key(LogicalKeyboardKey.backspace);

    expect(present(f, npc.id), isTrue);
    expect(f.document.undoCount, steps);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets(
    'every family the menu deletes, the keyboard deletes and undoes',
    (tester) async {
      final f = await NeutralMapHostFixture.open(tester);
      final project = f.maps.project!;
      final sign = MapEntityEditingCommands(
        f.document,
        project,
      ).place(MapEntityKind.sign, const GridPos(x: 2, y: 2));
      final warp = WarpEditingCommands(f.document, project).place(
        project.maps.firstWhere((entry) => entry.id != f.document.current.id),
        const GridPos(x: 4, y: 2),
      );
      final zone = GameplayZoneEditingCommands(f.document, project).place(
        GameplayZoneKind.encounter,
        const MapRect(
          pos: GridPos(x: 16, y: 2),
          size: GridSize(width: 2, height: 2),
        ),
      );
      await f.pump(frames: 4);
      final cases = <(String, GridPos, bool Function())>[
        (
          'sign',
          sign.pos,
          () => f.document.current.entities.any((item) => item.id == sign.id),
        ),
        (
          'warp',
          warp.pos,
          () => f.document.current.warps.any((item) => item.id == warp.id),
        ),
        (
          'zone',
          zone.area.pos,
          () => f.document.current.gameplayZones.any(
            (item) => item.id == zone.id,
          ),
        ),
      ];
      for (final (name, at, present) in cases) {
        await f.rightClick(at.x, at.y);
        await f.key(LogicalKeyboardKey.escape);
        await f.key(LogicalKeyboardKey.backspace);
        expect(present(), isFalse, reason: '$name: ${f.document.error}');
        await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
        await f.key(LogicalKeyboardKey.keyZ);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
        expect(present(), isTrue, reason: '$name comes back with undo');
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
