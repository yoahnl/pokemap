import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_selection_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _root = 'test/fixtures/spatial_first_map';

ProjectManifest _project() => ProjectManifest.fromJson(
  jsonDecode(File('$_root/project.json').readAsStringSync())
      as Map<String, dynamic>,
);

MapData _map() {
  final source = MapData.fromJson(
    jsonDecode(File('$_root/maps/first-map.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  final scene = source.spatialScene!;
  return source.copyWith(
    spatialScene: scene.copyWith(
      instances: [
        ...scene.instances,
        SpatialModelInstance(
          id: 'oak_a',
          modelId: 'house',
          position: Model3dVector3(x: 3.25, y: 0.02, z: 10.5),
          rotationDegrees: 30,
          scale: 1.5,
        ),
        SpatialModelInstance(
          id: 'oak_b',
          modelId: 'house',
          position: Model3dVector3(x: 5.5, y: 0.02, z: 11.75),
        ),
      ],
    ),
    triggers: const [
      MapTrigger(
        id: 'quai',
        name: 'Quai',
        type: TriggerType.event,
        area: MapRect(
          pos: GridPos(x: 10, y: 10),
          size: GridSize(width: 2, height: 1),
        ),
      ),
    ],
  );
}

EditableMapDocument _document(MapData map, {String? mapId}) =>
    EditableMapDocument(
      MapWorkspaceDocument(map: map, mapId: mapId ?? map.id, revision: 'r'),
    );

MapSelectionTarget _decor(String id) => MapSelectionTarget(
  mapId: 'first-map',
  family: MapSelectionFamily.decor,
  id: id,
);

MapSelectionTarget _character(String id) => MapSelectionTarget(
  mapId: 'first-map',
  family: MapSelectionFamily.character,
  id: id,
);

SpatialModelInstance _instance(EditableMapDocument document, String id) =>
    document.current.spatialScene!.instances.firstWhere(
      (item) => item.id == id,
    );

void main() {
  final project = _project();

  test(
    'paste beside the originals keeps the layout, renames and is one undo step',
    () {
      final document = _document(_map());
      final before = document.current;
      final commands = MapSelectionCommands(document, project);
      final clipboard = commands.copy([
        _decor('oak_a'),
        _decor('oak_b'),
        _character('voyageur-halte'),
      ]);
      expect(document.current, same(before));
      final pasted = commands.paste(clipboard);
      expect(pasted, hasLength(3));
      expect(document.undoCount, 1);
      final ids = pasted.map((target) => target.id).toSet();
      expect(ids.intersection({'oak_a', 'oak_b', 'voyageur-halte'}), isEmpty);
      final copyA = _instance(document, pasted[0].id);
      final copyB = _instance(document, pasted[1].id);
      expect(copyA.position.x, 4.25);
      expect(copyA.position.z, 11.5);
      expect(copyA.rotationDegrees, 30);
      expect(copyA.scale, 1.5);
      expect(copyB.position.x, 6.5);
      expect(copyB.position.z, 12.75);
      final npc = document.current.entities.firstWhere(
        (entity) => entity.id == pasted[2].id,
      );
      expect(npc.name, 'Voyageur de la halte (copie)');
      expect(npc.pos, const GridPos(x: 9, y: 10));
      expect(_instance(document, 'oak_a').position.x, 3.25);
      document.restore(redo: false);
      expect(document.current, before);
    },
  );

  test('paste at the pointer cell anchors the group top-left there', () {
    final document = _document(_map());
    final commands = MapSelectionCommands(document, project);
    final clipboard = commands.copy([_decor('oak_a'), _decor('oak_b')]);
    final pasted = commands.paste(clipboard, at: const GridPos(x: 1, y: 2));
    final copyA = _instance(document, pasted[0].id);
    final copyB = _instance(document, pasted[1].id);
    expect(copyA.position.x, 1.25);
    expect(copyA.position.z, 2.5);
    expect(copyB.position.x, 3.5);
    expect(copyB.position.z, 3.75);
  });

  test('paste on another map of the project keeps the coordinates', () {
    final source = _document(_map());
    final clipboard = MapSelectionCommands(source, project).copy([
      _decor('oak_a'),
      MapSelectionTarget(
        mapId: 'first-map',
        family: MapSelectionFamily.trigger,
        id: 'quai',
      ),
    ]);
    final other = _document(
      _map().copyWith(
        id: 'second-map',
        spatialScene: _map().spatialScene!.copyWith(instances: const []),
        triggers: const [],
      ),
      mapId: 'second-map',
    );
    final pasted = MapSelectionCommands(other, project).paste(clipboard);
    expect(pasted.every((target) => target.mapId == 'second-map'), isTrue);
    final copy = _instance(other, pasted[0].id);
    expect(copy.position.x, 3.25);
    expect(copy.position.z, 10.5);
    final trigger = other.current.triggers.single;
    expect(trigger.name, 'Quai (copie)');
    expect(trigger.area.pos, const GridPos(x: 10, y: 10));
    expect(other.undoCount, 1);
  });

  test('duplicate offsets the copies by one cell in a single undo step', () {
    final document = _document(_map());
    final before = document.current;
    final duplicated = MapSelectionCommands(
      document,
      project,
    ).duplicate([_decor('oak_a'), _decor('oak_b')]);
    expect(duplicated, hasLength(2));
    expect(document.undoCount, 1);
    expect(_instance(document, duplicated[0].id).position.x, 4.25);
    expect(_instance(document, duplicated[1].id).position.z, 12.75);
    document.restore(redo: false);
    expect(document.current, before);
  });

  test(
    'cut removes the originals in one step and keeps them in the clipboard',
    () {
      final document = _document(_map());
      final before = document.current;
      final commands = MapSelectionCommands(document, project);
      final clipboard = commands.cut([
        _decor('oak_a'),
        _character('voyageur-halte'),
      ]);
      expect(document.undoCount, 1);
      expect(
        document.current.spatialScene!.instances.any(
          (item) => item.id == 'oak_a',
        ),
        isFalse,
      );
      expect(document.current.entities, isEmpty);
      final pasted = commands.paste(clipboard);
      expect(pasted, hasLength(2));
      expect(_instance(document, pasted[0].id).position.x, 3.25);
      document
        ..restore(redo: false)
        ..restore(redo: false);
      expect(document.current, before);
    },
  );

  test('delete removes every selected element atomically', () {
    final document = _document(_map());
    final before = document.current;
    final commands = MapSelectionCommands(document, project);
    expect(
      () => commands.delete([
        _decor('oak_a'),
        _character('voyageur-halte'),
      ], guard: (target) => target.id == 'voyageur-halte' ? 'Utilisé' : null),
      throwsA(isA<StateError>().having((e) => e.message, 'message', 'Utilisé')),
    );
    expect(document.current, same(before));
    commands.delete([_decor('oak_a'), _decor('oak_b')]);
    expect(document.undoCount, 1);
    expect(
      document.current.spatialScene!.instances.where(
        (item) => item.id.startsWith('oak_'),
      ),
      isEmpty,
    );
  });

  test('move shifts the whole group by whole cells or refuses it entirely', () {
    final document = _document(_map());
    final before = document.current;
    final commands = MapSelectionCommands(document, project);
    final group = [
      _decor('oak_a'),
      _decor('oak_b'),
      _character('voyageur-halte'),
    ];
    commands.move(group, 1, -1);
    expect(document.undoCount, 1);
    expect(_instance(document, 'oak_a').position.x, 4.25);
    expect(_instance(document, 'oak_b').position.z, 10.75);
    expect(document.current.entities.single.pos, const GridPos(x: 9, y: 8));
    expect(() => commands.move(group, 0, 5), throwsStateError);
    expect(document.undoCount, 1);
    document.restore(redo: false);
    expect(document.current, before);
  });

  test('rotate turns 3D decors by a quarter in one undo step', () {
    final document = _document(_map());
    MapSelectionCommands(
      document,
      project,
    ).rotate([_decor('oak_a'), _decor('oak_b')], 90);
    expect(document.undoCount, 1);
    expect(_instance(document, 'oak_a').rotationDegrees, 120);
    expect(_instance(document, 'oak_b').rotationDegrees, 90);
  });

  test('copy refuses a spawn point and an unknown element', () {
    final document = _document(
      _map().copyWith(
        entities: [
          ..._map().entities,
          const MapEntity(
            id: 'spawn',
            kind: MapEntityKind.spawn,
            pos: GridPos(x: 2, y: 2),
          ),
        ],
      ),
    );
    final commands = MapSelectionCommands(document, project);
    expect(
      () => commands.copy([
        MapSelectionTarget(
          mapId: 'first-map',
          family: MapSelectionFamily.marker,
          id: 'spawn',
        ),
      ]),
      throwsStateError,
    );
    expect(() => commands.copy([_decor('missing')]), throwsStateError);
  });
}
