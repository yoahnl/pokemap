import 'package:map_core/map_core.dart' show ProjectModel3dEntry;

import '../../project_visuals/domain/project_visuals_port.dart';
import 'map_atmosphere_controller.dart';
import 'map_editor_controller.dart';

import 'dart:async';

import '../domain/map_editor_port.dart';
import '../domain/map_atmosphere_port.dart';

import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';

part 'map_workspace_catalog_commands.dart';
part 'map_workspace_catalog_preparation.dart';
part 'map_workspace_history_destinations.dart';
part 'map_workspace_resource_references.dart';
part 'map_workspace_element_order.dart';

class MapWorkspaceController {
  MapWorkspaceController(this.session, this.port, {this.catalogPort})
    : projectScope =
          session.storage == ProjectSessionStorage.workingCatalog &&
              port is MapWorkspaceScopedPort
          ? MapWorkspaceProjectScope.catalogMetadata
          : MapWorkspaceProjectScope.completeProject;

  final ProjectSession session;
  final MapWorkspacePort port;
  final MapCatalogPort? catalogPort;
  final Map<String, EditableMapDocument> documents = {};
  final Map<String, Future<EditableMapDocument>> _loading = {};
  final Map<String, Future<MapData?>> _previews = {};
  final Map<String, EditableMapDocument> retiredDocuments = {};
  final _elementOrderReceipts =
      <String, Map<Object, MapElementOrderWorkspaceReceipt>>{};
  bool catalogBusy = false;
  MapCatalogReceipt? pendingCatalogReceipt;
  String? _catalogTargetId;
  var _catalogEpoch = 0;
  final Map<String, int> _mapEpochs = {};
  final Set<void Function()> _listeners = {};
  ProjectManifest? project;
  MapWorkspaceProjectScope projectScope;
  final Map<String, MapWorkspaceSelection> _selections = {};
  bool get hasCompleteProject =>
      projectScope == MapWorkspaceProjectScope.completeProject;
  ProjectManifest? _visualMapSource;
  ProjectManifest? _visualFamilySource;
  ProjectManifest? _combinedVisuals;
  ProjectManifest? _resourceVisualDefinitions;
  ProjectManifest? get visualProject {
    if (hasCompleteProject) return project;
    final map = _selections[active?.base.mapId]?.definitions ?? project;
    final family = _resourceVisualDefinitions;
    if (map == null || family == null) return map;
    if (!identical(map, _visualMapSource) ||
        !identical(family, _visualFamilySource)) {
      _visualMapSource = map;
      _visualFamilySource = family;
      _combinedVisuals = combineResourceVisuals(map, family);
    }
    return _combinedVisuals;
  }

  EditableMapDocument? active;
  SpatialVisualPatch? _projectVisualProfile;
  final _mapVisualProfiles = <String, SpatialVisualPatch>{};
  void acceptVisualProfile(SpatialVisualPatch profile, {String? mapId}) {
    if (mapId == null) {
      _projectVisualProfile = profile;
    } else {
      _mapVisualProfiles[mapId] = profile;
    }
    final document = active;
    if (document != null && (mapId == null || document.base.mapId == mapId)) {
      document.visualProfile = (_projectVisualProfile ?? SpatialVisualPatch())
          .overriddenBy(
            _mapVisualProfiles[document.base.mapId] ?? SpatialVisualPatch(),
          );
      notify();
    }
  }

  bool loading = false;
  String? error;
  String? Function(MapData before, MapData after)? historyGuard;
  String? Function(String actionId, String targetMapId)?
  catalogDependencyFailure;
  var _generation = 0;
  var _disposed = false;
  bool get isDisposed => _disposed;

  bool get dirty => documents.values.any(
    (document) =>
        document.dirty ||
        document.atmosphere?.dirty == true ||
        document.editor?.dirty == true,
  );
  bool get saving => documents.values.any(
    (document) =>
        document.saving ||
        document.atmosphere?.saving == true ||
        document.editor?.saving == true,
  );
  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  Future<void> initialize() async {
    if (project != null) return;
    try {
      final source = port;
      final manifest = !hasCompleteProject && source is MapWorkspaceScopedPort
          ? (await source.loadCatalog(session)).metadata
          : await port.loadProject(session);
      if (_disposed) return;
      project = manifest;
      notify();
      if (manifest.maps.isNotEmpty) {
        final initial = manifest.newGame.enabled
            ? manifest.maps.singleWhere(
                (entry) => entry.id == manifest.newGame.startMapId,
                orElse: () => throw StateError(
                  'La carte de départ configurée est absente du projet.',
                ),
              )
            : manifest.maps.first;
        await activate(initial);
      }
    } catch (failure) {
      if (!_disposed) {
        error = _message(failure);
        notify();
      }
    }
  }

  final _workshops = <MapWorkspaceWorkshop>{};
  final _workshopLoads = <MapWorkspaceWorkshop, Future<void>>{};
  ProjectManifest? _workshopDefinitions;

  bool hasWorkshop(MapWorkspaceWorkshop workshop) =>
      hasCompleteProject || _workshops.contains(workshop);

  Future<void> ensureWorkshop(MapWorkspaceWorkshop workshop) {
    if (hasWorkshop(workshop) || _disposed) return Future.value();
    return _workshopLoads.putIfAbsent(workshop, () async {
      try {
        if (project == null) await initialize();
        final source = port;
        if (source is! MapWorkspaceWorkshopPort || project == null) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.unavailable,
            'Cet atelier ne dispose pas de lecteur ciblé.',
          );
        }
        final loaded = await source.loadWorkshop(session, workshop);
        if (_disposed) return;
        _workshopDefinitions = workshop.merge(
          _workshopDefinitions ?? project!,
          loaded.metadata,
        );
        project = workshop.merge(project!, loaded.metadata);
        _workshops.add(workshop);
        notify();
      } finally {
        _workshopLoads.remove(workshop);
      }
    });
  }

  String? _resourceKind;
  int _resourceKindRequest = 0;
  int _resourceKindPending = 0;
  Future<void> _resourceKindQueue = Future.value();
  bool hasResourceKind(String kind) =>
      hasCompleteProject || _resourceKind == kind;

  Future<void> ensureResourceKind(String kind) {
    if (_disposed || hasCompleteProject) return Future.value();
    if (hasResourceKind(kind) && _resourceKindPending == 0) {
      return Future.value();
    }
    final request = ++_resourceKindRequest;
    _resourceKindPending++;
    final operation = _resourceKindQueue.then((_) async {
      if (_disposed || request != _resourceKindRequest) return;
      await ensureWorkshop(MapWorkspaceWorkshop.resources);
      final source = port;
      if (source is! MapWorkspaceResourceKindPort) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.unavailable,
          'Cette famille ne dispose pas de lecteur ciblé.',
        );
      }
      final loaded = await (source as MapWorkspaceResourceKindPort)
          .loadResourceKind(session, kind);
      if (_disposed || request != _resourceKindRequest) return;
      final map = _selections[active?.base.mapId]?.definitions ?? project!;
      _resourceVisualDefinitions = null;
      project = mergeResourceSelection(
        project!,
        combineResourceVisuals(_withWorkshops(map), loaded.metadata),
      );
      _resourceKind = kind;
      _resourceVisualDefinitions = loaded.metadata;
      notify();
    });
    _resourceKindQueue = operation.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return operation.whenComplete(() {
      _resourceKindPending--;
    });
  }

  ProjectManifest _withWorkshops(ProjectManifest selection) {
    final loaded = _workshopDefinitions;
    if (loaded == null) return selection;
    var merged = selection;
    for (final workshop in _workshops) {
      merged = workshop.merge(merged, loaded);
    }
    final family = _resourceVisualDefinitions;
    return family == null ? merged : combineResourceVisuals(merged, family);
  }

  Future<void> materializeProject() async {
    if (hasCompleteProject || _disposed) return;
    final source = port;
    if (source is! MapWorkspaceScopedPort) return;
    final complete = await source.materializeProject(session);
    if (_disposed) return;
    project = complete;
    projectScope = MapWorkspaceProjectScope.completeProject;
    _selections.clear();
    notify();
  }

  Future<void> refreshCatalogSelection() async {
    final source = port;
    if (hasCompleteProject || _disposed || source is! MapWorkspaceScopedPort) {
      return;
    }
    final catalog = await source.loadCatalog(session);
    if (_disposed) return;
    _workshopDefinitions = null;
    _resourceKind = null;
    _resourceVisualDefinitions = null;
    for (final workshop in _workshops.toList()) {
      if (source is MapWorkspaceWorkshopPort) {
        final loaded = await source.loadWorkshop(session, workshop);
        if (_disposed) return;
        _workshopDefinitions = workshop.merge(
          _workshopDefinitions ?? catalog.metadata,
          loaded.metadata,
        );
      }
    }
    final document = active;
    final entry = catalog.metadata.maps
        .where((entry) => entry.id == document?.base.mapId)
        .firstOrNull;
    final selection = entry == null
        ? null
        : await source.loadMapSelection(session, entry);
    if (_disposed) return;
    _selections.clear();
    if (selection != null) {
      _selections[entry!.id] = selection;
    }
    project = _withWorkshops(selection?.definitions ?? catalog.metadata);
    projectScope = selection == null
        ? MapWorkspaceProjectScope.catalogMetadata
        : MapWorkspaceProjectScope.mapSelection;
    notify();
  }

  Future<void> activate(
    ProjectMapEntry entry, {
    bool Function()? isCurrent,
  }) async {
    if (_disposed || isCurrent?.call() == false) return;
    if (project != null && !_entryDocumentCurrent(entry)) {
      if (active?.base.mapId == entry.id) active = null;
      error = 'Cette carte ne figure plus dans le projet.';
      notify();
      return;
    }
    final currentEntry =
        project?.maps.where((map) => map.id == entry.id).firstOrNull ?? entry;
    final catalogEpoch = _catalogEpoch;
    final mapEpoch = _mapEpochs[entry.id];
    Future<EditableMapDocument>? pending;
    final generation = ++_generation;
    loading = true;
    error = null;
    notify();
    try {
      final cached = documents[entry.id];
      if (cached == null) {
        pending = _loading.putIfAbsent(entry.id, () async {
          final source = port;
          if (!hasCompleteProject && source is MapWorkspaceScopedPort) {
            final selection = await source.loadMapSelection(
              session,
              currentEntry,
            );
            _selections[entry.id] = selection;
            return _prepareAtmosphere(
              EditableMapDocument(selection.document),
              currentEntry,
            );
          }
          return _prepareAtmosphere(
            EditableMapDocument(await port.loadMap(session, currentEntry)),
            currentEntry,
          );
        });
      }
      final document = cached ?? await pending!;
      final source = port;
      if (cached != null &&
          !hasCompleteProject &&
          source is MapWorkspaceScopedPort &&
          !_selections.containsKey(entry.id)) {
        _selections[entry.id] = await source.loadMapSelection(
          session,
          currentEntry,
        );
      }
      if (_disposed ||
          mapEpoch != _mapEpochs[entry.id] ||
          isCurrent?.call() == false ||
          (catalogEpoch != _catalogEpoch && !_entryDocumentCurrent(entry))) {
        return;
      }
      documents[entry.id] = document;
      if (generation == _generation) {
        active = document;
        document.visualProfile = (_projectVisualProfile ?? SpatialVisualPatch())
            .overriddenBy(_mapVisualProfiles[entry.id] ?? SpatialVisualPatch());
        final selection = _selections[entry.id];
        if (!hasCompleteProject && selection != null) {
          project = _withWorkshops(selection.definitions);
          projectScope = MapWorkspaceProjectScope.mapSelection;
        }
      }
    } catch (failure) {
      if (!_disposed &&
          generation == _generation &&
          mapEpoch == _mapEpochs[entry.id] &&
          isCurrent?.call() != false) {
        error = _message(failure);
      }
    } finally {
      if (identical(_loading[entry.id], pending)) _loading.remove(entry.id);
      if (!_disposed && generation == _generation) {
        loading = false;
        notify();
      }
    }
  }

  Future<EditableMapDocument> _prepareAtmosphere(
    EditableMapDocument document,
    ProjectMapEntry entry,
  ) async {
    final editorPort = port;
    if (editorPort is MapEditorPort) {
      final editor = await MapEditorController.open(
        session,
        entry.id,
        editorPort as MapEditorPort,
      );
      if (_disposed) {
        editor.dispose();
        return document;
      }
      document.editor = editor;
    }
    final atmospherePort = port;
    if (document.current.spatialScene != null &&
        atmospherePort is MapAtmospherePort) {
      final atmosphere = await MapAtmosphereController.open(
        session,
        entry.id,
        atmospherePort as MapAtmospherePort,
      );
      if (_disposed) {
        atmosphere.dispose();
        return document;
      }
      document.atmosphere = atmosphere;
    }
    if (document.current.spatialScene != null && port is ProjectVisualsPort) {
      final visuals = port as ProjectVisualsPort;
      _projectVisualProfile ??= (await visuals.loadVisuals(session)).profile;
      _mapVisualProfiles[entry.id] = (await visuals.loadVisuals(
        session,
        map: entry,
      )).profile;
      document.visualProfile = _projectVisualProfile!.overriddenBy(
        _mapVisualProfiles[entry.id]!,
      );
    }
    return document;
  }

  Future<MapData?> previewMap(String id) {
    if (_disposed) return Future.value(null);
    final entry = project?.maps.where((map) => map.id == id).firstOrNull;
    if (entry == null) return Future.value(null);
    final cached = _previews[id];
    if (cached != null) return cached;
    final mapEpoch = _mapEpochs[id];
    late final Future<MapData?> pending;
    pending = () async {
      try {
        final loaded = await port.loadMap(session, entry);
        if (_disposed ||
            mapEpoch != _mapEpochs[id] ||
            !_entryDocumentCurrent(entry)) {
          return null;
        }
        return loaded.map;
      } on Object {
        if (identical(_previews[id], pending)) _previews.remove(id);
        rethrow;
      }
    }();
    _previews[id] = pending;
    return pending;
  }

  Future<void> refreshSavedMaps(Set<String> mapIds) async {
    if (_disposed || project == null) return;
    final activeId = active?.base.mapId;
    for (final id in mapIds) {
      _previews.remove(id);
      final document = documents[id];
      if (document?.dirty == true || document?.saving == true) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Un brouillon de carte est encore ouvert. Enregistrez-le avant de relier les cartes.',
        );
      }
      final entry = project!.maps.where((map) => map.id == id).firstOrNull;
      if (entry == null) continue;
      final updated = EditableMapDocument(await port.loadMap(session, entry));
      if (_disposed) return;
      updated.atmosphere = document?.atmosphere;
      updated.editor = document?.editor;
      documents[id] = updated;
      if (activeId == id) active = updated;
    }
    notify();
  }

  Future<bool> save(EditableMapDocument document) async {
    if (_disposed || document.saving) return false;
    if (catalogLocks(document.base.mapId)) {
      document.error = 'Une publication du catalogue concerne cette carte.';
      notify();
      return false;
    }
    if (!identical(documents[document.base.mapId], document) ||
        (project != null &&
            !project!.maps.any((entry) => entry.id == document.base.mapId))) {
      document.error = 'Cette carte ne figure plus dans le projet.';
      notify();
      return false;
    }
    if (!await (document.atmosphere?.save() ?? Future.value(true))) {
      return false;
    }
    if (!await (document.editor?.save() ?? Future.value(true))) return false;
    if (!document.dirty) return true;
    document.saving = true;
    document.error = null;
    final snapshot = document.current;
    notify();
    try {
      final revision = await port.saveMap(session, document.base, snapshot);
      if (_disposed) return false;
      document.acceptSave(snapshot, revision);
      final source = port;
      if (!hasCompleteProject && source is MapWorkspaceScopedPort) {
        final entry = project!.maps.singleWhere(
          (entry) => entry.id == document.base.mapId,
        );
        final selection = await source.loadMapSelection(session, entry);
        if (_disposed) return false;
        _selections[entry.id] = selection;
        if (identical(active, document)) {
          project = _withWorkshops(selection.definitions);
        }
      }
      return true;
    } catch (failure) {
      if (!_disposed) document.error = _message(failure);
      return false;
    } finally {
      document.saving = false;
      notify();
    }
  }

  Future<bool> saveAll() async {
    for (final document in documents.values.toList()) {
      if (!await save(document)) return false;
    }
    return !_disposed && !dirty && !saving;
  }

  void restore({required bool redo}) {
    final document = active;
    final manifest = project;
    if (document == null ||
        manifest == null ||
        document.saving ||
        catalogLocks(document.base.mapId) ||
        !manifest.maps.any((entry) => entry.id == document.base.mapId)) {
      return;
    }
    final token = redo ? document.redoToken : document.undoToken;
    final order = _elementOrderReceipts[document.base.mapId]?[token];
    if (order != null &&
        !document.dirty &&
        document.base.revision == order.document.revision) {
      unawaited(_restoreElementOrder(document, order, redo: redo));
      return;
    }
    document.restore(
      redo: redo,
      canRestore: (next) {
        final before = document.current;
        final resourceProblem = _historyResourceProblem(before, next, manifest);
        if (resourceProblem != null) {
          document.error = resourceProblem;
          return false;
        }
        if (_historyHasMissingMapDestination(next, manifest)) {
          document.error =
              'Cette annulation restaurerait une destination supprimée.';
          return false;
        }
        final removed = <(String, String)>[
          for (final entity in before.entities)
            if (!next.entities.any((item) => item.id == entity.id))
              ('entity', entity.id),
          for (final trigger in before.triggers)
            if (!next.triggers.any((item) => item.id == trigger.id))
              ('trigger', trigger.id),
        ];
        final dependencies = buildNarrativeDependencyIndex(
          project: manifest,
          maps: [before],
        );
        final referenced = removed.any(
          (item) => dependencies
              .usagesFor(
                NarrativeDependencyKey.mapSource(
                  mapId: before.id,
                  sourceKind: item.$1,
                  sourceId: item.$2,
                ),
              )
              .isNotEmpty,
        );
        final problem = referenced
            ? 'Cette annulation retirerait un personnage ou une zone utilisé par l’histoire enregistrée.'
            : historyGuard?.call(before, next);
        if (problem != null) {
          document.error = problem;
          return false;
        }
        return true;
      },
    );
    notify();
  }

  Future<void> acceptModelLight(
    ProjectModel3dEntry model,
    String beforeRevision,
    String afterRevision,
  ) async {
    if (_disposed) return;
    final source = port;
    if (source is MapWorkspaceModelLightPort) {
      await (source as MapWorkspaceModelLightPort).acceptModelLight(
        session,
        model,
        beforeRevision,
        afterRevision,
      );
    }
    if (_disposed) return;
    _selections.removeWhere(
      (_, selection) =>
          selection.definitions.models3d.any((value) => value.id == model.id),
    );
    final current = project;
    if (current == null) return;
    acceptResources(
      current,
      current.copyWith(
        models3d: [
          for (final value in current.models3d)
            value.id == model.id
                ? value.copyWith(
                    light: model.light,
                    clearLight: model.light == null,
                  )
                : value,
        ],
      ),
    );
  }

  void acceptResources(ProjectManifest before, ProjectManifest updated) {
    if (_disposed) return;
    if (project != before) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant cette opération.',
      );
    }
    project = updated;
    if (_workshopDefinitions != null) _workshopDefinitions = updated;
    notify();
  }

  void notify() {
    if (_disposed) return;
    for (final listener in List.of(_listeners)) {
      if (_listeners.contains(listener)) listener();
    }
  }

  bool _entryDocumentCurrent(ProjectMapEntry entry) {
    final current = project?.maps
        .where((map) => map.id == entry.id)
        .firstOrNull;
    return current != null &&
        current.relativePath == entry.relativePath &&
        current.name == entry.name;
  }

  void dispose() {
    _disposed = true;
    _generation++;
    _previews.clear();
    for (final document in {...documents.values, ...retiredDocuments.values}) {
      document.atmosphere?.dispose();
      document.editor?.dispose();
    }
    _listeners.clear();
  }
}
