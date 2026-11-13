import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

import '../support/map_workspace_fixture.dart';
import 'character_editing_test.dart' show guide;

void main() {
  test(
    'random step remains directionless across typed command, JSON and history',
    () {
      final fixture = _fixture();
      final command = CharacterEditingCommands(fixture.$1, fixture.$2);
      command.setMovementConfiguration(
        'npc',
        fixture.$1.current.entities.single.npc!.movement.copyWith(
          routeSteps: const [
            MapEntityNpcRouteStep.randomMove(),
            MapEntityNpcRouteStep.randomFacing(),
          ],
        ),
      );
      final movement = fixture.$1.current.entities.single.npc!.movement;
      expect(
        movement.routeSteps.first,
        const MapEntityNpcRouteStep.randomMove(),
      );
      expect(
        MapData.fromJson(fixture.$1.current.toJson())
            .entities
            .single
            .npc!
            .movement,
        movement,
      );
      expect(fixture.$1.undoCount, 1);
      fixture.$1.restore(redo: false);
      expect(
        fixture.$1.current.entities.single.npc!.movement.routeSteps.first,
        const MapEntityNpcRouteStep.face(direction: EntityFacing.west),
      );
    },
  );
  test('Studio typed command preserves NPC bindings and native history', () {
    final fixture = _fixture();
    final commands = CharacterEditingCommands(fixture.$1, fixture.$2);
    final original = fixture.$1.current;
    final next = original.entities.single.npc!.movement.copyWith(
      routeSteps: const [
        MapEntityNpcRouteStep.move(direction: EntityFacing.east),
        MapEntityNpcRouteStep.face(direction: EntityFacing.north),
      ],
    );
    commands.setMovementConfiguration('npc', next);
    final committed = fixture.$1.current;
    expect(committed.entities.single.npc!.movement, next);
    expect(committed.entities.single.npc!.counterInteractionSides, [
      EntityFacing.north,
    ]);
    expect(committed.entities.single.npc!.characterId, guide.id);
    expect(committed.entities.single.pos, original.entities.single.pos);
    expect(MapData.fromJson(committed.toJson()), committed);
    fixture.$1.restore(redo: false);
    expect(fixture.$1.current, original);
    fixture.$1.restore(redo: true);
    expect(fixture.$1.current, committed);
  });

  test(
    'typed route actions preserve ordering, bindings and scoped suspension',
    () {
      final fixture = _fixture();
      final document = fixture.$1;
      final commands = CharacterEditingCommands(document, fixture.$2);
      MapEntityNpcMovementConfig current() =>
          document.current.entities.single.npc!.movement;
      commands.setMovementConfiguration(
        'npc',
        current().copyWith(
          routeSteps: const [
            MapEntityNpcRouteStep.move(direction: EntityFacing.west),
            MapEntityNpcRouteStep.randomFacing(),
          ],
        ),
      );
      commands.setMovementConfiguration(
        'npc',
        current().copyWith(
          routeSteps: const [
            MapEntityNpcRouteStep.move(direction: EntityFacing.east),
            MapEntityNpcRouteStep.randomFacing(),
          ],
        ),
      );
      commands.setMovementConfiguration(
        'npc',
        current().copyWith(routeSteps: current().routeSteps.reversed.toList()),
      );
      final movement = current();
      expect(movement.routeSteps, const [
        MapEntityNpcRouteStep.randomFacing(),
        MapEntityNpcRouteStep.move(direction: EntityFacing.east),
      ]);
      expect(
        movement.suspendWhenInstanceBoolean,
        MapEntityNpcRouteInstanceBoolean(key: 'npc.autonomousRouteStopped'),
      );
      expect(document.current.entities.single.npc!.counterInteractionSides, [
        EntityFacing.north,
      ]);
      commands.setMovementConfiguration(
        'npc',
        current().copyWith(suspendWhenInstanceBoolean: null),
      );
      expect(current().suspendWhenInstanceBoolean, isNull);
      commands.setMovementConfiguration(
        'npc',
        current().copyWith(
          suspendWhenInstanceBoolean: MapEntityNpcRouteInstanceBoolean(
            key: 'npc.autonomousRouteStopped',
          ),
        ),
      );
      expect(
        current().suspendWhenInstanceBoolean?.key,
        'npc.autonomousRouteStopped',
      );
      expect(
        MapData.fromJson(document.current.toJson())
            .entities
            .single
            .npc!
            .movement,
        current(),
      );
      expect(document.undoCount, 5);
    },
  );

}

MapEntityNpcMovementConfig _movement() => MapEntityNpcMovementConfig(
  mode: MapEntityNpcMovementMode.fixedRoute,
  pauseDurationMs: 1600,
  stepDurationMs: 250,
  routeSteps: const [
    MapEntityNpcRouteStep.face(direction: EntityFacing.west),
    MapEntityNpcRouteStep.randomFacing(),
  ],
  suspendWhenInstanceBoolean: MapEntityNpcRouteInstanceBoolean(
    key: 'npc.autonomousRouteStopped',
  ),
);

(EditableMapDocument, ProjectManifest) _fixture({bool spatial = false}) {
  final map = workspaceMap('a').copyWith(
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    entities: [
      MapEntity(
        id: 'npc',
        name: 'Guide',
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 3, y: 4),
        npc: MapEntityNpcData(
          characterId: guide.id,
          displayName: 'Guide',
          counterInteractionSides: const [EntityFacing.north],
          movement: spatial ? const MapEntityNpcMovementConfig() : _movement(),
        ),
      ),
    ],
  );
  final project = workspaceProject.copyWith(
    settings: workspaceProject.settings.copyWith(
      dimension: spatial ? ProjectDimension.threeD : ProjectDimension.twoD,
    ),
    characters: [guide],
    scenes: [
      SceneAsset(
        id: 'win',
        name: 'Après la victoire',
        graph: SceneGraph(
          startNodeId: 'start',
          nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
              id: 'stop',
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setMapEventInstanceBoolean(
                  mapId: 'a',
                  eventId: 'npc',
                  key: 'npc.autonomousRouteStopped',
                  value: true,
                ),
              ),
            ),
            SceneNode(id: 'end', kind: SceneNodeKind.end),
          ],
          edges: [
            SceneEdge(
              id: 'begin',
              fromNodeId: 'start',
              fromPortId: 'completed',
              toNodeId: 'stop',
              kind: SceneEdgeKind.defaultFlow,
            ),
            SceneEdge(
              id: 'done',
              fromNodeId: 'stop',
              fromPortId: 'completed',
              toNodeId: 'end',
              kind: SceneEdgeKind.actionCompleted,
            ),
          ],
        ),
      ),
    ],
  );
  return (
    EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
    ),
    project,
  );
}
