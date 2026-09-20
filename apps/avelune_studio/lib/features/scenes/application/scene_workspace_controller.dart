import 'package:map_core/map_core_domain.dart';
import '../../map_workspace/application/map_workspace_controller.dart';
import '../../narrative/application/narrative_workspace_controller.dart';
import '../domain/scene_port.dart';
import 'scene_edit_session.dart';

class SceneWorkspaceController {
  SceneWorkspaceController(
    this.workspace,
    this.port, {
    this.narrative,
    required this.changed,
  }) {
    narrative?.sceneAccessProblem = _sceneAccessProblem;
    workspace.addListener(_catalogChanged);
  }
  final MapWorkspaceController workspace;
  final ScenePort port;
  final NarrativeWorkspaceController? narrative;
  final void Function() changed;
  final sessions = <String, SceneEditSession>{};
  SceneEditSession? active;
  String? error;
  bool _disposed = false;
  bool get busy => sessions.values.any((session) => session.saving);
  bool get dirty => sessions.values.any((session) => session.dirty);
  ProjectManifest get project => workspace.project!;
  List<SceneAsset> get scenes => {
    for (final scene in project.scenes) scene.id: scene,
    for (final session in sessions.values) session.current.id: session.current,
  }.values.toList();

  void _catalogChanged() {
    if (_reconcileCleanSessions()) changed();
  }

  bool _reconcileCleanSessions() {
    if (_disposed || workspace.isDisposed) return false;
    final persisted = {for (final scene in project.scenes) scene.id: scene};
    var reconciled = false;
    for (final entry in sessions.entries.toList()) {
      final session = entry.value;
      if (session.dirty || session.saving) continue;
      final latest = persisted[entry.key];
      if (latest == null) {
        sessions.remove(entry.key);
        if (identical(active, session)) active = null;
        reconciled = true;
      } else if (session.reconcileClean(latest)) {
        reconciled = true;
      }
    }
    return reconciled;
  }

  String? _sceneAccessProblem(String id) => sessions[id]?.dirty == true
      ? 'Cette scène a un brouillon graphique. Revenez à la scène pour l’enregistrer ou abandonner explicitement ses modifications.'
      : null;

  String? _interactionProblem(String id) {
    if (_disposed || workspace.isDisposed) return 'Le projet est fermé.';
    if (narrative?.saving == true) {
      return 'Une publication narrative est en cours.';
    }
    final pending =
        narrative?.sessions.values.any(
          (session) =>
              session.current.interaction.sceneId == id && session.dirty,
        ) ??
        false;
    return pending
        ? 'Une interaction modifiée utilise cette scène. Revenez à cette interaction pour l’enregistrer ou annuler ses modifications avant d’éditer le graphe.'
        : null;
  }

  bool open(String id) {
    if (_disposed || workspace.isDisposed) return false;
    _reconcileCleanSessions();
    error = _interactionProblem(id);
    if (error != null) {
      changed();
      return false;
    }
    final scene = scenes.where((scene) => scene.id == id).firstOrNull;
    if (scene == null) {
      error = 'Cette scène ne figure plus dans le projet.';
      changed();
      return false;
    }
    active = sessions.putIfAbsent(id, () => _session(scene, base: scene));
    changed();
    return true;
  }

  SceneEditSession? create(String name) {
    if (_disposed || workspace.isDisposed || name.trim().isEmpty) return null;
    try {
      final created = createSceneDraftInProject(
        project.copyWith(scenes: scenes),
        name: name,
      ).createdScene;
      active = _session(created);
      sessions[created.id] = active!;
      error = null;
      changed();
      return active;
    } catch (failure) {
      error = failure.toString();
      changed();
      return null;
    }
  }

  SceneEditSession _session(SceneAsset scene, {SceneAsset? base}) =>
      SceneEditSession(
        scene,
        base: base,
        onChanged: changed,
        canMutate: () => _interactionProblem(scene.id),
      );

  bool discard(String id) {
    if (sessions[id]?.saving == true) return false;
    final removed = sessions.remove(id);
    if (active == removed) active = null;
    changed();
    return removed != null;
  }

  Future<bool> save([SceneEditSession? session]) async {
    final target = session ?? active;
    if (_disposed || workspace.isDisposed || target == null || target.saving) {
      return false;
    }
    if (!target.dirty) return true;
    error = target.error = _interactionProblem(target.current.id);
    if (error != null) {
      changed();
      return false;
    }
    final snapshot = target.current;
    target.saving = true;
    changed();
    try {
      final receipt = await port.publishScene(
        base: target.base,
        current: snapshot,
      );
      if (_disposed ||
          workspace.isDisposed ||
          sessions[snapshot.id] != target) {
        return false;
      }
      workspace.acceptResources(
        receipt.catalog.before,
        receipt.catalog.manifest,
      );
      target.acceptSave(receipt.scene, receipt.catalog.revision);
      narrative?.invalidateCleanSceneSessions(snapshot.id);
      error = target.error = null;
      return true;
    } catch (failure) {
      if (!_disposed && !workspace.isDisposed) {
        error = target.error = failure.toString();
      }
      return false;
    } finally {
      target.saving = false;
      if (!_disposed && !workspace.isDisposed) changed();
    }
  }

  Future<bool> saveAll() async {
    for (final session in sessions.values.toList()) {
      if (session.dirty && !await save(session)) return false;
    }
    return !dirty && !_disposed;
  }

  void dispose() {
    _disposed = true;
    workspace.removeListener(_catalogChanged);
    if (narrative?.sceneAccessProblem == _sceneAccessProblem) {
      narrative?.sceneAccessProblem = null;
    }
  }
}
