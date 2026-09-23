import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/map_host_fixture.dart';
import '../support/ui05_narrative_fixture.dart';

const free = GridPos(x: 3, y: 12);

void main() {
  MapEntity placeCharacter(MapHostFixture f) {
    final project = f.maps.project!;
    return CharacterEditingCommands(f.document, project).place(
      project.characters.firstWhere((entry) => entry.id == 'guide'),
      free,
    );
  }

  bool present(MapHostFixture f, String id) =>
      f.document.current.entities.any((entity) => entity.id == id);

  Future<void> expectRefused(
    MapHostFixture f,
    String id,
    LogicalKeyboardKey key,
  ) async {
    final before = f.document.current;
    final steps = f.document.undoCount;
    final disk = await f.disk();
    await f.key(key);
    expect(present(f, id), isTrue, reason: '${key.keyLabel} kept the target');
    expect(f.document.current, before);
    expect(f.document.undoCount, steps, reason: 'no history entry');
    expect(f.document.error, contains('brouillon'));
    expect(await f.disk(), disk, reason: 'a refusal publishes nothing');
  }

  testWidgets(
    'the Delete keys refuse a character an unsaved world rule targets',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final world = await f.worldOwner();
      final npc = placeCharacter(f);
      final rule = world.createRule();
      world.editRule(
        rule,
        (draft) => draft.target = WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: f.document.current.id,
          entityId: npc.id,
        ),
      );
      await f.tapCell(free.x, free.y);

      await expectRefused(f, npc.id, LogicalKeyboardKey.delete);
      await expectRefused(f, npc.id, LogicalKeyboardKey.backspace);
      expect(world.pendingRules.keys, contains(rule));
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a configured event that is not saved yet protects its character',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final events = await f.eventOwner();
      final npc = placeCharacter(f);
      final id = Ui05NarrativeFixture.eventId(2);
      expect(
        events.setSource(
          id,
          NarrativeEventSourceRef.entityInteract(f.document.current.id, npc.id),
        ),
        isTrue,
        reason: events.error,
      );
      expect(events.isDirty(id), isTrue);
      expect(
        events.record(id)!.definitionOrNull,
        isNotNull,
        reason: 'the record is configured, its source lives in the definition',
      );
      await f.tapCell(free.x, free.y);

      await expectRefused(f, npc.id, LogicalKeyboardKey.delete);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a rule on a twin id elsewhere blocks nothing, and the deletion undoes',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final world = await f.worldOwner();
      final npc = placeCharacter(f);
      final other = f.maps.project!.maps
          .firstWhere((entry) => entry.id != f.document.current.id)
          .id;
      final rule = world.createRule();
      world.editRule(
        rule,
        (draft) => draft.target = WorldRuleTarget(
          kind: WorldRuleTargetKind.mapEntity,
          mapId: other,
          entityId: npc.id,
        ),
      );
      await f.tapCell(free.x, free.y);
      final steps = f.document.undoCount;

      await f.key(LogicalKeyboardKey.delete);
      expect(present(f, npc.id), isFalse, reason: f.document.error);
      expect(f.document.undoCount, steps + 1);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
      await f.key(LogicalKeyboardKey.keyZ);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
      expect(present(f, npc.id), isTrue, reason: 'the removal is undoable');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'Delete never acts behind an open context menu',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final npc = placeCharacter(f);
      await f.rightClick(free.x, free.y);
      expect(f.menu, findsOneWidget);
      final steps = f.document.undoCount;

      await f.key(LogicalKeyboardKey.delete);
      await f.key(LogicalKeyboardKey.backspace);

      expect(present(f, npc.id), isTrue);
      expect(f.document.undoCount, steps);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'a story zone whose interaction is being written refuses both paths',
    (tester) async {
      final f = await MapHostFixture.open(tester);
      final narrative = await f.narrativeOwner();
      await tester.tap(find.byTooltip('Dessiner une zone d’histoire'));
      await pumpIo(tester, frames: 4);
      await f.drag(3, 11, 5, 13);
      await pumpIo(tester, frames: 12);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom de l’interaction'),
        'Brume sur le quai',
      );
      await pumpIo(tester, frames: 4);
      expect(narrative.active!.dirty, isTrue);
      await tester.tap(find.text('Retour à la carte'));
      await pumpIo(tester, frames: 10);
      final zone = narrative.active!.current.interaction.source
          .toJson()['triggerId'];

      await f.rightClick(4, 12);
      final remove = tester.widget<TextButton>(
        find.ancestor(
          of: f.inMenu('Supprimer la zone'),
          matching: find.byType(TextButton),
        ),
      );
      expect(remove.onPressed, isNull, reason: 'the menu blocks it');
      await f.key(LogicalKeyboardKey.escape);

      final steps = f.document.undoCount;
      await f.key(LogicalKeyboardKey.delete);
      expect(
        f.document.current.triggers.map((trigger) => trigger.id),
        contains(zone),
        reason: 'the keyboard blocks it too',
      );
      expect(f.document.undoCount, steps);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  testWidgets(
    'every family the menu deletes, the keyboard deletes and undoes',
    (tester) async {
      final f = await MapHostFixture.open(tester);
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
      await pumpIo(tester, frames: 4);
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
