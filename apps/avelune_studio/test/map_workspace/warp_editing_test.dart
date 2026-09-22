import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const guide = ProjectCharacterEntry(
  id: 'guide',
  name: 'Chef de gare',
  tilesetId: 'atlas',
);

ProjectMapEntry get garden =>
    workspaceEntries.firstWhere((entry) => entry.id == 'b');

void main() {
  late EditableMapDocument document;
  late ProjectManifest project;
  late WarpEditingCommands commands;
  setUp(() {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a'),
        revision: 'base',
        mapId: 'a',
      ),
    );
    project = workspaceProject.copyWith(characters: [guide]);
    commands = WarpEditingCommands(document, project);
  });

  test('a placed warp keeps the destination that was chosen', () {
    final warp = commands.place(garden, const GridPos(x: 3, y: 4));
    expect(warp.targetMapId, 'b');
    expect(warp.pos, const GridPos(x: 3, y: 4));
    expect(document.current.warps, hasLength(1));
    expect(
      commands.destinationOf(warp)!.name,
      'Jardin',
      reason: 'the destination resolves to a real map of the project',
    );
    expect(commands.destinationProblem(warp), isNull);
    expect(
      document.current.layers,
      workspaceMap('a').layers,
      reason: 'placing a warp never rewrites the tiles',
    );
  });

  test('only the project maps are offered as destinations', () {
    expect(
      commands.destinations().map((entry) => entry.id),
      ['b'],
      reason: 'a map never proposes itself as its own destination',
    );
    expect(
      () => commands.place(
        const ProjectMapEntry(
          id: 'ghost',
          name: 'Carte fantôme',
          relativePath: 'ghost.json',
        ),
        const GridPos(x: 1, y: 1),
      ),
      throwsStateError,
      reason: 'a destination outside the project is refused at placement',
    );
    expect(document.current.warps, isEmpty);
  });

  test('a destination removed from the project is named, not hidden', () {
    final warp = commands.place(garden, const GridPos(x: 2, y: 2));
    final orphaned = WarpEditingCommands(
      document,
      workspaceProject.copyWith(
        maps: [workspaceEntries.first],
      ),
    );
    expect(orphaned.destinationOf(warp), isNull);
    expect(
      orphaned.destinationProblem(warp),
      contains('n’existe plus'),
      reason: 'the author is told instead of seeing a silent broken link',
    );
  });

  test('moving a warp leaves the other families untouched', () {
    final decors = MapEditingCommands(document, project);
    final characters = CharacterEditingCommands(document, project);
    decors.place(workspaceElement, const GridPos(x: 8, y: 8));
    final npc = characters.place(guide, const GridPos(x: 6, y: 6));
    final warp = commands.place(garden, const GridPos(x: 2, y: 2));
    final decorsBefore = document.current.placedElements;
    final entitiesBefore = document.current.entities;

    commands.move(warp.id, const GridPos(x: 9, y: 1));

    expect(commands.selected(warp.id)!.pos, const GridPos(x: 9, y: 1));
    expect(document.current.placedElements, decorsBefore);
    expect(document.current.entities, entitiesBefore);
    expect(characters.selected(npc.id), isNotNull);
  });

  test('retargeting goes through the shared validation', () {
    final warp = commands.place(garden, const GridPos(x: 1, y: 1));
    commands.retarget(
      warp.id,
      targetPos: const GridPos(x: 5, y: 7),
      triggerMode: MapWarpTriggerMode.onBump,
    );
    final updated = commands.selected(warp.id)!;
    expect(updated.targetPos, const GridPos(x: 5, y: 7));
    expect(updated.triggerMode, MapWarpTriggerMode.onBump);
    expect(
      () => commands.retarget(warp.id, targetMapId: 'ghost'),
      throwsStateError,
      reason: 'a destination outside the project never reaches the map',
    );
    expect(commands.selected(warp.id)!.targetMapId, 'b');
    expect(
      () => commands.move(warp.id, const GridPos(x: 99, y: 99)),
      throwsA(isA<ValidationException>()),
      reason: 'map_core keeps the warp inside the map bounds',
    );
  });

  test('placement, move and deletion are undoable step by step', () {
    final warp = commands.place(garden, const GridPos(x: 4, y: 4));
    commands.move(warp.id, const GridPos(x: 5, y: 4));
    commands.delete(warp.id);
    expect(document.current.warps, isEmpty);

    document.restore(redo: false);
    expect(document.current.warps.single.pos, const GridPos(x: 5, y: 4));
    document.restore(redo: false);
    expect(document.current.warps.single.pos, const GridPos(x: 4, y: 4));
    document.restore(redo: false);
    expect(document.current.warps, isEmpty);

    document.restore(redo: true);
    expect(document.current.warps.single.targetMapId, 'b');
    expect(document.dirty, isTrue);
  });
}
