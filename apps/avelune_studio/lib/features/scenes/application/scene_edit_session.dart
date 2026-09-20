import 'package:map_core/map_core_domain.dart';

class SceneEditSession {
  SceneEditSession(this.current, {this.base, this.onChanged, this.canMutate});
  SceneAsset current;
  SceneAsset? base;
  SceneAsset? get saved => base;
  final void Function()? onChanged;
  final String? Function()? canMutate;
  static const historyLimit = 64;
  final _undo = <SceneAsset>[];
  final _redo = <SceneAsset>[];
  int revision = 0;
  String? savedRevision;
  String? error;
  bool saving = false;
  bool get dirty => current != base;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;
  int get undoCount => _undo.length;

  bool mutate(SceneAsset Function(SceneAsset) operation) {
    try {
      return commit(operation(current));
    } catch (failure) {
      error = failure.toString();
      onChanged?.call();
      return false;
    }
  }

  bool commit(SceneAsset next) {
    final problem = canMutate?.call();
    if (problem != null || next.id != current.id) {
      error = problem ?? 'L’identité de la scène ne peut pas changer.';
      onChanged?.call();
      return false;
    }
    if (next == current) return false;
    _undo.add(current);
    if (_undo.length > historyLimit) _undo.removeAt(0);
    _redo.clear();
    current = next;
    revision++;
    error = null;
    onChanged?.call();
    return true;
  }

  void restore({required bool redo}) {
    final problem = canMutate?.call();
    if (problem != null) {
      error = problem;
      onChanged?.call();
      return;
    }
    final source = redo ? _redo : _undo;
    if (source.isEmpty) return;
    (redo ? _undo : _redo).add(current);
    current = source.removeLast();
    revision++;
    error = null;
    onChanged?.call();
  }

  void acceptSave(SceneAsset snapshot, String projectRevision) {
    base = snapshot;
    savedRevision = projectRevision;
  }

  bool reconcileClean(SceneAsset published) {
    if (dirty || saving || published.id != current.id || published == current) {
      return false;
    }
    current = base = published;
    _undo.clear();
    _redo.clear();
    savedRevision = null;
    error = null;
    revision++;
    return true;
  }

  bool rename(String name) => mutate((scene) {
    if (name.trim().isEmpty) throw ArgumentError('Le nom est requis.');
    return SceneAsset.fromJson({...scene.toJson(), 'name': name.trim()});
  });

  bool move(String nodeId, double x, double y) => mutate(
    (scene) =>
        updateSceneNodeLayout(scene, nodeId: nodeId, x: x, y: y).updatedScene,
  );

  bool connect(String fromNodeId, String portId, String toNodeId) => mutate(
    (scene) => addSceneEdgeDraft(
      scene,
      fromNodeId: fromNodeId,
      fromPortId: portId,
      toNodeId: toNodeId,
    ).updatedScene,
  );

  bool disconnect(String edgeId) =>
      mutate((scene) => removeSceneEdgeDraft(scene, edgeId).updatedScene);

  bool delete(String nodeId) =>
      mutate((scene) => removeSceneNodeDraft(scene, nodeId).updatedScene);

  bool duplicate(String nodeId) =>
      mutate((scene) => duplicateSceneNodeDraft(scene, nodeId).updatedScene);

  bool add(SceneNodeKind kind, {String? title}) => mutate(
    (scene) => addSceneNodeDraft(scene, kind: kind, title: title).updatedScene,
  );
}
