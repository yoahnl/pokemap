import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_catalog_port.dart';

part 'map_workspace_catalog_commands.dart';
part 'map_workspace_catalog_preparation.dart';
part 'map_workspace_history_destinations.dart';

class MapWorkspaceController {
  MapWorkspaceController(this.session, this.port, {this.catalogPort});

  final ProjectSession session;
  final MapWorkspacePort port;
  final MapCatalogPort? catalogPort;
  final Map<String, EditableMapDocument> documents = {};
  final Map<String, Future<EditableMapDocument>> _loading = {};
  final Map<String, Future<MapData?>> _previews = {};
  final Map<String, EditableMapDocument> retiredDocuments = {};
  bool catalogBusy = false;
  MapCatalogReceipt? pendingCatalogReceipt;
  String? _catalogTargetId;
  var _catalogEpoch = 0;
  final Map<String, int> _mapEpochs = {};
  final Set<void Function()> _listeners = {};
  ProjectManifest? project;
  EditableMapDocument? active;
  bool loading = false;
  String? error;
  String? Function(MapData before, MapData after)? historyGuard;
  String? Function(String actionId, String targetMapId)?
  catalogDependencyFailure;
  var _generation = 0;
  var _disposed = false;
  bool get isDisposed => _disposed;

  bool get dirty => documents.values.any((document) => document.dirty);
  bool get saving => documents.values.any((document) => document.saving);
  void addListener(void Function() listener) => _listeners.add(listener);
  void removeListener(void Function() listener) => _listeners.remove(listener);

  Future<void> initialize() async {
    if (project != null) return;
    try {
      final manifest = await port.loadProject(session);
      if (_disposed) return;
      project = manifest;
      notify();
      if (manifest.maps.isNotEmpty) await activate(manifest.maps.first);
    } catch (failure) {
      if (!_disposed) {
        error = _message(failure);
        notify();
      }
    }
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
        pending = _loading.putIfAbsent(
          entry.id,
          () =>
              port.loadMap(session, currentEntry).then(EditableMapDocument.new),
        );
      }
      final document = cached ?? await pending!;
      if (_disposed ||
          mapEpoch != _mapEpochs[entry.id] ||
          isCurrent?.call() == false ||
          (catalogEpoch != _catalogEpoch && !_entryDocumentCurrent(entry))) {
        return;
      }
      documents[entry.id] = document;
      if (generation == _generation) active = document;
    } catch (failure) {
      if (!_disposed &&
          generation == _generation &&
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
    if (!document.dirty) return true;
    document.saving = true;
    document.error = null;
    final snapshot = document.current;
    notify();
    try {
      final revision = await port.saveMap(session, document.base, snapshot);
      if (_disposed) return false;
      document.acceptSave(snapshot, revision);
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

  void acceptResources(ProjectManifest before, ProjectManifest updated) {
    if (_disposed) return;
    if (project != before) {
      throw const MapWorkspaceFailure(
        MapWorkspaceProblem.conflict,
        'Le catalogue a changé pendant cette opération.',
      );
    }
    project = updated;
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
    _listeners.clear();
  }
}
