import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:avelune_studio/features/characters/application/character_editing_commands.dart';
import 'package:avelune_studio/features/characters/application/character_movement_inputs.dart';
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

  test('timing input rejects invalid values before history mutation and commits valid values', () {
    final fixture = _fixture();
    final inputs = CharacterMovementInputs();
    final commands = CharacterEditingCommands(fixture.$1, fixture.$2);
    final original = fixture.$1.current.entities.single.npc!.movement;
    for (final invalid in ['0', '-1', '60001', 'not a number']) {
      expect(inputs.timing(original, invalid, pause: false), isNull);
      expect(fixture.$1.undoCount, 0);
      expect(
        fixture.$1.current.entities.single.npc!.movement.stepDurationMs,
        250,
      );
    }
    expect(
      inputs.problem,
      'La durée du pas doit être comprise entre 1 et 60 000 ms.',
    );
    commands.setMovementConfiguration(
      'npc',
      inputs.timing(original, '480', pause: false)!,
    );
    expect(
      fixture.$1.current.entities.single.npc!.movement.stepDurationMs,
      480,
    );
    expect(fixture.$1.undoCount, 1);
    expect(inputs.timing(original, '0', pause: true)!.pauseDurationMs, 0);
    expect(inputs.timing(original, '3600001', pause: true), isNull);
  });

  test('3D fixed routes retain bounded movement area and random pauses', () {
    final fixture = _fixture(spatial: true);
    final commands = CharacterEditingCommands(fixture.$1, fixture.$2);
    final inputs = CharacterMovementInputs();
    commands.setMovementConfiguration('npc', _movement());
    expect(fixture.$1.current.entities.single.npc!.movement, _movement());
    expect(fixture.$1.undoCount, 1);
    final bounded = inputs.toggleArea(
      _movement(),
      fixture.$1.current,
      fixture.$1.current.entities.single,
    );
    commands.setMovementConfiguration('npc', bounded);
    expect(
      fixture.$1.current.entities.single.npc!.movement.movementArea,
      const MapRect(
        pos: GridPos(x: 2, y: 3),
        size: GridSize(width: 3, height: 3),
      ),
    );
    commands.setMovementConfiguration(
      'npc',
      bounded.copyWith(pauseDurationsMs: const [500, 1000]),
    );
    final current = fixture.$1.current.entities.single.npc!.movement;
    expect(current.pauseDurationsMs, [500, 1000]);
    expect(inputs.area(current, fixture.$1.current, 'x', '-1'), isNull);
    expect(inputs.problem, 'La zone doit rester dans les limites de la carte.');
    expect(inputs.pauseChoice(current, 0, '-1'), isNull);
    expect(inputs.pauseChoice(current, 0, '250')!.pauseDurationsMs, [
      250,
      1000,
    ]);
  });
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
