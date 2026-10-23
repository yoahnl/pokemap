part of 'playable_map_game.dart';

extension _PlayableMapGameSceneMusic on PlayableMapGame {
  Object get _soundMapOwner => (
    _currentMapActivationId,
    _gameState.mapInstanceWorldState.instanceRef(_activeMapId),
  );

  void _resetMapAudio() {
    _worldAudioSelectionSerial++;
    final controller = _mapAudio;
    final soundOwners = [
      for (final owners in _soundMapOwnersByActivation.values) ...owners,
    ];
    _soundMapOwnersByActivation.clear();
    _mapAudio = null;
    _mapAudioOwner = null;
    unawaited(controller?.close());
    if ((sceneSoundEffectPlaybackPort ?? _dialogueFeedbackPlayer)
        case final SceneOwnedSoundEffectPlaybackPort port) {
      for (final owner in soundOwners) {
        unawaited(
          port.stopOwnedSoundEffects(owner).catchError((Object error) {
            debugPrint('[scene_runtime] owned sound cleanup failed: $error');
          }),
        );
      }
    }
    final ambience = _injectedAmbienceMusicService ?? _ambienceMusicService;
    unawaited(
      ambience?.update(
        route: RuntimeAudioRoute.ambience,
        path: null,
        immediateStop: true,
      ),
    );
  }

  RuntimeSceneMusicSelection _captureMapAudioBaseline(
    SceneMusicChannel channel,
  ) => channel == SceneMusicChannel.ambience
      ? (route: RuntimeAudioRoute.ambience, path: null, volume: 0)
      : (
          route: RuntimeAudioRoute.overworld,
          path: _battleMusicResolver.resolveMapMusicAbsolutePath(
            bundle: _bundle,
          ),
          volume: _bundle.map.mapMetadata.musicVolume ?? .8,
        );

  RuntimeWorldAudioController _mapAudioForCurrentOwner() {
    final owner = _soundMapOwner;
    if (_mapAudioOwner != null && _mapAudioOwner != owner) _resetMapAudio();
    _mapAudioOwner = owner;
    return _mapAudio ??= RuntimeWorldAudioController(
      owner: owner,
      isOwnerCurrent: (candidate) =>
          !_isRemoved &&
          candidate == _mapAudioOwner &&
          candidate == _soundMapOwner,
      captureBaseline: _captureMapAudioBaseline,
      onChanged: _publishWorldAudio,
    );
  }

  Future<void> _publishWorldAudio() async {
    if (_isRemoved) return;
    await _applyRuntimeMusicSelection();
    final error =
        _ambienceMusic.lastFailure ??
        (_flowPhase != _RuntimeFlowPhase.battle &&
                _flowPhase != _RuntimeFlowPhase.battleTransition
            ? _music.lastFailure
            : null);
    if (error != null) throw StateError('World audio playback failed: $error');
  }

  Future<void> _closeSceneMusicBeforeCommit(
    _NarrativeSceneWorkingSession session,
  ) async {
    final controller = session.sceneAudio;
    if (controller == null) return;
    await controller.close();
    if (!_scenePresentationScopeIsCurrent(session))
      throw StateError('The Scene audio owner changed before commit.');
    if (controller.transactionFailure case final failure?)
      throw StateError('Scene audio transaction failed: $failure');
  }

  RuntimeWorldAudioController _sceneAudioFor(
    _NarrativeSceneWorkingSession session,
  ) => session.sceneAudio ??= RuntimeWorldAudioController(
    owner: session,
    isOwnerCurrent: (owner) =>
        identical(owner, session) && _scenePresentationScopeIsCurrent(session),
    captureBaseline: (channel) => switch (channel) {
      SceneMusicChannel.music =>
        _mapAudio?.music.selection ?? _captureMapAudioBaseline(channel),
      SceneMusicChannel.ambience =>
        _mapAudio?.ambience.selection ?? _captureMapAudioBaseline(channel),
      SceneMusicChannel.both => throw ArgumentError(
        'Capture a single channel.',
      ),
    },
    onChanged: _publishWorldAudio,
  );

  Future<String> _executeSceneMusicCommand(
    SceneInteractiveCommand command, {
    required _NarrativeSceneWorkingSession? session,
  }) async {
    if (command is! SceneMusicInteractiveCommand ||
        session == null ||
        _bundle.manifest.settings.dimension != ProjectDimension.twoD ||
        !_scenePresentationScopeIsCurrent(session))
      return 'blocked';
    String? path;
    if (command.operation == SceneMusicOperation.play) {
      final media = _bundle.manifest.cinematicMediaAssets
          .where((asset) => asset.id == command.mediaAssetId)
          .toList();
      if (media.length != 1 ||
          media.single.kind != CinematicMediaAssetKind.music)
        return 'blocked';
      path = resolveDialogueFeedbackProjectFile(
        _bundle.projectRootDirectory,
        media.single.relativePath,
      );
    }
    final controller = command.scope == SceneMusicScope.map
        ? _mapAudioForCurrentOwner()
        : _sceneAudioFor(session);
    if (command.scope == SceneMusicScope.map) {
      final checkpoint = controller.captureCheckpoint();
      session.registerCompensation(() async {
        if (controller.isCurrent)
          await controller.restoreCheckpoint(checkpoint);
      });
    }
    final applied = switch (command.operation) {
      SceneMusicOperation.play => await controller.play(
        channel: command.channel,
        path: path!,
        volume: command.volume!,
      ),
      SceneMusicOperation.restore => await controller.restore(command.channel),
      SceneMusicOperation.fadeOut => await controller.fadeOut(
        channel: command.channel,
        duration: Duration(milliseconds: command.durationMs!),
      ),
      SceneMusicOperation.stop => await controller.stop(command.channel),
      SceneMusicOperation.memorize => await controller.memorize(
        command.channel,
      ),
      SceneMusicOperation.restoreMemorized => await controller.restoreMemorized(
        command.channel,
      ),
    };
    if (!_scenePresentationScopeIsCurrent(session))
      throw StateError('The Scene audio owner changed during playback.');
    return applied ? 'completed' : 'blocked';
  }

  Future<String> _executeSceneStopSoundEffectsCommand(
    SceneInteractiveCommand command, {
    required _NarrativeSceneWorkingSession? session,
  }) async {
    if (command is! SceneStopSoundEffectsInteractiveCommand ||
        session == null ||
        _bundle.manifest.settings.dimension != ProjectDimension.twoD ||
        !_scenePresentationScopeIsCurrent(session))
      return 'blocked';
    final port = _sceneSoundEffectAudio;
    if (port is! SceneOwnedSoundEffectPlaybackPort) return 'blocked';
    if (command.scope == SceneMusicScope.map) {
      final owners =
          _soundMapOwnersByActivation.remove(_currentMapActivationId) ??
          const <Object>{};
      for (final owner in owners) {
        await port.stopOwnedSoundEffects(owner);
      }
    } else {
      await port.stopOwnedSoundEffects(session);
    }
    if (!_scenePresentationScopeIsCurrent(session))
      throw StateError('The Scene sound owner changed during stop.');
    return 'completed';
  }
}
