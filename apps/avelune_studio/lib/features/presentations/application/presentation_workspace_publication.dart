part of 'presentation_workspace_controller.dart';

extension PresentationWorkspacePublication on PresentationWorkspaceController {
  Future<void> _releaseMediaIfUnused(PresentationStagedMedia media) async {
    final handle = media.parameters['artifactHandle'];
    if (_sessions.values.any(
      (s) => s.imports.any((m) => m.parameters['artifactHandle'] == handle),
    )) {
      return;
    }
    await port.releaseMedia(media);
  }

  Future<bool> save([String? id]) async {
    if (_closed || !_flush()) return false;
    final s = _sessions[id ?? activeId];
    if (s == null || _publishing.contains(s.asset.id)) return false;
    if (!s.dirty) return true;
    final asset = s.asset, before = project, link = s.link;
    final currentScene = link == null
        ? null
        : sceneDrafts
              ?.call()
              .where((scene) => scene.id == link.scene.id)
              .firstOrNull;
    if (link != null && currentScene != null && currentScene != link.scene) {
      return _fail(
        'La scène ouverte a changé depuis la préparation du lien. Le montage reste conservé.',
      );
    }
    if (_sceneReferenceProblems(s, asset).isNotEmpty) {
      return _fail('Une scène ouverte utilise un repère absent de ce montage.');
    }
    final imports = List<PresentationStagedMedia>.of(s.imports);
    _publishing.add(asset.id);
    error = null;
    changed();
    try {
      final receipt = await port.publish(
        asset: asset,
        base: s.base,
        folderId: s.folderId,
        changeFolder: s.folderId != s.base?.entry?.folderId,
        link: link,
        imports: imports,
        mediaBaselines: s.projection.mediaBaselines,
      );
      if (_closed) return false;
      if (receipt.snapshot?.asset != asset) {
        throw const PresentationFailure(
          'Le reçu ne correspond pas au montage envoyé.',
        );
      }
      narrative.workspace.acceptResources(
        project == receipt.resources.before ? receipt.resources.before : before,
        receipt.resources.manifest,
      );
      s.base = receipt.snapshot;
      s.saved = asset;
      s.link = null;
      s.imports.removeWhere(imports.contains);
      s.projection = receipt.snapshot!.projection;
      _adopt(s, s.asset);
      if (link != null) {
        final scene = receipt.resources.manifest.scenes.singleWhere(
          (a) => a.id == link.scene.id,
        );
        onScenePublished?.call(link, scene);
      }
      onPublished?.call(asset.id);
      for (final media in imports) {
        await _releaseMediaIfUnused(media);
      }
      return true;
    } catch (failure) {
      return _fail(failure);
    } finally {
      _publishing.remove(asset.id);
      if (!_closed) changed();
    }
  }

  Future<bool> saveAll() async {
    if (!_flush()) return false;
    for (final id
        in _sessions.entries
            .where((e) => e.value.dirty)
            .map((e) => e.key)
            .toList()) {
      if (!await save(id)) return false;
    }
    return !dirty;
  }

  Future<bool> reload([String? id]) async {
    final target = id ?? activeId;
    if (_closed ||
        target == null ||
        _publishing.contains(target) ||
        !_flush()) {
      return false;
    }
    final old = _sessions.remove(target);
    if (old?.base == null && old != null) {
      for (final media in old.imports) {
        await _releaseMediaIfUnused(media);
      }
      if (activeId == target) activeId = null;
      changed();
      return true;
    }
    final ok = await open(target);
    if (!ok && old != null) _sessions[target] = old;
    if (ok && old != null) {
      for (final media in old.imports) {
        await _releaseMediaIfUnused(media);
      }
    }
    changed();
    return ok;
  }

  Future<bool> setArchived(String id, bool archived) async {
    if (_closed || !_flush() || !await open(id) || activeId != id) return false;
    final s = _active!;
    if (s.dirty || s.base == null) {
      return _fail('Enregistrez le montage avant de changer son archivage.');
    }
    _publishing.add(id);
    _deleting.add(id);
    changed();
    final before = project;
    try {
      final receipt = await port.setArchived(s.base!, archived);
      if (_closed) return false;
      narrative.workspace.acceptResources(
        project == receipt.resources.before ? receipt.resources.before : before,
        receipt.resources.manifest,
      );
      s.base = receipt.snapshot;
      error = null;
      return true;
    } catch (failure) {
      return _fail(failure);
    } finally {
      _publishing.remove(id);
      _deleting.remove(id);
      if (!_closed) changed();
    }
  }

  Future<bool> delete(String id) async {
    if (_closed ||
        !_flush() ||
        !await open(id) ||
        activeId != id ||
        _publishing.contains(id)) {
      return false;
    }
    final s = _active!;
    final usages = <String>{
      for (final scene in [...project.scenes, ...?sceneDrafts?.call()])
        for (final node in scene.graph.nodes)
          if (node.payload case ScenePresentationCinematicPayload(
            :final presentationCinematicId,
          ))
            if (presentationCinematicId == id) scene.name,
    };
    if (usages.isNotEmpty) {
      return _fail('Présentation utilisée par : ${usages.join(', ')}.');
    }
    final before = project;
    _publishing.add(id);
    _deleting.add(id);
    changed();
    try {
      if (s.base != null) {
        final receipt = await port.delete(s.base!);
        if (_closed) return false;
        narrative.workspace.acceptResources(
          project == receipt.resources.before
              ? receipt.resources.before
              : before,
          receipt.resources.manifest,
        );
      }
      _sessions.remove(id);
      for (final media in s.imports) {
        await _releaseMediaIfUnused(media);
      }
      if (activeId == id) activeId = null;
      error = null;
      return true;
    } catch (failure) {
      return _fail(failure);
    } finally {
      _publishing.remove(id);
      _deleting.remove(id);
      if (!_closed) changed();
    }
  }
}
