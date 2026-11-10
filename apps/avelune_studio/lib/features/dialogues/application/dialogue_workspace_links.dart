part of 'dialogue_workspace_controller.dart';

extension DialogueWorkspaceLinks on DialogueWorkspaceController {
  Future<bool> connectSelection(
    String id,
    String target, {
    required Future<bool> Function() confirmReplacement,
    bool Function()? isActive,
  }) async {
    final owner = _active;
    if (_closed || owner == null) return false;
    final document = owner.current.document;
    final node = document.nodes
        .where(
          (node) =>
              node.id == id ||
              node.steps.whereType<DeJumpStep>().any((step) => step.id == id),
        )
        .firstOrNull;
    final branch = document.nodes
        .expand(dialogueBranches)
        .where((branch) => branch.id == id)
        .firstOrNull;
    final jumps =
        node?.steps.whereType<DeJumpStep>() ??
        branch?.steps.whereType<DeJumpStep>() ??
        [];
    final destination = document.nodeById(target);
    final replacing = jumps.any(
      (jump) => jump.targetTitle != destination?.title,
    );
    final revision = owner.revision;
    if (replacing && !await confirmReplacement()) return false;
    if (_closed ||
        !(isActive?.call() ?? true) ||
        !identical(_active, owner) ||
        owner.revision != revision) {
      return false;
    }
    return node != null
        ? connectNode(node.id, target, replace: replacing)
        : connect(id, target, replace: replacing);
  }

  bool deleteSelection({
    String? wireId,
    String? branchId,
    String? stepId,
    String? nodeId,
  }) {
    final document = _active?.current.document;
    if (_closed || document == null) return false;
    if (wireId != null) {
      final step = document.nodes
          .expand((node) => dialogueSteps(node.steps))
          .where((step) => step.id == wireId)
          .firstOrNull;
      return step is DeJumpStep ? disconnectJump(wireId) : disconnect(wireId);
    }
    if (branchId != null) return removeResponse(branchId);
    if (stepId != null) return removeStep(stepId);
    if (nodeId != null) return deleteNode(nodeId);
    return false;
  }

  bool connect(String branchId, String targetNodeId, {bool replace = false}) =>
      _edit((v) {
        final branch = _branch(v.document, branchId);
        final target = v.document.nodeById(targetNodeId);
        if (target == null) throw StateError('Destination absente.');
        final jumps = branch.steps.whereType<DeJumpStep>().toList();
        if (jumps.length > 1 ||
            (jumps.isNotEmpty && branch.steps.last != jumps.single)) {
          throw StateError(
            'Réorganisez cette branche avant de modifier son saut : du contenu suit la destination.',
          );
        }
        if (jumps.isNotEmpty &&
            jumps.single.targetTitle != target.title &&
            !replace) {
          throw StateError(
            'Cette réponse possède déjà une destination. Confirmez son remplacement.',
          );
        }
        if (jumps.isEmpty) {
          branch.steps.add(
            DeJumpStep(id: newDialogueEditorId(), targetTitle: target.title),
          );
        } else {
          jumps.single.targetTitle = target.title;
        }
      });
  bool disconnect(String branchId) => _edit((v) {
    _branch(v.document, branchId).steps.removeWhere((s) => s is DeJumpStep);
  });
  bool connectNode(
    String nodeId,
    String targetNodeId, {
    bool replace = false,
  }) => _edit((v) {
    final node = v.document.nodeById(nodeId),
        target = v.document.nodeById(targetNodeId);
    if (node == null || target == null) throw StateError('Suite absente.');
    final jumps = node.steps.whereType<DeJumpStep>().toList();
    if (jumps.length > 1 ||
        (jumps.isNotEmpty && node.steps.last != jumps.single)) {
      throw StateError(
        'Le saut possède du contenu voisin. Réorganisez cette suite explicitement.',
      );
    }
    if (jumps.isNotEmpty &&
        jumps.single.targetTitle != target.title &&
        !replace) {
      throw StateError('Confirmez le remplacement de cette destination.');
    }
    if (jumps.isEmpty) {
      node.steps.add(
        DeJumpStep(id: newDialogueEditorId(), targetTitle: target.title),
      );
    } else {
      jumps.single.targetTitle = target.title;
    }
  });
  bool disconnectJump(String stepId) => _edit((v) {
    if (_step(v.document, stepId) is! DeJumpStep) {
      throw StateError('Ce bloc n’est pas un saut.');
    }
    _stepList(v.document, stepId).removeWhere((s) => s.id == stepId);
  });
  String? addOutcome(String label) {
    final s = _active;
    if (s == null || label.trim().isEmpty) return null;
    final id = availableDialogueOutcomeId(
      label,
      s.current.entry.declaredOutcomes.map((o) => o.id),
    );
    final ok = _edit(
      (_) {},
      metadata: (e) => e.copyWith(
        declaredOutcomes: [
          ...e.declaredOutcomes,
          DialogueDeclaredOutcome(id: id, label: label.trim()),
        ],
      ),
    );
    return ok ? id : null;
  }

  bool assignOutcome(String branchId, String? outcomeId) => _edit((v) {
    if (outcomeId != null &&
        !v.entry.declaredOutcomes.any((o) => o.id == outcomeId)) {
      throw StateError('Déclarez ce résultat avant de l’utiliser.');
    }
    _branch(v.document, branchId).outcomeId = outcomeId;
  });
  bool renameOutcome(String id, String label) => label.trim().isEmpty
      ? _fail('Indiquez un nom de résultat.')
      : _edit(
          (_) {},
          metadata: (e) => e.copyWith(
            declaredOutcomes: [
              for (final o in e.declaredOutcomes)
                if (o.id == id)
                  DialogueDeclaredOutcome(id: id, label: label.trim())
                else
                  o,
            ],
          ),
        );
  bool removeOutcome(String id) {
    final s = _active;
    if (s == null) return false;
    final uses = collectDialogueOutcomeSceneUsages(
      project.copyWith(scenes: [...project.scenes, ...?sceneDrafts?.call()]),
      dialogueId: s.current.entry.id,
      outcomeId: id,
    );
    if (uses.isNotEmpty) {
      return _fail(
        'Résultat utilisé par : ${uses.map((u) => u.sceneId).toSet().join(', ')}.',
      );
    }
    return _edit(
      (v) {
        for (final c
            in v.document.nodes
                .expand((n) => dialogueSteps(n.steps))
                .whereType<DeChoiceStep>()) {
          for (final b in c.branches) {
            if (b.outcomeId == id) b.outcomeId = null;
          }
        }
      },
      metadata: (e) => e.copyWith(
        declaredOutcomes: e.declaredOutcomes.where((o) => o.id != id).toList(),
      ),
    );
  }
}
