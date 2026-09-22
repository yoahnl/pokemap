import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late MapEntityEditingCommands commands;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    commands = MapEntityEditingCommands(document, workspaceProject);
  });

  test('a map without a player start cannot be played at all', () {
    expect(
      () => GameplayWorldState.fromMap(
        document.current,
        project: workspaceProject,
      ),
      throwsA(isA<GameplaySpawnResolutionException>()),
      reason: 'this is why the spawn family matters more than it looks',
    );

    final spawn = commands.place(
      MapEntityKind.spawn,
      const GridPos(x: 4, y: 6),
    );
    final world = GameplayWorldState.fromMap(
      document.current,
      project: workspaceProject,
    );
    expect(
      world.player.pos,
      const GridPos(x: 4, y: 6),
      reason: 'the engine starts the player where the author clicked',
    );
    expect(commands.playerStart()!.id, spawn.id);
  });

  test('the player start follows the author when it is moved', () {
    commands.place(MapEntityKind.spawn, const GridPos(x: 2, y: 2));
    commands.move(commands.playerStart()!.id, const GridPos(x: 9, y: 3));
    final world = GameplayWorldState.fromMap(
      document.current,
      project: workspaceProject,
    );
    expect(world.player.pos, const GridPos(x: 9, y: 3));
  });

  test('a spawn placed for something else is not a player start', () {
    final spawn = commands.place(
      MapEntityKind.spawn,
      const GridPos(x: 1, y: 1),
    );
    commands.updateSpawn(spawn.id, role: EntitySpawnRole.npcSpawn);
    expect(commands.playerStart(), isNull);
    expect(
      () => GameplayWorldState.fromMap(
        document.current,
        project: workspaceProject,
      ),
      throwsA(isA<GameplaySpawnResolutionException>()),
      reason: 'the role is read, not assumed from the family',
    );
  });

  test('a sign carries its own text and blocks the way', () {
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 5, y: 5));
    expect(sign.blocksMovement, isTrue);
    commands.updateSign(
      sign.id,
      title: 'Quai numéro 3',
      plainText: 'Le train de 17h42 part d’ici.',
    );
    final updated = commands.selected(sign.id)!;
    expect(updated.sign!.title, 'Quai numéro 3');
    expect(updated.sign!.plainText, 'Le train de 17h42 part d’ici.');
    expect(
      updated.name,
      'Quai numéro 3',
      reason: 'the name follows the title so the map stays readable',
    );
  });

  test('these families never answer for a character', () {
    final sign = commands.place(MapEntityKind.sign, const GridPos(x: 3, y: 3));
    expect(commands.at(const GridPos(x: 3, y: 3)).single.id, sign.id);
    expect(
      () => commands.place(MapEntityKind.npc, const GridPos(x: 0, y: 0)),
      throwsStateError,
      reason: 'a character keeps its own catalogue-backed command',
    );
  });

  test('placing, editing and deleting are undoable step by step', () {
    final spawn = commands.place(
      MapEntityKind.spawn,
      const GridPos(x: 7, y: 7),
    );
    commands.updateSpawn(spawn.id, facing: EntityFacing.north);
    commands.delete(spawn.id);
    expect(document.current.entities, isEmpty);

    document.restore(redo: false);
    expect(commands.selected(spawn.id)!.spawn!.facing, EntityFacing.north);
    document.restore(redo: false);
    expect(commands.selected(spawn.id)!.spawn!.facing, EntityFacing.south);
    document.restore(redo: false);
    expect(document.current.entities, isEmpty);
  });
}
