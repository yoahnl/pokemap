import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const herbs = ProjectEncounterTable(
  id: 'herbs',
  name: 'Hautes herbes',
  encounterKind: EncounterKind.walk,
);

const area = MapRect(
  pos: GridPos(x: 2, y: 2),
  size: GridSize(width: 4, height: 3),
);

void main() {
  late EditableMapDocument document;
  late GameplayZoneEditingCommands commands;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    commands = GameplayZoneEditingCommands(
      document,
      workspaceProject.copyWith(encounterTables: [herbs]),
    );
  });

  test('a drawn zone keeps the rectangle and gets its own payload', () {
    final zone = commands.place(GameplayZoneKind.encounter, area);
    expect(zone.area, area);
    expect(zone.encounter, isNotNull);
    expect(zone.movement, isNull, reason: 'one kind, one payload');
    expect(commands.at(const GridPos(x: 3, y: 3)).single.id, zone.id);
    expect(
      commands.at(const GridPos(x: 9, y: 9)),
      isEmpty,
      reason: 'outside the rectangle the zone does not answer',
    );
  });

  test('an encounter zone without a table says so instead of pretending', () {
    final zone = commands.place(GameplayZoneKind.encounter, area);
    expect(
      commands.coverageProblem(commands.selected(zone.id)!),
      contains('ne déclenche rien'),
    );

    commands.updateEncounter(zone.id, tableId: herbs.id);
    expect(commands.coverageProblem(commands.selected(zone.id)!), isNull);
    expect(commands.tableOf(commands.selected(zone.id)!)!.name, 'Hautes herbes');

    final orphaned = GameplayZoneEditingCommands(document, workspaceProject);
    expect(
      orphaned.coverageProblem(orphaned.selected(zone.id)!),
      contains('n’existe plus'),
      reason: 'a table removed from the project is named, not hidden',
    );
  });

  test('changing the kind moves the payload with it', () {
    final zone = commands.place(GameplayZoneKind.encounter, area);
    commands.updateEncounter(zone.id, tableId: herbs.id);
    commands.retype(zone.id, GameplayZoneKind.hazard);

    final changed = commands.selected(zone.id)!;
    expect(changed.kind, GameplayZoneKind.hazard);
    expect(changed.hazard, isNotNull);
    expect(
      changed.encounter,
      isNull,
      reason: 'the old payload does not linger behind the new kind',
    );
    expect(
      changed.name,
      'Zone dangereuse',
      reason: 'an untouched default name follows the kind',
    );

    commands.rename(zone.id, 'Marais du quai');
    commands.retype(zone.id, GameplayZoneKind.movement);
    expect(
      commands.selected(zone.id)!.name,
      'Marais du quai',
      reason: 'a name the author wrote is never overwritten',
    );
  });

  test('each kind exposes its own properties', () {
    final hazard = commands.place(GameplayZoneKind.hazard, area);
    commands.updateHazard(hazard.id, damagePerStep: 3);
    expect(commands.selected(hazard.id)!.hazard!.damagePerStep, 3);

    final effect = commands.place(
      GameplayZoneKind.movementEffect,
      const MapRect(
        pos: GridPos(x: 8, y: 8),
        size: GridSize(width: 2, height: 2),
      ),
    );
    commands.updateMovementEffect(effect.id, movementCost: 2);
    expect(commands.selected(effect.id)!.movementEffect!.movementCost, 2);
    expect(
      commands.selected(hazard.id)!.hazard!.damagePerStep,
      3,
      reason: 'editing one zone leaves the other alone',
    );
  });

  test('zones move, resize, overlap by priority and undo step by step', () {
    final zone = commands.place(GameplayZoneKind.encounter, area);
    final second = commands.place(
      GameplayZoneKind.hazard,
      const MapRect(
        pos: GridPos(x: 3, y: 3),
        size: GridSize(width: 2, height: 2),
      ),
    );
    commands.setPriority(second.id, 5);
    expect(
      commands.at(const GridPos(x: 3, y: 3)).map((z) => z.id),
      containsAll([zone.id, second.id]),
      reason: 'overlapping zones are all reported, not silently merged',
    );

    commands.move(zone.id, const GridPos(x: 10, y: 5));
    expect(commands.selected(zone.id)!.area.pos, const GridPos(x: 10, y: 5));
    commands.resize(zone.id, const GridSize(width: 2, height: 2));
    expect(
      commands.selected(zone.id)!.area.size,
      const GridSize(width: 2, height: 2),
    );
    commands.delete(second.id);
    expect(document.current.gameplayZones, hasLength(1));

    document.restore(redo: false);
    expect(document.current.gameplayZones, hasLength(2));
    document.restore(redo: false);
    expect(
      commands.selected(zone.id)!.area.size,
      const GridSize(width: 4, height: 3),
    );
  });

  test('a zone never touches the tiles or the other families', () {
    final layers = document.current.layers;
    commands.place(GameplayZoneKind.movement, area);
    expect(document.current.layers, layers);
    expect(document.current.entities, isEmpty);
    expect(document.current.placedElements, isEmpty);
    expect(document.current.triggers, isEmpty);
  });
}
