import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/events/application/event_workspace_controller.dart';
import 'package:avelune_studio/features/world/application/world_workspace_controller.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

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
}
