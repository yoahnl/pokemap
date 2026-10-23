part of 'playable_map_game.dart';

extension _PlayableMapGameWorldPresentation on PlayableMapGame {
  bool get _worldPresentationVisible =>
      !_isRemoved &&
      !_cinematicRuntimeController.isPlaying &&
      (_flowPhase == _RuntimeFlowPhase.overworld ||
          _flowPhase == _RuntimeFlowPhase.dialogue ||
          _flowPhase == _RuntimeFlowPhase.blockingInteraction);

  void _resetWorldPresentation() {
    _worldPresentationGeneration++;
    _worldPresentation.reset();
    for (final image in _worldPresentationImages.values) {
      image.dispose();
    }
    _worldPresentationImages.clear();
    _worldPresentationImageBytes = 0;
    _worldPresentationImageLoader = null;
  }

  Future<String> _executeSceneWorldPresentationCommand(
    SceneInteractiveCommand command, {
    required _NarrativeSceneWorkingSession? session,
  }) async {
    if (command is! SceneWorldPresentationInteractiveCommand ||
        !isLoaded ||
        _bundle.manifest.settings.dimension != ProjectDimension.twoD ||
        !_scenePresentationScopeIsCurrent(session)) {
      return 'blocked';
    }
    final generation = _worldPresentationGeneration;
    final activation = _currentMapActivationId;
    final mapId = _activeMapId;
    final instance = _battleRuntimeGameState.mapInstanceWorldState.instanceRef(
      mapId,
    );
    bool current() =>
        generation == _worldPresentationGeneration &&
        activation == _currentMapActivationId &&
        mapId == _activeMapId &&
        instance ==
            _battleRuntimeGameState.mapInstanceWorldState.instanceRef(mapId) &&
        _scenePresentationScopeIsCurrent(session);
    if (command.operation == SceneWorldPresentationOperation.showPicture &&
        !_worldPresentationImages.containsKey(command.mediaAssetId)) {
      if (_worldPresentationImages.length >= 100) {
        return 'blocked';
      }
      ui.Image image;
      try {
        image =
            await (_worldPresentationImageLoader ??=
                    WorldPresentationImageLoader(_bundle.projectRootDirectory))
                .load(command.mediaAssetId!);
      } on Object {
        return 'blocked';
      }
      if (!current() ||
          _worldPresentationImageBytes + image.width * image.height * 4 >
              64 * 1024 * 1024) {
        image.dispose();
        return 'blocked';
      }
      _worldPresentationImageBytes += image.width * image.height * 4;
      _worldPresentationImages[command.mediaAssetId!] = image;
    }
    if (!current()) {
      return 'blocked';
    }
    final checkpoint = _worldPresentation.captureCheckpoint();
    if (!_worldPresentation.apply(command, sceneOwner: session)) {
      return 'blocked';
    }
    session?.registerCompensation(() async {
      if (current()) {
        _worldPresentation.restoreCheckpoint(checkpoint);
      }
    });
    if (command.waitForCompletion && command.durationMs > 0) {
      await _executeSceneWaitCommand(
        SceneInteractiveCommand.wait(durationMs: command.durationMs),
        session: session,
      );
      if (!current()) {
        return 'blocked';
      }
    }
    return 'completed';
  }
}

final class _WorldPresentationViewportComponent extends Component {
  _WorldPresentationViewportComponent(this.game) : super(priority: 800);
  final PlayableMapGame game;
  @override
  void render(Canvas canvas) {
    if (!game._worldPresentationVisible) {
      return;
    }
    RuntimeWorldPresentationRenderer(images: game._worldPresentationImages)
        .render(
          canvas,
          Size(game.camera.viewport.size.x, game.camera.viewport.size.y),
          game._worldPresentation.frame,
        );
  }
}
