import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:avelune_studio/features/map_workspace/coordination/map_selection_shortcuts.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

const _root = 'test/fixtures/spatial_first_map';
const _session = ProjectSession(
  sessionId: 'scoped-paste',
  name: 'Catalogue',
  directoryPath: '/project',
  storage: ProjectSessionStorage.workingCatalog,
);

ProjectManifest _project() {
  final project = ProjectManifest.fromJson(
    jsonDecode(File('$_root/project.json').readAsStringSync())
        as Map<String, dynamic>,
  );
  return project.copyWith(
    maps: [
      ...project.maps,
      project.maps.single.copyWith(
        id: 'second-map',
        name: 'Seconde',
        relativePath: 'maps/second-map.json',
      ),
    ],
  );
}

MapData _first() => MapData.fromJson(
  jsonDecode(File('$_root/maps/first-map.json').readAsStringSync())
      as Map<String, dynamic>,
);

MapData _second() {
  final map = _first();
  return map.copyWith(
    id: 'second-map',
    name: 'Seconde',
    entities: const [],
    spatialScene: map.spatialScene!.copyWith(
      instances: map.spatialScene!.instances
          .where((item) => item.modelId != 'house')
          .toList(),
    ),
  );
}

final class _ScopedPort
    implements MapWorkspaceScopedPort, MapWorkspaceResourceClosurePort {
  _ScopedPort(this.project);
  final ProjectManifest project;
  final closures = <String>[];

  ProjectManifest _definitionsFor(MapData map) {
    final models = {
      for (final item in map.spatialScene!.instances) item.modelId,
    };
    final characters = {
      for (final entity in map.entities) ?entity.npc?.characterId,
    };
    return project.copyWith(
      models3d: project.models3d
          .where((model) => models.contains(model.id))
          .toList(),
      characters: project.characters
          .where((character) => characters.contains(character.id))
          .toList(),
    );
  }

  MapData _map(String id) => id == 'second-map' ? _second() : _first();

  @override
  Future<MapWorkspaceCatalog> loadCatalog(ProjectSession session) async =>
      MapWorkspaceCatalog(
        metadata: project.copyWith(models3d: const [], characters: const []),
        revision: 'catalog-1',
      );

  @override
  Future<MapWorkspaceSelection> loadMapSelection(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final document = await loadMap(session, entry);
    return MapWorkspaceSelection(
      document: document,
      definitions: _definitionsFor(document.map),
      catalogRevision: 'catalog-1',
      snapshotRevision: 'map-state-1',
    );
  }

  @override
  Future<MapWorkspaceCatalog> loadResourceClosure(
    ProjectSession session,
    String canonicalKind,
    String id,
  ) async {
    closures.add('$canonicalKind:$id');
    return MapWorkspaceCatalog(
      metadata: project.copyWith(
        models3d: canonicalKind == 'model3d'
            ? project.models3d.where((model) => model.id == id).toList()
            : const [],
        characters: canonicalKind == 'character'
            ? project.characters.where((item) => item.id == id).toList()
            : const [],
      ),
      revision: 'catalog-1',
    );
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async => MapWorkspaceDocument(
    map: _map(entry.id),
    revision: 'map-1',
    mapId: entry.id,
  );

  @override
  Future<ProjectManifest> materializeProject(ProjectSession session) =>
      throw StateError('The scoped controller must not read everything.');

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) =>
      throw StateError('The scoped controller must not read everything.');

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async => 'map-2';
}

void main() {
  test(
    'pasting on a map that never used the model loads its definition first',
    () async {
      final port = _ScopedPort(_project());
      final maps = MapWorkspaceController(_session, port);
      addTearDown(maps.dispose);
      final view = MapEditingViewportSession();
      addTearDown(view.dispose);
      await maps.initialize();
      await maps.activate(maps.project!.maps.first);
      final first = maps.active!;
      view.select(first, MapSelectionFamily.decor, 'house_31');
      view.toggleInSelection(
        first,
        MapSelectionFamily.character,
        'voyageur-halte',
      );
      final actions = MapSelectionActions(maps, view);
      actions.copy();
      expect(maps.clipboard?.items, hasLength(2));

      await maps.activate(maps.project!.maps.last);
      final second = maps.active!;
      expect(second.base.mapId, 'second-map');
      expect(
        maps.project!.models3d.any((model) => model.id == 'house'),
        isFalse,
      );
      view.pointer = (mapId: 'second-map', cell: const GridPos(x: 3, y: 3));

      await actions.paste();

      expect(second.error, isNull);
      expect(
        port.closures,
        containsAll(['model3d:house', 'character:voyageur-psdk']),
      );
      final pasted = view.selectionIn('second-map');
      expect(pasted, hasLength(2));
      final house = second.current.spatialScene!.instances.singleWhere(
        (item) => item.modelId == 'house',
      );
      expect((house.position.x.floor(), house.position.z.floor()), (3, 3));
      expect(second.current.entities, hasLength(1));
      expect(second.undoCount, 1);
      expect(
        maps.project!.models3d.any((model) => model.id == 'house'),
        isTrue,
      );
      expect(
        maps.visualProject!.models3d.any((model) => model.id == 'house'),
        isTrue,
      );
      expect(
        maps.visualProject!.characters.any(
          (item) => item.id == 'voyageur-psdk',
        ),
        isTrue,
      );
    },
  );
}
