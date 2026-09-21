part of 'presentation_workspace_controller.dart';

extension PresentationWorkspaceEditing on PresentationWorkspaceController {
  bool apply(String actionId, Map<String, Object?> parameters) =>
      applyBatch([PresentationCommand(actionId, parameters)]);
  bool applyBatch(List<PresentationCommand> commands) {
    final s = _active;
    if (_closed || s == null || _deleting.contains(s.asset.id)) return false;
    if (s.readOnlyReason != null) return _fail(s.readOnlyReason!);
    final before = s.projection.manifest;
    try {
      _adopt(s, s.asset);
      for (final command in commands) {
        if (!command.actionId.startsWith('presentation') ||
            const {
              'presentationCinematic.create',
              'presentationCinematic.duplicate',
              'presentationCinematic.delete',
            }.contains(command.actionId)) {
          throw const PresentationFailure(
            'Cette opération ne modifie pas le document ouvert.',
          );
        }
        final params = {'cinematicId': s.asset.id, ...command.parameters};
        if (params['cinematicId'] != s.asset.id) {
          throw const PresentationFailure('Le document ciblé a changé.');
        }
        s.projection.apply(PresentationCommand(command.actionId, params));
      }
      final asset = s.projection.manifest.presentationCinematics.singleWhere(
        (a) => a.id == s.asset.id,
      );
      if (!_referencesAllow(s, asset)) {
        s.projection.adopt(before);
        return false;
      }
      s.change(asset);
      error = null;
      changed();
      return true;
    } catch (failure) {
      s.projection.adopt(before);
      return _fail(failure);
    }
  }

  bool rename(String title) {
    final s = _active;
    if (s == null) return false;
    return apply('presentationCinematic.update', {
      'title': title.trim(),
      'description': s.asset.description,
      'durationUs': s.asset.durationUs,
    });
  }

  void undo() => _restore(false);
  void redo() => _restore(true);
  void _restore(bool forward) {
    final s = _active;
    if (_closed || s == null || _deleting.contains(s.asset.id)) return;
    final from = forward ? s.redo : s.undo, to = forward ? s.undo : s.redo;
    if (from.isEmpty) return;
    if (!_referencesAllow(s, from.last.$1)) return;
    to.add((s.asset, s.folderId));
    final old = from.removeLast();
    s.asset = old.$1;
    s.folderId = old.$2;
    s.revision++;
    _adopt(s, s.asset);
    error = null;
    changed();
  }

  void _adopt(PresentationWorkingSession s, PresentationCinematicAsset asset) {
    s.projection.adopt(
      project.copyWith(
        presentationCinematics: [
          for (final a in project.presentationCinematics)
            if (a.id != asset.id) a,
          asset,
        ],
        scenes: s.link == null
            ? project.scenes
            : [
                for (final scene in project.scenes)
                  if (scene.id == s.link!.scene.id) s.link!.scene else scene,
              ],
      ),
    );
    s.projection.includeMedia(s.imports);
  }

  Future<PresentationStagedMedia?> importMedia({
    required String sourcePath,
    required String label,
    required ProjectMediaKind kind,
  }) async {
    final s = _active;
    if (_closed || s == null || !_flush()) return null;
    try {
      final media = await port.stageMedia(
        sourcePath: sourcePath,
        label: label,
        kind: kind,
      );
      if (_closed || _sessions[s.asset.id] != s) {
        await port.releaseMedia(media);
        return null;
      }
      s.imports.add(media);
      s.projection.includeMedia(s.imports);
      s.revision++;
      error = null;
      changed();
      return media;
    } catch (failure) {
      _fail(failure);
      return null;
    }
  }
}
