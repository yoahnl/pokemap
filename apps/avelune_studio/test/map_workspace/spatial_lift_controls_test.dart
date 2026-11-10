import 'package:avelune_studio/features/map_workspace/application/spatial_lift_editing_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

void main() {
  test('create edit reject and undo a vertical platform through its editing session', () {
    final deck = SpatialModelInstance(
      id: 'deck',
      modelId: 'model',
      position: Model3dVector3(x: 2, y: 0, z: 2),
    );
    final map = MapData(
      id: 'room',
      version: ProjectVersion.v9,
      name: 'Room',
      size: const GridSize(width: 8, height: 8),
      spatialScene: MapSpatialScene(width: 8, depth: 8, instances: [deck]),
    );
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'initial', mapId: map.id),
    );
    final editing = SpatialLiftEditingSession(document, deck);
    addTearDown(editing.dispose);
    expect(editing.apply(), isTrue);
    expect(document.current.spatialScene!.lifts.single.instanceId, 'deck');
    expect(
      document.current.spatialScene!.instances,
      map.spatialScene!.instances,
    );
    editing.values['upper'] = '3,25';
    expect(editing.apply(), isTrue);
    expect(document.current.spatialScene!.lifts.single.upperHeight, 3.25);
    final before = document.current;
    editing.values['upper'] = '-1';
    expect(editing.apply(), isFalse);
    expect(document.current, same(before));
    expect(editing.delete(), isTrue);
    expect(document.current.spatialScene!.lifts, isEmpty);
    document.restore(redo: false);
    expect(document.current.spatialScene!.lifts.single.upperHeight, 3.25);
  });
}
