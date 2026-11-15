import 'package:map_core/map_core_domain.dart';

import '../domain/map_catalog_port.dart';
import 'map_library_deletion.dart';
import 'map_library_ids.dart';
import 'map_library_outcome.dart';
import 'map_workspace_controller.dart';

export 'map_library_deletion.dart';
export 'map_library_ids.dart';
export 'map_library_outcome.dart';
export 'map_library_usages.dart';

const mapLibraryMaxSide = 256;

final class MapLibraryCommands {
  const MapLibraryCommands(this.maps);

  final MapWorkspaceController maps;

  ProjectManifest? get _project => maps.project;

  ProjectDimension get dimension =>
      _project?.settings.dimension ?? ProjectDimension.twoD;

  ({int width, int height}) get defaultSize => (
    width: _project?.settings.defaultMapWidth ?? 20,
    height: _project?.settings.defaultMapHeight ?? 15,
  );

  bool get busy => maps.catalogBusy || maps.pendingCatalogReceipt != null;

  bool get canDelete => maps.hasCompleteProject;

  Future<MapLibraryOutcome> createMap({
    required String name,
    required int width,
    required int height,
    String? groupId,
  }) async {
    final project = _project;
    final title = name.trim();
    if (title.isEmpty) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.nameRequired);
    }
    if (!_validSide(width) || !_validSide(height)) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.sizeInvalid);
    }
    if (project == null) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.missing);
    }
    final mapId = _newMapId(title);
    final result = await maps.mutateCatalog('map.create', {
      'mapId': mapId,
      'name': title,
      'width': width,
      'height': height,
      'groupId': ?groupId,
    });
    return _openCreated(result, mapId);
  }

  Future<MapLibraryOutcome> duplicateMap(
    String sourceMapId, {
    required String name,
  }) async {
    final source = _map(sourceMapId);
    if (source == null) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.missing);
    }
    final title = name.trim().isEmpty ? source.name : name.trim();
    final targetId = _newMapId(title);
    final result = await maps.mutateCatalog('map.duplicate', {
      'sourceMapId': sourceMapId,
      'targetMapId': targetId,
      'name': title,
      'groupId': source.groupId,
    });
    return _openCreated(result, targetId);
  }

  Future<MapLibraryOutcome> renameMap(String mapId, String name) async {
    final entry = _map(mapId);
    final title = name.trim();
    if (title.isEmpty) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.nameRequired);
    }
    if (entry == null) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.missing);
    }
    if (entry.name == title) return MapLibraryOutcome.done(mapId: mapId);
    return mapLibraryOutcome(
      await maps.mutateCatalog('map.update_metadata', {
        'mapId': mapId,
        'name': title,
      }),
      mapId: mapId,
    );
  }

  Future<MapLibraryOutcome> moveMap(String mapId, String? groupId) async {
    final entry = _map(mapId);
    if (entry == null ||
        (groupId != null && !_project!.groups.any((g) => g.id == groupId))) {
      return const MapLibraryOutcome.failed(MapLibraryProblem.missing);
    }
    if (entry.groupId == groupId) return MapLibraryOutcome.done(mapId: mapId);
    return mapLibraryOutcome(
      await maps.mutateCatalog('map.library.reorganize', {
        'assignments': [
          {'mapId': mapId, 'groupId': groupId},
        ],
      }),
      mapId: mapId,
    );
  }

  Future<MapLibraryOutcome> createFolder(String name, {String? parentId}) {
    final project = _project;
    final title = name.trim();
    if (title.isEmpty) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.nameRequired),
      );
    }
    if (project == null) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.missing),
      );
    }
    if (_nameTaken(title, parentId)) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.folderNameTaken),
      );
    }
    final id = mapLibraryIdFor(title, {
      for (final group in project.groups) group.id,
    }, fallback: 'dossier');
    return _organize([
      ...project.groups,
      ProjectMapGroup(
        id: id,
        name: title,
        type: MapGroupType.special,
        parentGroupId: parentId,
        sortOrder: project.groups.length,
      ),
    ], groupId: id);
  }

  Future<MapLibraryOutcome> renameFolder(String groupId, String name) {
    final title = name.trim();
    final group = _project?.groups.where((g) => g.id == groupId).firstOrNull;
    if (title.isEmpty) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.nameRequired),
      );
    }
    if (group == null) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.missing),
      );
    }
    if (group.name == title) {
      return Future.value(MapLibraryOutcome.done(groupId: groupId));
    }
    if (_nameTaken(title, group.parentGroupId, except: groupId)) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.folderNameTaken),
      );
    }
    return _organize([
      for (final item in _project!.groups)
        item.id == groupId ? item.copyWith(name: title) : item,
    ], groupId: groupId);
  }

  bool folderDeletionBlocked(String groupId) {
    final project = _project;
    return project == null ||
        project.maps.any((map) => map.groupId == groupId) ||
        project.groups.any((group) => group.parentGroupId == groupId);
  }

  Future<MapLibraryOutcome> deleteFolder(String groupId) {
    if (!(_project?.groups.any((g) => g.id == groupId) ?? false)) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.missing),
      );
    }
    if (folderDeletionBlocked(groupId)) {
      return Future.value(
        const MapLibraryOutcome.failed(MapLibraryProblem.folderNotEmpty),
      );
    }
    return _organize([
      for (final item in _project!.groups)
        if (item.id != groupId) item,
    ]);
  }

  Future<MapLibraryDeletion> analyzeDeletion(String mapId) =>
      MapLibraryDeletion.analyze(maps, mapId);

  Future<MapLibraryOutcome> confirmDeletion(MapLibraryDeletion deletion) =>
      deletion.confirm(maps);

  Future<MapLibraryOutcome> _organize(
    List<ProjectMapGroup> groups, {
    String? groupId,
  }) async => mapLibraryOutcome(
    await maps.mutateCatalog('map.library.reorganize', {
      'groups': [for (final group in groups) group.toJson()],
      'assignments': const <Object?>[],
    }),
    groupId: groupId,
  );

  Future<MapLibraryOutcome> _openCreated(
    MapCatalogResult result,
    String? mapId,
  ) async {
    final outcome = mapLibraryOutcome(result, mapId: mapId);
    final entry = mapId == null ? null : _map(mapId);
    if (!outcome.ok || entry == null) return outcome;
    await maps.activate(entry);
    return outcome;
  }

  bool _nameTaken(String name, String? parentId, {String? except}) =>
      _project!.groups.any(
        (group) =>
            group.id != except &&
            group.parentGroupId == parentId &&
            group.name.trim().toLowerCase() == name.toLowerCase(),
      );

  String _newMapId(String title) => mapLibraryIdFor(title, {
    for (final map in _project?.maps ?? const <ProjectMapEntry>[]) ...{
      map.id.toLowerCase(),
      _pathId(map.relativePath),
    },
  });

  ProjectMapEntry? _map(String id) =>
      _project?.maps.where((map) => map.id == id).firstOrNull;

  static bool _validSide(int value) => value > 0 && value <= mapLibraryMaxSide;

  static String _pathId(String relativePath) {
    final name = relativePath.split('/').last;
    return name.endsWith('.json')
        ? name.substring(0, name.length - 5).toLowerCase()
        : name.toLowerCase();
  }
}
