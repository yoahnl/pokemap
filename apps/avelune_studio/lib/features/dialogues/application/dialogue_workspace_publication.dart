part of 'dialogue_workspace_controller.dart';

extension DialogueWorkspacePublication on DialogueWorkspaceController {
  Future<bool> create(String name, {String? folderId}) async {
    if (_closed || name.trim().isEmpty) return _fail('Indiquez un nom.');
    final id = narrative.identity('dialogue');
    final entry = ProjectDialogueEntry(
      id: id,
      name: name.trim(),
      relativePath: 'dialogues/$id.yarn',
      folderId: folderId,
      defaultStartNode: 'Start',
    );
    final doc = emptyDialogueDocument();
    _sessions[id] = DialogueWorkingSession(
      DialogueWorkingState(entry, doc),
      null,
    );
    _generation++;
    activeId = id;
    preview = null;
    error = null;
    _loading = false;
    changed();
    return true;
  }

  Future<bool> duplicate(String id) async {
    if (!await open(id)) return false;
    final original = _active!;
    if (original.readOnlyReason != null) return _fail(original.readOnlyReason!);
    final nextId = narrative.identity('dialogue');
    final entry = original.current.entry.copyWith(
      id: nextId,
      name: '${original.current.entry.name} — copie',
      relativePath: 'dialogues/$nextId.yarn',
    );
    _sessions[nextId] = DialogueWorkingSession(
      DialogueWorkingState(
        entry,
        cloneDialogueDocument(original.current.document),
      ),
      null,
    );
    activeId = nextId;
    preview = null;
    changed();
    return true;
  }

  Future<bool> saveAll() async {
    final ids = _sessions.entries
        .where((e) => e.value.dirty)
        .map((e) => e.key)
        .toList();
    final original = activeId;
    try {
      for (final id in ids) {
        if (_closed) return false;
        activeId = id;
        if (!await save()) return false;
      }
      return !dirty;
    } finally {
      if (!_closed) {
        activeId = original;
        changed();
      }
    }
  }

  Future<bool> save() async {
    final s = _active;
    if (_closed || busy || s == null) return false;
    final problem =
        s.readOnlyReason ??
        narrative.dialogueInteractionAccessProblem(s.current.entry.id);
    if (problem != null) return _fail(problem);
    if (!s.dirty) return true;
    final snapshot = s.current.clone();
    final compiled = _compileDocument(snapshot);
    if (!compiled.canPublish) {
      return _fail(compiled.diagnostics.map((d) => d.message).join('\n'));
    }
    final removedTitles = s.base == null
        ? <String>{}
        : parseYarnToDocument(
            s.base!.source,
          ).nodeTitles().difference(snapshot.document.nodeTitles());
    for (final title in removedTitles) {
      final uses = _startUsages(title);
      if (uses.isNotEmpty) {
        return _fail('Entrée supprimée utilisée par : ${uses.join(', ')}.');
      }
    }
    final declared = snapshot.entry.declaredOutcomes.map((o) => o.id).toSet();
    final badUses = collectDialogueOutcomeSceneUsages(
      project.copyWith(scenes: [...project.scenes, ...?sceneDrafts?.call()]),
      dialogueId: snapshot.entry.id,
    ).where((u) => !declared.contains(u.outcomeId)).toList();
    if (badUses.isNotEmpty) {
      return _fail(
        'Résultat utilisé par : ${badUses.map((u) => u.sceneId).toSet().join(', ')}.',
      );
    }
    _publishing.add(s.current.entry.id);
    error = null;
    changed();
    final localBefore = project;
    try {
      final receipt = await port.publish(
        id: snapshot.entry.id,
        base: s.base,
        entry: snapshot.entry,
        source: snapshot.source,
      );
      if (_closed) return false;
      final saved = receipt.snapshot;
      if (saved == null ||
          saved.entry != snapshot.entry ||
          saved.source != snapshot.source) {
        throw const DialogueFailure(
          'Le reçu ne correspond pas au dialogue envoyé ; brouillon conservé.',
        );
      }
      narrative.workspace.acceptResources(
        project == receipt.resources.before
            ? receipt.resources.before
            : localBefore,
        receipt.resources.manifest,
      );
      s.base = saved;
      s.saved = snapshot;
      s.invalidate();
      narrative.invalidateCleanDialogueSessions(snapshot.entry.id);
      onPublished?.call(snapshot.entry.id, saved.revision);
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      _publishing.remove(s.current.entry.id);
      if (!_closed) changed();
    }
  }

  Future<bool> reload() async {
    final id = activeId;
    if (id == null || busy || _closed) return false;
    final previous = _sessions[id];
    if (previous != null) _identities[id] = previous.current.document;
    _sessions.remove(id);
    final ok = await open(id, startNode: previous?.startNode);
    if (!ok && previous != null) {
      _sessions[id] = previous;
      changed();
    }
    return ok;
  }

  Future<bool> delete(String id) async {
    if (_closed || busy) return false;
    if (!await open(id)) return false;
    final s = _active!;
    final uses = [
      for (final scene in [...project.scenes, ...?sceneDrafts?.call()])
        for (final n in scene.graph.nodes)
          if (n.payload case SceneYarnDialoguePayload(:final dialogueId))
            if (dialogueId == id) scene.name,
    ];
    if (uses.isNotEmpty) {
      return _fail('Dialogue utilisé par : ${uses.toSet().join(', ')}.');
    }
    final problem = narrative.dialogueInteractionAccessProblem(id);
    if (problem != null) return _fail(problem);
    if (s.base == null) {
      _sessions.remove(id);
      activeId = null;
      changed();
      return true;
    }
    _publishing.add(s.current.entry.id);
    _deleting.add(id);
    changed();
    final localBefore = project;
    try {
      final receipt = await port.publish(
        id: id,
        base: s.base,
        entry: null,
        source: null,
      );
      if (_closed) return false;
      narrative.workspace.acceptResources(
        project == receipt.resources.before
            ? receipt.resources.before
            : localBefore,
        receipt.resources.manifest,
      );
      _sessions.remove(id);
      if (activeId == id) {
        activeId = null;
        preview = null;
      }
      narrative.invalidateCleanDialogueSessions(id);
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      _publishing.remove(s.current.entry.id);
      _deleting.remove(id);
      if (!_closed) changed();
    }
  }
}
