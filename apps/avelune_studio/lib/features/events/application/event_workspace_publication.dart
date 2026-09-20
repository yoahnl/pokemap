part of 'event_workspace_controller.dart';

extension EventWorkspacePublication on EventWorkspaceController {
  Future<bool> _flushAndPublish() async {
    if (_closed || busy) return false;
    try {
      await flushEdits?.call();
      if (_closed) return false;
      return await _publish();
    } catch (failure) {
      if (!_closed) _fail(failure.toString());
      return false;
    }
  }

  Future<bool> changeMode(EventSystemMode mode) async {
    if (_closed || busy) return false;
    try {
      await flushEdits?.call();
    } catch (failure) {
      if (!_closed) _fail(failure.toString());
      return false;
    }
    if (_closed || busy) return false;
    if (dirty ||
        narrative.saving ||
        narrative.sessions.values.any((s) => s.dirty)) {
      return _fail(
        'Enregistrez les brouillons d’événements et d’interactions avant de changer le mode du registre.',
      );
    }
    final gateway = port;
    if (gateway is! EventRegistryModePort) {
      return _fail('Le changement de mode est indisponible.');
    }
    busy = true;
    _publishing.addAll(records.map((r) => r.id));
    changed();
    try {
      final localBefore = workspace.project!;
      final receipt = await (gateway as EventRegistryModePort).changeMode(
        base: narrative.project.eventRegistry,
        mode: mode,
      );
      if (_closed) return false;
      workspace.acceptResources(
        workspace.project == receipt.before ? receipt.before : localBefore,
        receipt.manifest,
      );
      error = null;
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      busy = false;
      _publishing.clear();
      if (!_closed) {
        reconcile();
        changed();
      }
    }
  }

  Future<bool> _publish() async {
    if (_closed || busy || narrative.saving) return false;
    reconcile();
    if (!dirty) return true;
    final snapshot = Map.of(_pending);
    final ordered = _publicationOrder(snapshot);
    if (ordered == null) {
      return _fail(
        'Les événements à enregistrer forment un cycle de dépendances.',
      );
    }
    _publishing.addAll(snapshot.keys);
    busy = true;
    error = null;
    changed();
    var saved = 0;
    try {
      for (final id in ordered) {
        final entry = MapEntry(id, snapshot[id]);
        final problem = narrative.interactionAccessProblem(entry.key);
        if (problem != null) throw EventFailure(problem);
        final localBefore = workspace.project!;
        final receipt = await port.publishEvent(
          id: entry.key,
          base: _bases[entry.key],
          current: entry.value,
        );
        if (_closed) return false;
        final desired = record(entry.key);
        _bases[entry.key] = entry.value;
        workspace.acceptResources(
          workspace.project == receipt.before ? receipt.before : localBefore,
          receipt.manifest,
        );
        if (desired == entry.value) {
          _pending.remove(entry.key);
        } else {
          _pending[entry.key] = desired;
        }
        saved++;
      }
      return !dirty;
    } catch (failure) {
      if (!_closed) {
        error =
            '${saved == 0 ? '' : '$saved événement(s) enregistré(s). Les autres brouillons restent ouverts. '}$failure';
      }
      return false;
    } finally {
      busy = false;
      _publishing.clear();
      if (!_closed) {
        reconcile();
        changed();
      }
    }
  }

  Future<bool> _reload(String id) async {
    if (_closed || busy || narrative.saving) return false;
    final expected = record(id);
    final previous = workspace.project;
    if (previous == null) return false;
    busy = true;
    changed();
    try {
      final latest = await workspace.port.loadProject(workspace.session);
      if (_closed) return false;
      if (record(id) != expected || workspace.project != previous) {
        throw const EventFailure(
          'Le brouillon a changé pendant la lecture ; il est conservé.',
        );
      }
      workspace.acceptResources(previous, latest);
      _pending.remove(id);
      _bases[id] = _stored(id);
      _invalidate(id);
      if (_stored(id) == null && activeId == id) activeId = null;
      error = null;
      return true;
    } catch (failure) {
      if (!_closed) error = failure.toString();
      return false;
    } finally {
      busy = false;
      if (!_closed) {
        reconcile();
        changed();
      }
    }
  }
}
