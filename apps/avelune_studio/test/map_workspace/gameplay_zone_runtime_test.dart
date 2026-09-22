import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late GameplayZoneEditingCommands zones;

  GameplayWorldState world() =>
      GameplayWorldState.fromMap(document.current, project: workspaceProject);

  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    MapEntityEditingCommands(
      document,
      workspaceProject,
    ).place(MapEntityKind.spawn, const GridPos(x: 4, y: 4));
    zones = GameplayZoneEditingCommands(document, workspaceProject);
  });

  test('a hazard zone drawn in Studio really hurts the player', () {
    final zone = zones.place(
      GameplayZoneKind.hazard,
      const MapRect(
        pos: GridPos(x: 4, y: 5),
        size: GridSize(width: 3, height: 3),
      ),
    );
    zones.updateHazard(zone.id, damagePerStep: 2);

    var result = stepGameplayWorld(world(), const MoveIntent(Direction.south));
    while (result is Moved && result.hazardEffect == null) {
      final next = stepGameplayWorld(
        result.world,
        const MoveIntent(Direction.south),
      );
      if (next is! Moved || next.world.player.pos == result.world.player.pos) {
        break;
      }
      result = next;
    }

    expect(result, isA<Moved>());
    final effect = (result as Moved).hazardEffect;
    expect(
      effect,
      isNotNull,
      reason: 'walking into the rectangle the author drew triggers the hazard',
    );
    expect(effect!.zoneId, zone.id);
    expect(effect.damagePerStep, 2);
    expect(effect.zoneName, 'Zone dangereuse');
  });

  test('a hazard without damage stays inert instead of half working', () {
    final zone = zones.place(
      GameplayZoneKind.hazard,
      const MapRect(
        pos: GridPos(x: 4, y: 5),
        size: GridSize(width: 3, height: 3),
      ),
    );
    expect(zones.selected(zone.id)!.hazard!.damagePerStep, 0);

    var result = stepGameplayWorld(world(), const MoveIntent(Direction.south));
    for (var i = 0; i < 6 && result is Moved; i++) {
      expect(
        result.hazardEffect,
        isNull,
        reason: 'zero damage per step means nothing happens, not a crash',
      );
      result = stepGameplayWorld(
        result.world,
        const MoveIntent(Direction.south),
      );
    }
  });

  test('the priority the author set decides which zone wins', () {
    final mild = zones.place(
      GameplayZoneKind.hazard,
      const MapRect(
        pos: GridPos(x: 3, y: 5),
        size: GridSize(width: 5, height: 4),
      ),
    );
    zones.updateHazard(mild.id, damagePerStep: 1);
    final severe = zones.place(
      GameplayZoneKind.hazard,
      const MapRect(
        pos: GridPos(x: 4, y: 5),
        size: GridSize(width: 2, height: 2),
      ),
    );
    zones.updateHazard(severe.id, damagePerStep: 3);
    zones.setPriority(severe.id, 2);

    var result = stepGameplayWorld(world(), const MoveIntent(Direction.south));
    while (result is Moved && result.hazardEffect == null) {
      final next = stepGameplayWorld(
        result.world,
        const MoveIntent(Direction.south),
      );
      if (next is! Moved || next.world.player.pos == result.world.player.pos) {
        break;
      }
      result = next;
    }

    final effect = (result as Moved).hazardEffect;
    expect(effect, isNotNull);
    expect(
      effect!.zoneId,
      severe.id,
      reason: 'the higher priority zone is the one the engine applies',
    );
    expect(effect.damagePerStep, 3);
  });
}
