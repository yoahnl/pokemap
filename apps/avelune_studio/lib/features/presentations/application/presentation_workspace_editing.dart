part of 'presentation_workspace_controller.dart';

extension PresentationWorkspaceEditing on PresentationWorkspaceController {
  bool moveLayer(String layerId, int offset) {
    final asset = _active?.asset;
    if (_closed || asset == null) return false;
    final ordered = asset.layers.toList()
      ..sort((a, b) {
        final z = b.zIndex.compareTo(a.zIndex);
        return z == 0 ? a.id.compareTo(b.id) : z;
      });
    final index = ordered.indexWhere((layer) => layer.id == layerId);
    final target = index + offset;
    if (index < 0 ||
        target < 0 ||
        target >= ordered.length ||
        asset.isLayerEffectivelyLocked(layerId)) {
      return false;
    }
    return apply('presentationLayer.move', {
      'layerId': layerId,
      'insertionIndex': target,
      'targetFolderId': asset.folderForLayer(layerId)?.id,
    });
  }

  bool patchClip(String clipId, Map<String, Object?> values) {
    final asset = _active?.asset;
    if (asset == null) return false;
    for (final track in asset.tracks) {
      final clip = track.clips.where((clip) => clip.id == clipId).firstOrNull;
      if (clip == null) continue;
      final layerId = switch (clip) {
        PresentationTextClip() => clip.layerId,
        PresentationVisualClip() => clip.layerId,
        _ => null,
      };
      if (layerId != null && asset.isLayerEffectivelyLocked(layerId))
        return false;
      return apply('presentationClip.update', {
        'trackId': track.id,
        'clip': {...encodePresentationClip(clip), ...values},
      });
    }
    return false;
  }

  bool addClip(
    PresentationClip clip, {
    PresentationLayer? layer,
    required String label,
  }) => applyBatch([
    if (layer != null)
      PresentationCommand('presentationLayer.create', {
        'layer': encodePresentationLayer(layer),
      }),
    PresentationCommand('presentationTrack.create', {
      'track': {
        'id': narrative.identity('track'),
        'label': label,
        'kind': clip.trackKind.name,
        'clips': [encodePresentationClip(clip)],
      },
    }),
  ]);

  PresentationLayer _newLayer(String title) => PresentationLayer(
    id: narrative.identity('element'),
    label: title,
    zIndex:
        _active!.asset.layers
            .map((layer) => layer.zIndex)
            .fold<int>(-1, (a, b) => a > b ? a : b) +
        1,
  );

  int insertionStartUs(int timeUs) =>
      timeUs >= (_active?.asset.durationUs ?? 0) ? 0 : timeUs;

  String? addText({int timeUs = 0}) {
    final asset = _active?.asset;
    if (_closed || asset == null) return null;
    final start = insertionStartUs(timeUs);
    final layer = _newLayer('Texte');
    final clip = PresentationTextClip(
      id: narrative.identity('text'),
      startUs: start,
      durationUs: asset.durationUs - start,
      layerId: layer.id,
      text: 'Votre titre',
      style: PresentationTextStyle(
        fontSize: 48,
        weight: PresentationTextWeight.bold,
      ),
    );
    return addClip(clip, layer: layer, label: 'Texte') ? clip.id : null;
  }

  String? addMarker({int timeUs = 0, bool interaction = false}) {
    if (_closed || _active == null) return null;
    final clip = PresentationMarkerClip(
      id: narrative.identity('marker'),
      startUs: insertionStartUs(timeUs),
      label: interaction ? 'Interaction' : 'Repère',
      markerKind: interaction
          ? PresentationMarkerKind.interactionCue
          : PresentationMarkerKind.ordinary,
    );
    return addClip(clip, label: 'Repères') ? clip.id : null;
  }

  String? addMediaClip(ProjectMediaAsset media, {int timeUs = 0}) {
    final asset = _active?.asset;
    if (_closed || asset == null) return null;
    final start = insertionStartUs(timeUs);
    final remaining = asset.durationUs - start;
    PresentationLayer? layer;
    final PresentationClip clip;
    if (media.kind == ProjectMediaKind.audio) {
      clip = PresentationAudioClip(
        id: narrative.identity('audio'),
        startUs: start,
        durationUs: remaining,
        resourceId: media.id,
        audioKind: PresentationAudioKind.music,
      );
    } else if (media.kind == ProjectMediaKind.captions) {
      clip = PresentationCaptionClip(
        id: narrative.identity('caption'),
        startUs: start,
        durationUs: remaining,
        captionId: media.id,
      );
    } else {
      layer = _newLayer(media.label);
      clip = PresentationVisualClip(
        id: narrative.identity('image'),
        startUs: start,
        durationUs: remaining,
        layerId: layer.id,
        resourceId: media.id,
        mediaKind: media.kind == ProjectMediaKind.video
            ? PresentationVisualMediaKind.video
            : PresentationVisualMediaKind.image,
      );
    }
    return addClip(clip, layer: layer, label: media.label) ? clip.id : null;
  }

  bool deleteClips(Iterable<String> clipIds) {
    final ids = clipIds.toList();
    if (_closed || ids.isEmpty || !_flush()) return false;
    return apply('presentationClip.deleteBatch', {'clipIds': ids});
  }

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
