part of 'dialogue_workspace_controller.dart';

extension DialogueWorkspaceCommands on DialogueWorkspaceController {
  bool rename(String name) => name.trim().isEmpty
      ? _fail('Indiquez un nom.')
      : _edit((_) {}, metadata: (e) => e.copyWith(name: name.trim()));
  String? addNode(String title) {
    if (title.trim().isEmpty || title.contains('\n')) {
      _fail('Indiquez un titre de suite sur une ligne.');
      return null;
    }
    String? id;
    _replaceDocument((doc) {
      final next = doc.createNode(title: title);
      id = next.nodes.last.id;
      return next;
    });
    return id;
  }

  bool renameNode(String id, String title) {
    final s = _active;
    if (s == null) return false;
    final old = s.current.document.nodeById(id)?.title;
    if (old == null || title.trim().isEmpty || title.contains('\n')) {
      return _fail('Titre de suite invalide.');
    }
    if (old == title.trim()) return true;
    final uses = _startUsages(old);
    if (uses.isNotEmpty) {
      return _fail(
        'Cette entrée est utilisée par : ${uses.join(', ')}. Modifiez explicitement leurs points de départ.',
      );
    }
    return _replaceDocument(
      (d) => d.renameNode(id, title),
      metadata: (e) => e.defaultStartNode == old
          ? e.copyWith(defaultStartNode: title.trim())
          : e,
    );
  }

  bool deleteNode(String id) {
    final s = _active;
    if (s == null) return false;
    final node = s.current.document.nodeById(id);
    if (node == null) return false;
    final uses = _startUsages(node.title);
    final jumps = s.current.document.nodes
        .where((n) => n.id != id)
        .expand((n) => dialogueSteps(n.steps))
        .whereType<DeJumpStep>()
        .where((j) => j.targetTitle == node.title);
    if (uses.isNotEmpty ||
        jumps.isNotEmpty ||
        s.current.entry.defaultStartNode == node.title) {
      return _fail(
        'Cette suite reste un point de départ ou une destination. Changez ses références avant suppression. ${uses.join(', ')}',
      );
    }
    return _replaceDocument((d) => d.deleteNode(id));
  }

  String? duplicateNode(String id) {
    String? newId;
    final old = _active?.current.document.nodes.map((n) => n.id).toSet() ?? {};
    _replaceDocument((d) {
      final next = d.duplicateNode(id);
      newId = next.nodes.firstWhere((n) => !old.contains(n.id)).id;
      return next;
    });
    return newId;
  }

  bool selectEntry(String id) {
    final node = _active?.current.document.nodeById(id);
    if (node == null) return false;
    return _replaceDocument(
      (d) => d.selectEntryNode(id),
      metadata: (e) => e.copyWith(defaultStartNode: node.title),
    );
  }

  String? addLine(
    String nodeId, {
    String text = '',
    String? speaker,
    bool narration = false,
    int? index,
  }) {
    final id = newDialogueEditorId();
    final ok = _edit((v) {
      final node = v.document.nodeById(nodeId);
      if (node == null) throw StateError('Suite absente.');
      final step = narration
          ? DeNarrationStep(id: id, text: text)
          : DeLineStep(id: id, speaker: speaker, body: text);
      node.steps.insert(
        index == null ? node.steps.length : index.clamp(0, node.steps.length),
        step,
      );
    });
    return ok ? id : null;
  }

  bool updateLine(
    String id, {
    String? text,
    String? speaker,
    String? characterId,
    String? portraitStateId,
    bool clearPortrait = false,
  }) => _edit((v) {
    final step = _step(v.document, id);
    if (step is DeNarrationStep) {
      if (text != null) step.text = text;
      return;
    }
    if (step is! DeLineStep) throw StateError('Sélectionnez une réplique.');
    if (text != null) step.body = text;
    if (speaker != null) step.speaker = speaker.isEmpty ? null : speaker;
    if (clearPortrait) {
      step.characterId = null;
      step.portraitStateId = null;
    }
    if (characterId != null) {
      if (step.characterId != characterId) step.portraitStateId = null;
      step.characterId = characterId.isEmpty ? null : characterId;
    }
    if (portraitStateId != null) {
      step.portraitStateId = portraitStateId.isEmpty ? null : portraitStateId;
    }
  });
  bool removeStep(String id) => _edit((v) {
    final list = _stepList(v.document, id);
    final step = _step(v.document, id);
    if (step is DeStartStep) {
      throw StateError('Changez le point de départ depuis la suite.');
    }
    list.removeWhere((s) => s.id == id);
  });
  String? duplicateStep(String id) {
    String? result;
    _edit((v) {
      final list = _stepList(v.document, id);
      final at = list.indexWhere((s) => s.id == id);
      final copy = cloneDialogueStep(list[at], freshIds: true);
      result = copy.id;
      list.insert(at + 1, copy);
    });
    return result;
  }

  bool moveStep(String id, int delta) => _edit((v) {
    final list = _stepList(v.document, id);
    final from = list.indexWhere((s) => s.id == id);
    final to = (from + delta).clamp(0, list.length - 1);
    if (list[from] is DeStartStep || list[to] is DeStartStep) return;
    final item = list.removeAt(from);
    list.insert(to, item);
  });
  String? addChoice(String nodeId) {
    final id = newDialogueEditorId();
    final ok = _edit((v) {
      final node = v.document.nodeById(nodeId);
      if (node == null) throw StateError('Suite absente.');
      node.steps.add(DeChoiceStep(id: id, branches: []));
    });
    return ok ? id : null;
  }

  String? addResponse(String choiceId, String label) {
    final id = newDialogueEditorId();
    final ok = _edit((v) {
      final choice = _step(v.document, choiceId) as DeChoiceStep;
      choice.branches.add(DeChoiceBranch(id: id, label: label, steps: []));
    });
    return ok ? id : null;
  }

  bool updateResponse(String id, String label) =>
      _edit((v) => _branch(v.document, id).label = label);
  bool reorderResponse(String branchId, int delta) => _edit((v) {
    final choice = v.document.nodes
        .expand((n) => dialogueSteps(n.steps))
        .whereType<DeChoiceStep>()
        .firstWhere((c) => c.branches.any((b) => b.id == branchId));
    final from = choice.branches.indexWhere((b) => b.id == branchId);
    final to = (from + delta).clamp(0, choice.branches.length - 1);
    final item = choice.branches.removeAt(from);
    choice.branches.insert(to, item);
  });
  bool removeResponse(String id) => _edit((v) {
    for (final c
        in v.document.nodes
            .expand((n) => dialogueSteps(n.steps))
            .whereType<DeChoiceStep>()) {
      c.branches.removeWhere((b) => b.id == id);
    }
  });
  List<String> _startUsages(String title) => [
    for (final scene in [...project.scenes, ...?sceneDrafts?.call()])
      for (final node in scene.graph.nodes)
        if (node.payload case SceneYarnDialoguePayload(
          :final dialogueId,
          :final yarnNodeName,
        ))
          if (dialogueId == activeId && yarnNodeName == title)
            '${scene.name} / ${node.title}',
  ];
}
