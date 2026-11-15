import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_properties.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _root = 'test/fixtures/spatial_first_map';

void main() {
  final project = ProjectManifest.fromJson(
    jsonDecode(File('$_root/project.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final source = MapData.fromJson(
    jsonDecode(File('$_root/maps/first-map.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final map = source.copyWith(
    spatialScene: source.spatialScene!.copyWith(
      instances: [
        SpatialModelInstance(
          id: 'oak',
          modelId: 'house',
          position: Model3dVector3(x: 3.5, y: .75, z: 4.5),
          rotationDegrees: 15,
          scale: 1.25,
        ),
      ],
    ),
  );
  EditableMapDocument document() => EditableMapDocument(
    MapWorkspaceDocument(map: map, mapId: map.id, revision: 'r'),
  );
  MapSelectionTarget target(MapSelectionFamily family, String id) =>
      MapSelectionTarget(mapId: map.id, family: family, id: id);

  test('a 3D decor exposes X, Y, height above ground, turn and size', () {
    final edited = document();
    final properties = mapSelectionProperties(edited, project, [
      target(MapSelectionFamily.decor, 'oak'),
    ]) as SpatialModelProperties;
    final ground = map.spatialScene!.worldHeightAt(3.5, 4.5);
    expect(properties.name, 'Maison d’Oliville');
    expect((properties.x, properties.y), (3.5, 4.5));
    expect(properties.z, closeTo(.75 - ground, 1e-9));
    expect((properties.rotation, properties.scale), (15, 1.25));
    expect(properties.animated, isNull);
    MapSelectionPropertyCommands(edited, project).setSpatial('oak', z: 2);
    final moved = edited.current.spatialScene!.instances.single;
    expect(moved.position.y, closeTo(ground + 2, 1e-9));
    expect(edited.undoCount, 1);
    expect(
      () => MapSelectionPropertyCommands(
        edited,
        project,
      ).setAnimated('oak', animated: true),
      throwsStateError,
    );
  });

  test('a character exposes its cell and moves through it', () {
    final edited = document();
    final npc = map.entities.single;
    final properties = mapSelectionProperties(edited, project, [
      target(MapSelectionFamily.character, npc.id),
    ]) as GridElementProperties;
    expect(properties.name, isNotEmpty);
    expect(properties.position, npc.pos);
    MapSelectionPropertyCommands(
      edited,
      project,
    ).setGrid(properties, const GridPos(x: 2, y: 3));
    expect(edited.current.entities.single.pos, const GridPos(x: 2, y: 3));
    expect(edited.undoCount, 1);
  });

  test('several elements only report their count', () {
    final properties = mapSelectionProperties(document(), project, [
      target(MapSelectionFamily.decor, 'oak'),
      target(MapSelectionFamily.character, map.entities.single.id),
    ]);
    expect((properties as GroupSelectionProperties).count, 2);
    expect(mapSelectionProperties(document(), project, const []), isNull);
  });
}
