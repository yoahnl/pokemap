part of 'presentation_workspace_controller.dart';

extension PresentationWorkspaceLibrary on PresentationWorkspaceController {
  bool setFolder(String id, String? folderId) {
    final s = _sessions[id];
    if (_closed || !_flush() || s == null || _deleting.contains(id)) {
      return false;
    }
    if (folderId != null &&
        !catalog.folders.any(
          (f) =>
              f.id == folderId &&
              f.family == CinematicLibraryFamily.presentation,
        )) {
      return _fail('Dossier de présentations introuvable.');
    }
    if (s.folderId != folderId) {
      s.undo.add((s.asset, s.folderId));
      s.redo.clear();
      s.folderId = folderId;
      s.revision++;
    }
    error = null;
    changed();
    return true;
  }

  Future<String?> createFolder(String name, {String? parentFolderId}) async {
    if (_closed || !_flush()) return null;
    if (name.trim().isEmpty) {
      _fail('Indiquez un nom de dossier.');
      return null;
    }
    final before = project, id = narrative.identity('presentation_folder');
    try {
      final receipt = await port.createFolder(
        id: id,
        name: name.trim(),
        parentFolderId: parentFolderId,
      );
      if (_closed) return null;
      narrative.workspace.acceptResources(
        project == receipt.resources.before ? receipt.resources.before : before,
        receipt.resources.manifest,
      );
      error = null;
      changed();
      return id;
    } catch (failure) {
      _fail(failure);
      return null;
    }
  }

  Future<bool> create({
    required String title,
    String templateId = 'blank',
    int durationUs = 12000000,
    String? folderId,
  }) => _create(
    title: title,
    templateId: templateId,
    durationUs: durationUs,
    folderId: folderId,
  );
  Future<bool> createLinked({
    required PresentationSceneLink link,
    required String title,
    String templateId = 'blank',
    int durationUs = 12000000,
    String? folderId,
  }) => _create(
    title: title,
    templateId: templateId,
    durationUs: durationUs,
    folderId: folderId,
    link: link,
  );
  Future<bool> _create({
    required String title,
    required String templateId,
    required int durationUs,
    String? folderId,
    PresentationSceneLink? link,
  }) async {
    if (_closed || !_flush()) return false;
    if (title.trim().isEmpty) return _fail('Indiquez un nom.');
    suspendPreview?.call();
    final ticket = ++_generation;
    _loading = true;
    changed();
    try {
      final draft = await port.prepare(project);
      if (_closed || ticket != _generation) return false;
      final id = narrative.identity('presentation');
      final asset = draft.instantiate(
        id: id,
        title: title.trim(),
        templateId: templateId,
        durationUs: durationUs,
      );
      final s = PresentationWorkingSession(asset, draft, null)
        ..folderId = folderId
        ..link = link;
      _sessions[id] = s;
      _adopt(s, asset);
      activeId = id;
      error = null;
      return true;
    } catch (failure) {
      if (!_closed && ticket == _generation) return _fail(failure);
      return false;
    } finally {
      if (!_closed && ticket == _generation) {
        _loading = false;
        changed();
      }
    }
  }

  Future<bool> duplicate(String id) async {
    if (!await open(id) || activeId != id) return false;
    final source = _active!;
    final revision = source.revision, ticket = _generation;
    try {
      final draft = await port.prepare(
        project.copyWith(presentationCinematics: entries),
      );
      if (_closed || ticket != _generation || activeId != id) return false;
      if (source.revision != revision) {
        return _fail('Le montage a changé pendant la duplication. Réessayez.');
      }
      final next = narrative.identity('presentation');
      draft.includeMedia(source.imports);
      final manifest = draft.apply(
        PresentationCommand('presentationCinematic.duplicate', {
          'cinematicId': id,
          'duplicateId': next,
          'title': '${source.asset.title} — copie',
        }),
      );
      final asset = manifest.presentationCinematics.singleWhere(
        (a) => a.id == next,
      );
      final s = PresentationWorkingSession(asset, draft, null)
        ..folderId = source.folderId ?? source.base?.entry?.folderId;
      s.imports.addAll(source.imports);
      _sessions[next] = s;
      suspendPreview?.call();
      activeId = next;
      error = null;
      changed();
      return true;
    } catch (failure) {
      return _fail(failure);
    }
  }
}
