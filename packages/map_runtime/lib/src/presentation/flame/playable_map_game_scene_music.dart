part of 'playable_map_game.dart';

extension _PlayableMapGameSceneMusic on PlayableMapGame {
  Future<void> _closeSceneMusicBeforeCommit(
    _NarrativeSceneWorkingSession session,
  ) async {
    final controller = session.sceneMusic;
    if (controller == null) return;
    await controller.close();
    if (!_scenePresentationScopeIsCurrent(session)) {
      throw StateError('The Scene music owner changed before commit.');
    }
    final failure = controller.transactionFailure;
    if (failure != null) {
      throw StateError('Scene music transaction failed: $failure');
    }
  }

  RuntimeSceneMusicSelection _captureSceneMusicBaseline() => (
    route: RuntimeAudioRoute.overworld,
    path: _battleMusicResolver.resolveMapMusicAbsolutePath(bundle: _bundle),
    volume: _bundle.map.mapMetadata.musicVolume ?? .8,
  );

  Future<String> _executeSceneMusicCommand(
    SceneInteractiveCommand command, {
    required _NarrativeSceneWorkingSession? session,
  }) async {
    if (command is! SceneMusicInteractiveCommand ||
        session == null ||
        _bundle.manifest.settings.dimension != ProjectDimension.twoD ||
        !_scenePresentationScopeIsCurrent(session)) {
      return 'blocked';
    }
    String? path;
    if (command.operation == SceneMusicOperation.play) {
      final media = _bundle.manifest.cinematicMediaAssets.where(
        (asset) => asset.id == command.mediaAssetId,
      );
      if (media.length != 1 ||
          media.single.kind != CinematicMediaAssetKind.music) {
        return 'blocked';
      }
      path = resolveDialogueFeedbackProjectFile(
        _bundle.projectRootDirectory,
        media.single.relativePath,
      );
    }
    final controller = session.sceneMusic ??= RuntimeSceneMusicController(
      owner: session,
      isOwnerCurrent: (owner) =>
          identical(owner, session) &&
          _scenePresentationScopeIsCurrent(session),
      captureBaseline: _captureSceneMusicBaseline,
      onChanged: () async {
        if (!_scenePresentationScopeIsCurrent(session)) return;
        await _applyRuntimeMusicSelection();
        if (!_scenePresentationScopeIsCurrent(session)) return;
        final failure = _music.lastFailure;
        if (failure != null &&
            _flowPhase != _RuntimeFlowPhase.battle &&
            _flowPhase != _RuntimeFlowPhase.battleTransition) {
          throw StateError('Scene music playback failed: $failure');
        }
      },
    );
    final bool applied;
    try {
      applied = switch (command.operation) {
        SceneMusicOperation.play => await controller.play(
          path: path!,
          volume: command.volume!,
        ),
        SceneMusicOperation.restore => await controller.restore(),
        SceneMusicOperation.fadeOut => await controller.fadeOut(
          duration: Duration(milliseconds: command.durationMs!),
        ),
      };
    } on Object catch (error) {
      if (!_scenePresentationScopeIsCurrent(session)) {
        throw StateError('The Scene music owner changed during playback.');
      }
      debugPrint('[scene_runtime] scoped music failed: $error');
      rethrow;
    }
    if (!_scenePresentationScopeIsCurrent(session)) {
      throw StateError('The Scene music owner changed during playback.');
    }
    return applied ? 'completed' : 'blocked';
  }
}
