

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/gameplay_zone_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData endpoint(String id, DiveZoneRole role) => workspaceMap(id).copyWith(
  layers: const [],
  entities: [
    MapEntity(
      id: '$id-spawn',
      name: 'Arrivée locale',
      kind: MapEntityKind.spawn,
      pos: const GridPos(x: 2, y: 2),
      spawn: const MapEntitySpawnData(),
    ),
  ],
  gameplayZones: [
    MapGameplayZone(
      id: 'terrain',
      kind: GameplayZoneKind.movement,
      area: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 6, height: 6),
      ),
      movement: MovementZonePayload(
        requiredMode: role == DiveZoneRole.surface
            ? MovementMode.surf
            : MovementMode.dive,
      ),
    ),
    MapGameplayZone(
      id: 'point',
      name: 'Point de Plongée',
      kind: GameplayZoneKind.fieldAction,
      area: const MapRect(
        pos: GridPos(x: 2, y: 2),
        size: GridSize(width: 1, height: 1),
      ),
      fieldAction: FieldActionZonePayload(
        actionKind: FieldActionZoneKind.dive,
        dive: DiveZonePayload(role: role),
      ),
    ),
  ],
);
void main() {
  test(
    'Dive role, exact local spawn and movement mode stay draft with Undo redo',
    () {
      final map = endpoint('a', DiveZoneRole.surface);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: map, revision: 'initial', mapId: 'a'),
      );
      final commands = GameplayZoneEditingCommands(document, workspaceProject);
      commands.configureDive('point', arrivalSpawnId: 'a-spawn');
      final configured = document.current;
      expect(document.dirty, isTrue);
      expect(document.saved, map);
      document.restore(redo: false);
      expect(document.current, map);
      document.restore(redo: true);
      expect(document.current, configured);
      commands.updateMovement('terrain', requiredMode: MovementMode.dive);
      final deep = document.current;
      expect(
        deep.gameplayZones.first.movement!.requiredMode,
        MovementMode.dive,
      );
      document.restore(redo: false);
      expect(document.current, configured);
      document.restore(redo: true);
      expect(document.current, deep);
    },
  );
}
