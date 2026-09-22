import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_command_runner.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_context_menu_model.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const twin = 'partage';
const area = MapRect(
  pos: GridPos(x: 3, y: 3),
  size: GridSize(width: 4, height: 4),
);

EditableMapDocument documentFor(String mapId) => EditableMapDocument(
  MapWorkspaceDocument(
    map: workspaceMap(mapId),
    revision: 'base',
    mapId: mapId,
  ),
);

MapContextActionContext contextAt(
  EditableMapDocument document,
  GridPos position,
) => MapContextActionContext(
  document: document,
  project: workspaceProject,
  position: position,
);

void main() {
  test('two families may share a local id without confusing the runner', () {
    final document = documentFor('a');
    // The contracts allow the same local id in two different collections.
    document.commit(
      document.current.copyWith(
        gameplayZones: [
          const MapGameplayZone(
            id: twin,
            name: 'Herbes',
            kind: GameplayZoneKind.encounter,
            area: area,
            encounter: EncounterZonePayload(),
          ),
        ],
        warps: [
          const MapWarp(
            id: twin,
            pos: GridPos(x: 4, y: 4),
            targetMapId: 'b',
            targetPos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );

    final context = contextAt(document, const GridPos(x: 4, y: 4));
    final targets = mapContextTargetsAt(
      document,
      workspaceProject,
      const GridPos(x: 4, y: 4),
    );
    final warp = targets.firstWhere(
      (item) => item.family == MapContextFamily.warp,
    );
    final zone = targets.firstWhere(
      (item) => item.family == MapContextFamily.zone,
    );
    expect(warp.id, zone.id, reason: 'the fixture really has twins');
    expect(warp.key, isNot(zone.key));
    expect(warp.sameAs(zone), isFalse);

    expect(
      MapContextCommandRunner(context).run(MapContextCommand.delete, zone),
      isNull,
    );
    expect(
      document.current.gameplayZones,
      isEmpty,
      reason: 'the zone chosen in the menu is the one removed',
    );
    expect(
      document.current.warps.single.id,
      twin,
      reason: 'its homonym in another family is untouched',
    );
  });

  test('a target from another map is refused, never substituted', () {
    final document = documentFor('a');
    MapEditingCommands(
      document,
      workspaceProject,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    final decor = document.current.placedElements.single;
    final foreign = MapContextTarget(
      mapId: 'b',
      family: MapContextFamily.decor,
      id: decor.id,
      label: 'Arbre',
      kindLabel: 'Décor',
    );

    final steps = document.undoCount;
    expect(
      MapContextCommandRunner(
        contextAt(document, const GridPos(x: 4, y: 4)),
      ).run(MapContextCommand.delete, foreign),
      contains('n’est plus à cet endroit'),
    );
    expect(document.current.placedElements, hasLength(1));
    expect(document.undoCount, steps);
  });

  test('front and back describe the menu target, not a previous click', () {
    final document = documentFor('a');
    final commands = MapEditingCommands(document, workspaceProject);
    final bottom = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    final top = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    // A previous left click left another element selected elsewhere.
    commands.place(workspaceElement, const GridPos(x: 9, y: 9));

    final context = contextAt(document, const GridPos(x: 4, y: 4));
    final targets = mapContextTargetsAt(
      document,
      workspaceProject,
      const GridPos(x: 4, y: 4),
    );
    final topTarget = targets.firstWhere((item) => item.id == top);
    final bottomTarget = targets.firstWhere((item) => item.id == bottom);

    final topActions = mapContextActionsFor(topTarget, context);
    expect(
      topActions
          .firstWhere((a) => a.command == MapContextCommand.bringForward)
          .enabled,
      isFalse,
      reason: 'the top decor of this stack cannot go further forward',
    );
    expect(
      topActions
          .firstWhere((a) => a.command == MapContextCommand.sendBackward)
          .enabled,
      isTrue,
    );

    final bottomActions = mapContextActionsFor(bottomTarget, context);
    expect(
      bottomActions
          .firstWhere((a) => a.command == MapContextCommand.bringForward)
          .enabled,
      isTrue,
      reason: 'choosing another target refreshes its own availability',
    );
    expect(
      bottomActions
          .firstWhere((a) => a.command == MapContextCommand.sendBackward)
          .enabled,
      isFalse,
    );

    int orderOf(String id) => document.current.placedElements
        .firstWhere((item) => item.id == id)
        .visualOrder;
    expect(orderOf(bottom), lessThan(orderOf(top)));

    expect(
      MapContextCommandRunner(
        context,
      ).run(MapContextCommand.bringForward, bottomTarget),
      isNull,
    );
    expect(
      orderOf(bottom),
      greaterThan(orderOf(top)),
      reason: 'the decor chosen in the menu really moved in front',
    );

    document.restore(redo: false);
    expect(
      orderOf(bottom),
      lessThan(orderOf(top)),
      reason: 'and the move is a single, undoable step',
    );
  });

  test('a zone keeps its payload and identity when it is moved', () {
    final document = documentFor('a');
    final zones = GameplayZoneEditingCommands(document, workspaceProject);
    final zone = zones.place(GameplayZoneKind.hazard, area);
    zones.updateHazard(zone.id, damagePerStep: 2);

    zones.move(zone.id, const GridPos(x: 8, y: 6));
    final moved = zones.selected(zone.id)!;
    expect(moved.area.pos, const GridPos(x: 8, y: 6));
    expect(moved.area.size, area.size);
    expect(moved.hazard!.damagePerStep, 2);
    expect(moved.id, zone.id);
  });
}
