import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';

class MapWorkspaceController {
  MapWorkspaceController(this.session, this.port);

  final ProjectSession session;
  final MapWorkspacePort port;
  final Map<String, EditableMapDocument> documents = {};
  final Map<String, Future<EditableMapDocument>> _loading = {};
  final Set<void Function()> _listeners = {};
  ProjectManifest? project;
  EditableMapDocument? active;
  bool loading = false;
  String? error;
  String? Function(MapData before, MapData after)? historyGuard;
  var _generation = 0;
  var _disposed = false;

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

  Future<void> activate(ProjectMapEntry entry) async {
    final generation = ++_generation;
    loading = true;
    error = null;
    notify();
    try {
      final document =
          documents[entry.id] ??
          await _loading.putIfAbsent(
            entry.id,
            () => port.loadMap(session, entry).then(EditableMapDocument.new),
          );
      if (_disposed) return;
      documents[entry.id] = document;
      if (generation == _generation) active = document;
    } catch (failure) {
      if (!_disposed && generation == _generation) error = _message(failure);
    } finally {
      _loading.remove(entry.id);
      if (!_disposed && generation == _generation) {
        loading = false;
        notify();
      }
    }
  }

  Future<bool> save(EditableMapDocument document) async {
    if (_disposed || document.saving) return false;
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
    if (document == null || manifest == null || document.saving) return;
    document.restore(
      redo: redo,
      canRestore: (next) {
        final before = document.current;
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

  void dispose() {
    _disposed = true;
    _generation++;
    _listeners.clear();
  }

  String _message(Object failure) => failure is MapWorkspaceFailure
      ? failure.message
      : 'Impossible de charger ou d’enregistrer cette carte.';
}
