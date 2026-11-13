import 'package:avelune_studio/features/map_workspace/application/map_arrival_choices.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {

  MapData garden() => workspaceMap('b').copyWith(
    name: 'Jardin',
    entities: const [
      MapEntity(
        id: 'start',
        name: 'Départ',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 2, y: 3),
      ),
    ],
    warps: const [
      MapWarp(
        id: 'landing',
        pos: GridPos(x: 6, y: 7),
        targetMapId: 'b',
        targetPos: GridPos(x: 6, y: 7),
        triggerMode: MapWarpTriggerMode.sceneOnly,
      ),
      MapWarp(
        id: 'back',
        pos: GridPos(x: 9, y: 1),
        targetMapId: 'a',
        targetPos: GridPos(x: 1, y: 1),
      ),
      MapWarp(
        id: 'elsewhere',
        pos: GridPos(x: 4, y: 4),
        targetMapId: 'house-geon',
        targetPos: GridPos(x: 0, y: 0),
      ),
    ],
  );

  test('arrival points come from the destination map only', () {
    final choices = mapArrivalChoices(garden(), fromMapId: 'a');
    expect(choices.map((choice) => (choice.label, choice.pos)), [
      ('Départ du joueur', const GridPos(x: 2, y: 3)),
      ('Point d’arrivée', const GridPos(x: 6, y: 7)),
      ('Passage qui revient ici', const GridPos(x: 9, y: 1)),
    ]);
    expect(
      mapArrivalChoices(garden(), fromMapId: 'a', query: 'revient'),
      hasLength(1),
    );
    expect(mapArrivalProblem(garden(), const GridPos(x: 3, y: 3)), isNull);
    expect(
      mapArrivalProblem(garden(), const GridPos(x: 30, y: 2)),
      contains('hors de « Jardin » (20 × 16)'),
    );
  });

}
