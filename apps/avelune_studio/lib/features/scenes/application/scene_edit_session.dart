import 'package:map_core/map_core_domain.dart';

SceneAsset replaceSceneNode(SceneAsset scene, SceneNode node) =>
    SceneAsset.fromJson({
      ...scene.toJson(),
      'graph': {
        ...scene.graph.toJson(),
        'nodes': [
          for (final current in scene.graph.nodes)
            (current.id == node.id ? node : current).toJson(),
        ],
      },
    });

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
  final _dialogueReads = <String, Object>{};

  Object beginDialogueRead(String nodeId) => _dialogueReads[nodeId] = Object();

  bool isCurrentDialogueRead(String nodeId, Object token) =>
      identical(_dialogueReads[nodeId], token);

  void finishDialogueRead(String nodeId, Object token) {
    if (isCurrentDialogueRead(nodeId, token)) _dialogueReads.remove(nodeId);
  }

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

  bool replacePayload(SceneNode node, SceneNodePayload payload) => mutate(
    (scene) => replaceSceneNode(
      scene,
      SceneNode(
        id: node.id,
        kind: node.kind,
        title: node.title,
        description: node.description,
        payload: payload,
      ),
    ),
  );

  Future<bool> retargetDialogue({
    required SceneNode node,
    required SceneYarnDialoguePayload original,
    required ProjectDialogueEntry target,
    required String? start,
    required List<String> outcomes,
    Future<RuntimeDialogueDocument> Function()? read,
    bool Function()? isActive,
  }) async {
    final request = beginDialogueRead(node.id);
    bool currentRequest() =>
        (isActive?.call() ?? true) && isCurrentDialogueRead(node.id, request);
    try {
      if (read == null &&
          original.choicePolicies.isEmpty &&
          original.linePolicies.isEmpty &&
          original.declaredCancellationOutcomes.isEmpty) {
        return replacePayload(
          node,
          SceneYarnDialoguePayload.fromJson({
            ...original.toJson(),
            'dialogueId': target.id,
            'yarnNodeName': start,
            'expectedOutcomes': outcomes,
          }),
        );
      }
      if (read == null) {
        throw StateError('La source du dialogue est indisponible.');
      }
      final compiled = await read();
      if (!currentRequest()) return false;
      final currentNode = current.graph.nodes
          .where((candidate) => candidate.id == node.id)
          .firstOrNull;
      if (currentNode?.payload != original) {
        throw StateError(
          'La scène a changé pendant la lecture du dialogue. Réessayez.',
        );
      }
      return commit(
        retargetSceneDialogue(
          current,
          nodeId: node.id,
          dialogueId: target.id,
          yarnNodeName: start,
          expectedOutcomes: outcomes,
          dialogue: compiled,
        ),
      );
    } catch (_) {
      if (!currentRequest()) return false;
      error = 'Le document est indisponible ou incompatible avec les réglages conservés. Le dialogue et ses réglages n’ont pas été modifiés.';
      onChanged?.call();
      return false;
    } finally {
      finishDialogueRead(node.id, request);
    }
  }

  void cancelDialogueReads() => _dialogueReads.clear();

  bool addOutcome(String name) {
    if (name.trim().isEmpty) return false;
    return mutate((scene) {
      var suffix = scene.declaredOutcomes.length + 1;
      while (scene.declaredOutcomes.any(
        (outcome) => outcome.id == 'result_$suffix',
      )) {
        suffix++;
      }
      return SceneAsset.fromJson({
        ...scene.toJson(),
        'declaredOutcomes': [
          ...scene.declaredOutcomes.map((outcome) => outcome.toJson()),
          SceneOutcome(id: 'result_$suffix', label: name).toJson(),
        ],
      });
    });
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

  String? addAt(
    SceneNodeKind kind, {
    String? title,
    SceneNodePayload? payload,
    required double x,
    required double y,
    String? fromNodeId,
    String? fromPortId,
  }) {
    String? createdId;
    final applied = mutate((scene) {
      late SceneAsset next;
      late SceneNode node;
      if (payload is SceneActionPayload) {
        final action = payload;
        final result = action.consequence != null
            ? addSceneConsequenceActionNodeDraft(
                scene,
                consequence: action.consequence!,
                title: title,
              )
            : addSceneCommandActionNodeDraft(
                scene,
                payload: action,
                title: title,
              );
        next = result.updatedScene;
        node = result.createdNode;
      } else if (payload != null || kind == SceneNodeKind.branchByOutcome) {
        final result = addSceneLinkedAssetNodeDraft(
          scene,
          payload: payload ?? SceneBranchByOutcomePayload(),
          title: title,
        );
        next = result.updatedScene;
        node = result.createdNode;
      } else {
        final result = addSceneNodeDraft(scene, kind: kind, title: title);
        next = result.updatedScene;
        node = result.createdNode;
      }
      next = updateSceneNodeLayout(
        next,
        nodeId: node.id,
        x: x,
        y: y,
      ).updatedScene;
      if (fromNodeId != null && fromPortId != null) {
        next = addSceneEdgeDraft(
          next,
          fromNodeId: fromNodeId,
          fromPortId: fromPortId,
          toNodeId: node.id,
        ).updatedScene;
      }
      createdId = node.id;
      return next;
    });
    return applied ? createdId : null;
  }
}

Map<String, (String, SceneNodePayload)> scenePayloadChoices(
  ProjectManifest project,
  SceneNodeKind kind,
) {
  return <String, (String, SceneNodePayload)>{
    if (kind == SceneNodeKind.yarnDialogue)
      for (final d in project.dialogues)
        d.id: (
          d.name,
          SceneYarnDialoguePayload(
            dialogueId: d.id,
            yarnNodeName: d.defaultStartNode,
            expectedOutcomes: d.declaredOutcomes.map((o) => o.id).toList(),
          ),
        ),
    if (kind == SceneNodeKind.cinematic)
      for (final c in project.cinematics)
        c.id: (c.title, SceneCinematicPayload(cinematicId: c.id)),
    if (kind == SceneNodeKind.presentationCinematic)
      for (final c in project.presentationCinematics)
        c.id: (
          c.title,
          ScenePresentationCinematicPayload(presentationCinematicId: c.id),
        ),
    if (kind == SceneNodeKind.battle)
      for (final t in project.trainers)
        'trainer:${t.id}': (
          t.name,
          SceneBattlePayload(trainerId: t.id, battleKind: 'trainer'),
        ),
    if (kind == SceneNodeKind.battle)
      for (final table in project.encounterTables)
        if (table.tags.contains('studio:unique') &&
            table.entries.length == 1 &&
            table.entries.single.minLevel == table.entries.single.maxLevel)
          'unique:${table.id}': (
            'Rencontre unique : ${table.name}',
            SceneBattlePayload(
              battleKind: 'wild',
              battleTemplateId: table.id,
              declaredOutcomes: const [
                'victory',
                'captured',
                'defeat',
                'runaway',
              ],
            ),
          ),
  };
}
