part of 'cinematic_workspace_controller.dart';

extension CinematicWorkspacePublication on CinematicWorkspaceController {
  Future<bool> create(String title, {String? folderId}) async {
    if (_closed || title.trim().isEmpty) return _fail('Indiquez un nom.');
    final id = narrative.identity('cinematic');
    _sessions[id] = CinematicWorkingSession(
      CinematicAsset(id: id, title: title, timeline: CinematicTimeline()),
      null,
    )..folderId = folderId;
    activeId = id;
    _generation++;
    _loading = false;
    transport.clear();
    error = null;
    changed();
    return true;
  }

  Future<bool> duplicate(String id) async {
    if (!await open(id) || activeId != id) return false;
    final original = _active!;
    final result = duplicateCinematicAsset(
      project.copyWith(cinematics: entries),
      cinematicId: id,
    );
    final clone = result.cinematic;
    final rewrites = <String, String>{
      for (var i = 0; i < original.asset.timeline.steps.length; i++)
        original.asset.timeline.steps[i].id: clone.timeline.steps[i].id,
    };
    final paths =
        original.asset.stageContext?.manualPaths ?? <CinematicManualPath>[];
    final fixed = _withPaths(clone, [
      for (final path in paths)
        path.copyWith(
          ownerActorMoveStepId:
              rewrites[path.ownerActorMoveStepId] ?? path.ownerActorMoveStepId,
        ),
    ]);
    final next = fixed.id;
    _sessions[next] = CinematicWorkingSession(fixed, null)
      ..folderId = original.base?.entry?.folderId ?? original.folderId;
    activeId = next;
    transport.clear();
    error = null;
    changed();
    return true;
  }

  Future<bool> saveAll() async {
    if (flushEdits?.call() == false) return false;
    final ids = _sessions.entries
        .where((e) => e.value.dirty)
        .map((e) => e.key)
        .toList();
    final previous = activeId;
    try {
      for (final id in ids) {
        if (_closed) return false;
        activeId = id;
        if (!await save()) return false;
      }
      return !dirty;
    } finally {
      if (!_closed) {
        activeId = previous;
        changed();
      }
    }
  }

  Future<bool> save() async {
    if (flushEdits?.call() == false) return false;
    final s = _active;
    if (_closed || busy || s == null) return false;
    final problem = narrative.cinematicInteractionAccessProblem(s.asset.id);
    if (problem != null) return _fail(problem);
    if (!s.dirty) return true;
    final snapshot = s.asset, before = project;
    _publishing.add(snapshot.id);
    error = null;
    changed();
    try {
      final receipt = await port.publish(
        id: snapshot.id,
        base: s.base,
        asset: snapshot,
        folderId: s.folderId,
      );
      if (_closed) return false;
      if (receipt.snapshot?.asset != snapshot) {
        throw StateError('Le reçu ne correspond pas à la cinématique envoyée.');
      }
      narrative.workspace.acceptResources(
        project == receipt.resources.before ? receipt.resources.before : before,
        receipt.resources.manifest,
      );
      s.base = receipt.snapshot;
      s.saved = snapshot;
      narrative.invalidateCleanCinematicSessions(snapshot.id);
      onPublished?.call(snapshot.id);
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      _publishing.remove(snapshot.id);
      if (!_closed) changed();
    }
  }

  Future<bool> reload() async {
    final id = activeId;
    if (id == null || busy || _closed) return false;
    final previous = _sessions.remove(id);
    final ok = await open(id);
    if (!ok && previous != null) {
      _sessions[id] = previous;
      changed();
    }
    return ok;
  }

  Future<bool> setArchived(bool archived) async {
    final s = _active;
    if (_closed || busy || s == null) return false;
    if (s.dirty || s.base == null) {
      return _fail('Enregistrez le brouillon avant de changer son archivage.');
    }
    final problem = narrative.cinematicInteractionAccessProblem(s.asset.id);
    if (problem != null) return _fail(problem);
    final id = s.asset.id, before = project;
    _publishing.add(id);
    _deleting.add(id);
    changed();
    try {
      final receipt = await port.setArchived(base: s.base!, archived: archived);
      if (_closed) return false;
      final saved = receipt.snapshot;
      if (saved == null || saved.asset.id != id) {
        throw StateError('Reçu d’archivage invalide.');
      }
      narrative.workspace.acceptResources(
        project == receipt.resources.before ? receipt.resources.before : before,
        receipt.resources.manifest,
      );
      s.base = saved;
      s.saved = saved.asset;
      s.asset = saved.asset;
      narrative.invalidateCleanCinematicSessions(id);
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      _publishing.remove(id);
      _deleting.remove(id);
      if (!_closed) changed();
    }
  }

  Future<bool> delete(String id) async {
    if (_closed || busy || !await open(id) || activeId != id) return false;
    final s = _active!;
    final uses = <String>{
      for (final scene in [...project.scenes, ...?sceneDrafts?.call()])
        for (final n in scene.graph.nodes)
          if (n.payload case SceneCinematicPayload(:final cinematicId))
            if (cinematicId == id) scene.name,
    };
    if (uses.isNotEmpty) {
      return _fail('Cinématique utilisée par : ${uses.join(', ')}.');
    }
    final problem = narrative.cinematicInteractionAccessProblem(id);
    if (problem != null) return _fail(problem);
    if (s.base == null) {
      _sessions.remove(id);
      activeId = null;
      transport.clear();
      changed();
      return true;
    }
    final before = project;
    _publishing.add(id);
    _deleting.add(id);
    changed();
    try {
      final receipt = await port.delete(base: s.base!);
      if (_closed) return false;
      narrative.workspace.acceptResources(
        project == receipt.resources.before ? receipt.resources.before : before,
        receipt.resources.manifest,
      );
      _sessions.remove(id);
      if (activeId == id) {
        activeId = null;
        transport.clear();
      }
      narrative.invalidateCleanCinematicSessions(id);
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      _publishing.remove(id);
      _deleting.remove(id);
      if (!_closed) changed();
    }
  }
}
