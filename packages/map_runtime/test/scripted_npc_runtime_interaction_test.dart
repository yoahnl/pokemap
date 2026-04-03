import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

void main() {
  group('scripted NPC runtime interaction coherence', () {
    test('NPC moved in runtime remains interactable at its new canonical cell',
        () {
      const npc = MapEntity(
        id: 'npc_professor',
        kind: MapEntityKind.npc,
        pos: GridPos(x: 4, y: 1),
        npc: MapEntityNpcData(
          dialogue: DialogueRef(dialogueId: 'intro'),
        ),
      );

      const map = MapData(
        id: 'map',
        name: 'Map',
        size: GridSize(width: 8, height: 4),
        layers: <MapLayer>[
          MapLayer.collision(
            id: 'collision',
            name: 'Collision',
            collisions: <bool>[
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
              false,
            ],
          ),
        ],
        entities: <MapEntity>[npc],
      );

      var world = GameplayWorldState.initial(
        map: map,
        playerPos: const GridPos(x: 3, y: 1),
        playerFacing: Direction.east,
      );

      final initialInteract = stepGameplayWorld(world, const InteractIntent());
      expect(initialInteract, isA<NpcInteracted>());
      expect((initialInteract as NpcInteracted).entity.id, 'npc_professor');
      expect(initialInteract.entity.npc?.dialogue?.dialogueId, 'intro');

      // Simule le commit runtime d'un déplacement scripté déjà terminé.
      world =
          world.withEntityPosition('npc_professor', const GridPos(x: 5, y: 1));

      // L'ancienne case ne doit plus être interactable.
      final oldCellInteract = stepGameplayWorld(
        world.withPlayer(
          world.player.copyWith(
            pos: const GridPos(x: 3, y: 1),
            facing: Direction.east,
          ),
        ),
        const InteractIntent(),
      );
      expect(oldCellInteract, isA<NothingToInteract>());

      // La nouvelle case doit être interactable avec le même dialogue.
      final newCellInteract = stepGameplayWorld(
        world.withPlayer(
          world.player.copyWith(
            pos: const GridPos(x: 4, y: 1),
            facing: Direction.east,
          ),
        ),
        const InteractIntent(),
      );
      expect(newCellInteract, isA<NpcInteracted>());
      expect((newCellInteract as NpcInteracted).entity.id, 'npc_professor');
      expect(newCellInteract.entity.npc?.dialogue?.dialogueId, 'intro');
    });
  });
}
