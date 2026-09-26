import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:map_authoring/map_authoring_documents.dart';
import 'package:map_authoring/map_authoring_local.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/data/map_document_retention.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';

part 'local_map_workspace_catalog.dart';

final class LocalMapWorkspaceAdapter implements MapWorkspacePort {
  LocalMapWorkspaceAdapter({
    ProjectFileReader? reader,
    AtomicMapDocumentPersistence? persistence,
  }) : _reader = reader ?? const LocalProjectFileReader(),
       _persistence = persistence ?? const AtomicMapDocumentPersistence();

  final ProjectFileReader _reader;
  final AtomicMapDocumentPersistence _persistence;
  final _projects = <String, _ProjectDocument>{};
  final _loadedPaths = <(String, String), String>{};
  Future<void> _writes = Future.value();

  Future<T> withResourceMutation<T>(Future<T> Function() operation) {
    final result = _writes.then((_) => operation());
    _writes = result.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return result;
  }

  Future<({ProjectManifest manifest, String revision})> resourceBaseline(
    ProjectSession session, {
    bool refreshCatalog = false,
  }) async {
    var project = _project(session);
    await _requireRoot(session);
    if (refreshCatalog) {
      project = await _refreshCatalog(session, project);
    }
    await _requireProjectRevision(session, project);
    return (manifest: project.manifest, revision: project.revision);
  }

  Future<void> acceptResourceMutation(
    ProjectSession session,
    ResourceMutationReceipt receipt, {
    bool allowMapOrganization = false,
  }) async {
    final project = _project(session);
    final originalMaps = project.manifest.maps;
    final updatedMaps = receipt.manifest.maps;
    final mapsMatch = allowMapOrganization
        ? originalMaps.length == updatedMaps.length &&
              [
                for (var index = 0; index < originalMaps.length; index++)
                  originalMaps[index].copyWith(
                        groupId: updatedMaps[index].groupId,
                        sortOrder: updatedMaps[index].sortOrder,
                      ) ==
                      updatedMaps[index],
              ].every((unchanged) => unchanged)
        : jsonEncode(originalMaps) == jsonEncode(updatedMaps);
    if (project.revision != receipt.beforeRevision ||
        project.manifest != receipt.before ||
        !mapsMatch) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le reçu ne correspond pas au catalogue ouvert.',
      );
    }
    final next = _ProjectDocument(
      project.root,
      receipt.manifest,
      receipt.revision,
    );
    await _requireProjectRevision(session, next);
    _projects[session.sessionId] = next;
  }

  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async {
    try {
      _projects.clear();
      _loadedPaths.clear();
      await _requireRoot(session);
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: 'project.json',
      );
      final value = decodeNarrativeEventJsonStrict(utf8.decode(bytes));
      if (value is! Map<String, dynamic>) throw const FormatException();
      final project = ProjectManifest.fromJson(value);
      final ids = <String>{};
      final paths = <String>{};
      for (final entry in project.maps) {
        if (!ids.add(entry.id) || !paths.add(entry.relativePath)) {
          throw const FormatException();
        }
      }
      _projects[session.sessionId] = _ProjectDocument(
        session.directoryPath,
        project,
        narrativeEventBytesFingerprint(bytes),
      );
      return project;
    } on MapWorkspaceFailure {
      rethrow;
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Le catalogue du projet ne peut pas être chargé.',
      );
    }
  }

  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    try {
      final project = _project(session);
      if (!project.manifest.maps.contains(entry)) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unsafePath,
          'Cette carte ne figure pas dans le projet ouvert.',
        );
      }
      final path = await _mapPath(session, entry);
      await _requireProjectRevision(session, project);
      final bytes = await _reader.readBytes(
        projectRoot: session.directoryPath,
        relativePath: entry.relativePath,
      );
      final map = decodeValidatedMapDocument(bytes, entry.relativePath);
      if (map.id != entry.id ||
          !buildMapVisualCompositionPlan(map).canCompose) {
        throw const FormatException();
      }
      requireMapDocumentRetention(bytes, map);
      _loadedPaths[(session.sessionId, entry.id)] = path;
      return MapWorkspaceDocument(
        map: map,
        revision: narrativeEventBytesFingerprint(bytes),
        mapId: entry.id,
      );
    } on MapWorkspaceFailure {
      rethrow;
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.invalidDocument,
        'Cette carte est absente, invalide ou utilise un format non pris en charge.',
      );
    }
  }

  @override
  Future<String> saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) => withResourceMutation(() => _saveMap(session, base, current));

  Future<String> _saveMap(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapData current,
  ) async {
    try {
      final project = _project(session);
      final entry = project.manifest.maps.singleWhere(
        (e) => e.id == base.mapId,
      );
      final path = await _mapPath(session, entry);
      if (_loadedPaths[(session.sessionId, entry.id)] != path ||
          base.map.id != entry.id ||
          current.id != entry.id) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unsafePath,
          'La destination de la carte a changé. Votre travail reste ouvert.',
        );
      }
      await _requireProjectRevision(session, project);
      if (!buildMapVisualCompositionPlan(current).canCompose) {
        throw const FormatException();
      }
      MapValidator.validate(current, projectDialogueContext: project.manifest);
      final bytes = encodeMapDocumentBytes(current);
      return await _persistence.write(
        path,
        bytes,
        precondition: MapDocumentWritePrecondition.revision(base.revision),
      );
    } on MapWorkspaceFailure {
      rethrow;
    } on EditorConflictException {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'La carte ou le projet a changé sur le disque. Rien n’a été écrasé ; votre travail reste ouvert.',
      );
    } on Object {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.writeFailed,
        'La carte n’a pas pu être enregistrée. Votre travail reste ouvert.',
      );
    }
  }

  Future<void> _requireProjectRevision(
    ProjectSession session,
    _ProjectDocument project,
  ) async {
    final bytes = await _reader.readBytes(
      projectRoot: session.directoryPath,
      relativePath: 'project.json',
    );
    if (narrativeEventBytesFingerprint(bytes) != project.revision) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le projet a changé sur le disque. Votre travail reste ouvert ; rouvrez le projet pour utiliser sa nouvelle version.',
      );
    }
  }

  _ProjectDocument _project(ProjectSession session) {
    final project = _projects[session.sessionId];
    if (project == null || project.root != session.directoryPath) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unavailable,
        'Le projet doit être ouvert avant de charger une carte.',
      );
    }
    return project;
  }

  Future<void> _requireRoot(ProjectSession session) async {
    final root = session.directoryPath;
    if (root != root.trim() || !p.isAbsolute(root)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le chemin du projet ne peut pas être préservé.',
      );
    }
    final resolved = await Directory(root).resolveSymbolicLinks();
    if (resolved != root || resolved != resolved.trim()) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le dossier du projet a changé depuis son ouverture.',
      );
    }
  }

  Future<String> _mapPath(ProjectSession session, ProjectMapEntry entry) async {
    await _requireRoot(session);
    final relative = entry.relativePath;
    if (relative != relative.trim() ||
        p.isAbsolute(relative) ||
        relative.contains('\\') ||
        relative
            .split('/')
            .any((part) => part.isEmpty || part == '..' || part == '.') ||
        relative.contains('\u0000')) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'Le chemin de cette carte n’est pas sûr.',
      );
    }
    final file = File(p.join(session.directoryPath, relative));
    if (await FileSystemEntity.type(file.path, followLinks: false) !=
        FileSystemEntityType.file) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'La carte doit être un fichier ordinaire du projet.',
      );
    }
    final canonical = await file.resolveSymbolicLinks();
    if (!p.isWithin(session.directoryPath, canonical)) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.unsafePath,
        'La carte pointe en dehors du projet ouvert.',
      );
    }
    return canonical;
  }
}

class _ProjectDocument {
  const _ProjectDocument(this.root, this.manifest, this.revision);

  final String root;
  final ProjectManifest manifest;
  final String revision;
}
