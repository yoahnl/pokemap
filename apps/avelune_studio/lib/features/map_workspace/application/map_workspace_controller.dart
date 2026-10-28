import '../../project_visuals/application/project_visuals_controller.dart';
import 'package:map_core/map_core.dart' show ProjectModel3dEntry, ProjectModel3dEntries;

import '../../project_visuals/domain/project_visuals_port.dart';
import 'map_atmosphere_controller.dart';
import 'map_exterior_decoration_controller.dart';
import 'map_editor_controller.dart';

import 'dart:async';

import '../domain/map_editor_port.dart';
import '../domain/map_atmosphere_port.dart';
import '../domain/map_exterior_decoration_port.dart';

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
  final Map<String, ProjectManifest> _previewDefinitions = {};
  ProjectManifest? previewDefinitionsFor(String mapId) => _previewDefinitions[mapId];
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
  final _selectionMapsByModel = <String, Set<String>>{};
  final _previewMapsByModel = <String, Set<String>>{};
  final _acceptedModelDefinitions = <String, ({int epoch, ProjectModel3dEntry definition})>{};
  int _modelSourceEpoch = 0;
  int modelSourceSelectionsVisited = 0;
  int modelSourcePreviewsVisited = 0;
  int modelSourceProjectionLookups = 0;
  int visualProjectionBuilds = 0;

  ProjectManifest _prepareModelProjection(ProjectManifest value, {int? sourceEpoch}) {
    final entries = ProjectModel3dEntries.prepare(value.models3d);
    final replacements = <ProjectModel3dEntry>[];
    if (sourceEpoch != null && _acceptedModelDefinitions.isNotEmpty) {
      for (final entry in entries) {
        final replacement = _acceptedModelDefinitions[entry.id];
        if (replacement != null && replacement.epoch > sourceEpoch && !identical(entry, replacement.definition)) {
          replacements.add(replacement.definition);
        }
      }
    }
    final models = replacements.isEmpty ? entries : entries.replaceSelected(replacements);
    return identical(models, value.models3d) ? value : value.copyWith(models3d: models);
  }

  ProjectManifest _replaceModelProjection(ProjectManifest value, Map<String, ProjectModel3dEntry> changed) {
    final entries = value.models3d as ProjectModel3dEntries;
    final replacements = <ProjectModel3dEntry>[];
    for (final replacement in changed.values) {
      modelSourceProjectionLookups++;
      final previous = entries.lookup(replacement.id);
      if (previous != null && !identical(previous, replacement)) replacements.add(replacement);
    }
    return replacements.isEmpty ? value : value.copyWith(models3d: entries.replaceSelected(replacements));
  }

  MapWorkspaceSelection _selectionWithDefinitions(MapWorkspaceSelection selection, ProjectManifest definitions) =>
      identical(selection.definitions, definitions) ? selection : MapWorkspaceSelection(
        document: selection.document, definitions: definitions,
        catalogRevision: selection.catalogRevision, snapshotRevision: selection.snapshotRevision,
      );

  void _indexModelProjection(String mapId, ProjectManifest? previous, ProjectManifest next, Map<String, Set<String>> index) {
    if (previous != null) {
      for (final model in previous.models3d) {
        final maps = index[model.id];
        maps?.remove(mapId);
        if (maps?.isEmpty == true) index.remove(model.id);
      }
    }
    for (final model in next.models3d) {
      (index[model.id] ??= {}).add(mapId);
    }
  }

  void _cacheSelection(String mapId, MapWorkspaceSelection selection, int sourceEpoch) {
    final definitions = _prepareModelProjection(selection.definitions, sourceEpoch: sourceEpoch);
    _indexModelProjection(mapId, _selections[mapId]?.definitions, definitions, _selectionMapsByModel);
    _selections[mapId] = _selectionWithDefinitions(selection, definitions);
  }

  void _cachePreviewDefinitions(String mapId, ProjectManifest value, int sourceEpoch) {
    final definitions = _prepareModelProjection(value, sourceEpoch: sourceEpoch);
    _indexModelProjection(mapId, _previewDefinitions[mapId], definitions, _previewMapsByModel);
    _previewDefinitions[mapId] = definitions;
  }

  void _clearSelections() {
    _selections.clear();
    _selectionMapsByModel.clear();
  }

  Map<String, Map<String, ProjectModel3dEntry>> _dependentModelChanges(
    Map<String, ProjectModel3dEntry> changed, Map<String, Set<String>> index,
  ) {
    final result = <String, Map<String, ProjectModel3dEntry>>{};
    for (final model in changed.values) {
      for (final mapId in index[model.id] ?? const <String>{}) {
        (result[mapId] ??= {})[model.id] = model;
      }
    }
    return result;
  }

  bool get hasCompleteProject =>
      projectScope == MapWorkspaceProjectScope.completeProject;
  ProjectManifest? _visualMapSource;
  ProjectManifest? _visualFamilySource;
  ProjectManifest? _combinedVisuals;
  ProjectManifest? _resourceVisualDefinitions;
  ProjectManifest? get visualProject {
    if (hasCompleteProject) return project == null ? null : _withSurfConfiguration(project!);
    final map = _selections[active?.base.mapId]?.definitions ?? project;
    final family = _resourceVisualDefinitions;
    if (map == null || family == null) return map == null ? null : _withSurfConfiguration(map);
    if (!identical(map, _visualMapSource) ||
        !identical(family, _visualFamilySource)) {
      _cacheVisualComposition(map, family);
    }
    return _combinedVisuals == null ? null : _withSurfConfiguration(_combinedVisuals!);
  }

  void _cacheVisualComposition(ProjectManifest map, ProjectManifest family) {
    _visualMapSource = map;
    _visualFamilySource = family;
    _combinedVisuals = _prepareModelProjection(combineResourceVisuals(map, family));
    visualProjectionBuilds++;
  }

  ProjectSurfSettings? _acceptedSurfConfiguration;
  ProjectFieldAbilitiesSettings? _acceptedFieldAbilities;
  ProjectAudioSettings? _acceptedAudio;
  bool _surfConfigurationAccepted = false,
      _fieldAbilitiesAccepted = false,
      _audioAccepted = false;
  Expando<ProjectManifest> _surfProjections = Expando<ProjectManifest>();

  ProjectManifest _withSurfConfiguration(ProjectManifest value) {
    final settings = value.settings;
    final updated = settings.copyWith(
      surf: _surfConfigurationAccepted
          ? _acceptedSurfConfiguration
          : settings.surf,
      fieldAbilities: _fieldAbilitiesAccepted
          ? _acceptedFieldAbilities
          : settings.fieldAbilities,
      audio: _audioAccepted ? _acceptedAudio : settings.audio,
    );
    if (settings == updated) return value;
    return _surfProjections[value] ??= value.copyWith(settings: updated);
  }

  void _acceptSettingsProjection(bool notifyChange) {
    if (_disposed) return;
    _surfProjections = Expando<ProjectManifest>();
    if (project case final current?) project = _withSurfConfiguration(current);
    if (notifyChange) notify();
  }

  void acceptSurfConfiguration(
    ProjectSurfSettings? configuration, {
    bool notifyChange = true,
  }) {
    if (_disposed) return;
    _surfConfigurationAccepted = true;
    _acceptedSurfConfiguration = configuration;
    _acceptSettingsProjection(notifyChange);
  }

  void acceptFieldAbilities(
    ProjectFieldAbilitiesSettings? configuration, {
    bool notifyChange = true,
  }) {
    if (_disposed) return;
    _fieldAbilitiesAccepted = true;
    _acceptedFieldAbilities = configuration;
    _acceptSettingsProjection(notifyChange);
  }

  void acceptAudio(
    ProjectAudioSettings? configuration, {
    bool notifyChange = true,
  }) {
    if (_disposed) return;
    _audioAccepted = true;
    _acceptedAudio = configuration;
    _acceptSettingsProjection(notifyChange);
  }

  EditableMapDocument? active;
  SpatialVisualPatch? _projectVisualProfile;
  SpatialVisualPatch get inheritedVisualProfile => _projectVisualProfile ?? SpatialVisualPatch();
  ProjectVisualsController? weatherDraftFor(EditableMapDocument document) {
    if (document.weatherVisuals case final existing?) return existing;
    final source = port;
    if (source is! ProjectVisualsPort) return null;
    final entry = project?.maps.where((map) => map.id == document.base.mapId).firstOrNull;
    if (entry == null) return null;
    final owner = ProjectVisualsController(session: session, port: source as ProjectVisualsPort);
    document.weatherVisuals = owner;
    var attached = false;
    owner.addListener(() {
      if (_disposed || owner.saved == null) return;
      if (!owner.dirty) _mapVisualProfiles[entry.id] = owner.preview.value;
      document.visualProfile = inheritedVisualProfile.overriddenBy(owner.preview.value);
      if (!attached) {
        attached = true;
        notify();
      }
    });
    unawaited(Future<void>(() async {
      if (!_disposed) await owner.open(map: entry);
    }));
    return owner;
  }
  final _mapVisualProfiles = <String, SpatialVisualPatch>{};
  void acceptVisualProfile(SpatialVisualPatch profile, {String? mapId}) {
    if (mapId == null) {
      _projectVisualProfile = profile;
    } else {
      _mapVisualProfiles[mapId] = profile;
      final owner = documents[mapId]?.weatherVisuals;
      if (owner != null && !owner.dirty && !owner.saving && owner.saved != null && owner.preview.value != profile) {
        unawaited(owner.open(map: owner.scope));
      }
    }
    final document = active;
    if (document != null && (mapId == null || document.base.mapId == mapId)) {
      document.visualProfile = (_projectVisualProfile ?? SpatialVisualPatch())
          .overriddenBy(
            document.weatherVisuals?.preview.value ?? _mapVisualProfiles[document.base.mapId] ?? SpatialVisualPatch(),
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
        document.exteriorDecoration?.dirty == true ||
        document.weatherVisuals?.dirty == true ||
        document.editor?.dirty == true,
  );
  bool get saving => documents.values.any(
    (document) =>
        document.saving ||
        document.atmosphere?.saving == true ||
        document.exteriorDecoration?.saving == true ||
        document.weatherVisuals?.saving == true ||
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
      project = _prepareModelProjection(manifest);
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
        final sourceEpoch = _modelSourceEpoch;
        final loaded = await source.loadWorkshop(session, workshop);
        if (_disposed) return;
        _workshopDefinitions = _prepareModelProjection(workshop.merge(
          _workshopDefinitions ?? project!,
          _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch),
        ));
        project = _prepareModelProjection(workshop.merge(project!, _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch)));
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
      final sourceEpoch = _modelSourceEpoch;
      final loaded = await (source as MapWorkspaceResourceKindPort)
          .loadResourceKind(session, kind);
      if (_disposed || request != _resourceKindRequest) return;
      final map = _selections[active?.base.mapId]?.definitions ?? project!;
      _resourceVisualDefinitions = null;
      project = _prepareModelProjection(mergeResourceSelection(
        project!,
        combineResourceVisuals(_withWorkshops(map), _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch)),
      ));
      _resourceKind = kind;
      _resourceVisualDefinitions = _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch);
      _cacheVisualComposition(map, _resourceVisualDefinitions!);
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
    if (loaded == null) return _withSurfConfiguration(selection);
    var merged = selection;
    for (final workshop in _workshops) {
      merged = workshop.merge(merged, loaded);
    }
    final family = _resourceVisualDefinitions;
    return _withSurfConfiguration(_prepareModelProjection(family == null ? merged : combineResourceVisuals(merged, family)));
  }

  Future<void> materializeProject() async {
    if (hasCompleteProject || _disposed) return;
    final source = port;
    if (source is! MapWorkspaceScopedPort) return;
    final sourceEpoch = _modelSourceEpoch;
    final complete = await source.materializeProject(session);
    if (_disposed) return;
    project = _prepareModelProjection(complete, sourceEpoch: sourceEpoch);
    projectScope = MapWorkspaceProjectScope.completeProject;
    _clearSelections();
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
        final sourceEpoch = _modelSourceEpoch;
        final loaded = await source.loadWorkshop(session, workshop);
        if (_disposed) return;
        _workshopDefinitions = _prepareModelProjection(workshop.merge(
          _workshopDefinitions ?? catalog.metadata,
          _prepareModelProjection(loaded.metadata, sourceEpoch: sourceEpoch),
        ));
      }
    }
    final document = active;
    final entry = catalog.metadata.maps
        .where((entry) => entry.id == document?.base.mapId)
        .firstOrNull;
    final sourceEpoch = _modelSourceEpoch;
    final selection = entry == null
        ? null
        : await source.loadMapSelection(session, entry);
    if (_disposed) return;
    _clearSelections();
    if (selection != null) {
      _cacheSelection(entry!.id, selection, sourceEpoch);
    }
    project = _withWorkshops(_selections[entry?.id]?.definitions ?? _prepareModelProjection(catalog.metadata));
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
            final sourceEpoch = _modelSourceEpoch;
            final selection = await source.loadMapSelection(
              session,
              currentEntry,
            );
            _cacheSelection(entry.id, selection, sourceEpoch);
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
        final sourceEpoch = _modelSourceEpoch;
        final selection = await source.loadMapSelection(session, currentEntry);
        _cacheSelection(entry.id, selection, sourceEpoch);
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
            .overriddenBy(document.weatherVisuals?.preview.value ?? _mapVisualProfiles[entry.id] ?? SpatialVisualPatch());
        final selection = _selections[entry.id];
        if (!hasCompleteProject && selection != null) {
          project = _withWorkshops(_selections[entry.id]!.definitions);
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
    if (document.current.spatialScene != null && port is MapExteriorDecorationPort) {
      final exterior = await MapExteriorDecorationController.open(session,document.current,port as MapExteriorDecorationPort);
      if (_disposed) { exterior.dispose(); return document; }
      if(exterior.available){document.exteriorDecoration = exterior;}else{exterior.dispose();}
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
        final previewPort = port;
        final sourceEpoch = _modelSourceEpoch;
        final selection = previewPort is MapWorkspacePreviewSelectionPort ? await (previewPort as MapWorkspacePreviewSelectionPort).loadMapPreviewSelection(session, entry) : null;
        final loaded = selection?.document ?? await port.loadMap(session, entry);
        if (_disposed ||
            mapEpoch != _mapEpochs[id] ||
            !_entryDocumentCurrent(entry)) {
          return null;
        }
        if (selection != null) _cachePreviewDefinitions(id, selection.definitions, sourceEpoch);
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
      updated.exteriorDecoration = document?.exteriorDecoration;
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
    if (!await (document.weatherVisuals?.save() ?? Future.value(true))) return false;
    if (!await (document.atmosphere?.save() ?? Future.value(true))) {
      return false;
    }
    if (!await (document.editor?.save() ?? Future.value(true))) return false;
    if (!await (document.exteriorDecoration?.save() ?? Future.value(true))) return false;
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
        final sourceEpoch = _modelSourceEpoch;
        final selection = await source.loadMapSelection(session, entry);
        if (_disposed) return false;
        _cacheSelection(entry.id, selection, sourceEpoch);
        if (identical(active, document)) {
          project = _withWorkshops(_selections[entry.id]!.definitions);
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
    final exterior = document.exteriorDecoration;
    if (exterior?.editingExterior == true) {
      if (redo) { exterior!.redo(); } else { exterior!.undo(); }
      notify();
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
    final current = project;
    if (current == null) return;
    final entries = current.models3d as ProjectModel3dEntries;
    final previous = entries.lookup(model.id);
    if (previous == null) return;
    final replacement = previous.copyWith(light: model.light, clearLight: model.light == null);
    acceptResources(current, current.copyWith(models3d: entries.replaceSelected([replacement])),
      changedModels: {model.id: replacement});
  }

  void acceptResources(ProjectManifest before, ProjectManifest updated, {
    Map<String, ProjectModel3dEntry> changedModels = const {},
  }) {
    if (_disposed) return;
    if (changedModels.isEmpty) {
      if (project != before) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé pendant cette opération.',
        );
      }
      project = _prepareModelProjection(updated);
      if (_workshopDefinitions != null) _workshopDefinitions = project;
    } else {
      final current = project;
      final currentModels = current?.models3d;
      final beforeModels = before.models3d;
      if (current == null || currentModels is! ProjectModel3dEntries ||
          beforeModels is! ProjectModel3dEntries) {
        throw const MapWorkspaceFailure(
          MapWorkspaceProblem.conflict,
          'Le catalogue a changé pendant cette opération.',
        );
      }
      for (final change in changedModels.entries) {
        final existing = currentModels.lookup(change.key);
        if (change.key != change.value.id ||
            (existing != null && existing != beforeModels.lookup(change.key) &&
                existing != change.value)) {
          throw const MapWorkspaceFailure(
            MapWorkspaceProblem.conflict,
            'Le catalogue a changé pendant cette opération.',
          );
        }
      }
      final sourceEpoch = ++_modelSourceEpoch;
      for (final entry in changedModels.entries) {
        _acceptedModelDefinitions[entry.key] = (epoch: sourceEpoch, definition: entry.value);
      }
      for (final change in _dependentModelChanges(changedModels, _selectionMapsByModel).entries) {
        modelSourceSelectionsVisited++;
        final selection = _selections[change.key]!;
        _selections[change.key] = _selectionWithDefinitions(selection,
          _replaceModelProjection(selection.definitions, change.value));
      }
      for (final change in _dependentModelChanges(changedModels, _previewMapsByModel).entries) {
        modelSourcePreviewsVisited++;
        _previewDefinitions[change.key] = _replaceModelProjection(_previewDefinitions[change.key]!, change.value);
      }
      project = _replaceModelProjection(current, changedModels);
      if (_workshopDefinitions case final definitions?) {
        _workshopDefinitions = _replaceModelProjection(definitions, changedModels);
      }
      if (_resourceVisualDefinitions case final definitions?) {
        _resourceVisualDefinitions = _replaceModelProjection(definitions, changedModels);
      }
      if (_combinedVisuals case final definitions?) {
        _combinedVisuals = _replaceModelProjection(definitions, changedModels);
        _visualMapSource = _selections[active?.base.mapId]?.definitions ?? project;
        _visualFamilySource = _resourceVisualDefinitions;
      }
    }
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
    _previewDefinitions.clear();
    _previewMapsByModel.clear();
    _clearSelections();
    _acceptedModelDefinitions.clear();
    for (final document in {...documents.values, ...retiredDocuments.values}) {
      document.weatherVisuals?.dispose();
      document.atmosphere?.dispose();
      document.exteriorDecoration?.dispose();
      document.editor?.dispose();
    }
    _listeners.clear();
  }
}
