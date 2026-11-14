part of 'studio_playtest_view.dart';

mixin _StudioPlaytestRuntimeLoading on State<StudioPlaytestView> {
  PlayableMapGame? _game;
  RuntimeMapBundle? _playerBundle;
  PlayerServiceRuntimeController? _playerServices;
  SpatialExplorationSession? _spatial;
  StudioSpatialPlaytest? _spatialPlaytest;
  late final _saves = widget.testSession ?? StudioPlaytestSession();
  bool _ready = false;
  Completer<void>? _spatialMountReady;
  HeadlessSceneInteractionPort? _preSessionInteractions;
  StreamSubscription<SceneInteractionRequest>? _preSessionSubscription;
  SceneInteractionRequest? _preSessionRequest;

  Future<Object> _load({bool restoreSpatialSave = false}) async {
    final document = await widget.port.loadMap(widget.session, widget.entry);
    if (document.revision != widget.expectedRevision) {
      throw const StudioLaunchProblem(
        'La carte a changé sur disque. Revenez et rechargez-la.',
        owner: StudioFailureOwner.map,
      );
    }
    final projectPath = p.join(widget.session.directoryPath, 'project.json');
    if (!mounted) throw StateError('Test fermé');
    if (document.map.spatialScene != null) {
      var bundle = await loadRuntimeMapBundle(
        projectFilePath: projectPath,
        mapId: widget.entry.id,
      );
      _requireUnchangedMap(bundle, document.map);
      StudioSpatialPlaytest.validateHero(bundle);
      final preparedAssets = await _prepareProjectAssets(
        project: bundle.manifest,
      );
      if (!mounted) throw StateError('Test fermé');
      if (preparedAssets) {
        bundle = await loadRuntimeMapBundle(
          projectFilePath: projectPath,
          mapId: widget.entry.id,
        );
        _requireUnchangedMap(bundle, document.map);
      }
      final playtest = await StudioSpatialPlaytest.prepare(
        bundle: bundle,
        projectFilePath: projectPath,
        projectRevision: widget.expectedRevision,
        saves: _saves,
        restore: restoreSpatialSave,
        mountSession: (runtime) async {
          if (!mounted) throw StateError('Test fermé');
          final ready = Completer<void>();
          _spatialMountReady = ready;
          setState(() => _spatial = runtime.session);
          await ready.future;
        },
        unmountSession: (runtime) async {
          if (mounted && identical(_spatialPlaytest?.runtime, runtime)) {
            setState(() => _spatial = null);
          }
        },
      );
      if (!mounted) {
        await playtest.dispose();
        throw StateError('Test fermé');
      }
      _spatialPlaytest = playtest;
      try {
        await playtest.runtime.load((_) {});
      } catch (_) {
        if (mounted && identical(_spatialPlaytest, playtest)) {
          setState(() {
            _spatialPlaytest = null;
            _spatial = null;
            _ready = false;
          });
          await WidgetsBinding.instance.endOfFrame;
        }
        await playtest.dispose();
        rethrow;
      }
      if (!mounted) throw StateError('Test fermé');
      setState(() {
        _spatial = playtest.runtime.session;
        _ready = true;
      });
      return playtest;
    }
    await _prepareProjectAssets();
    if (!mounted) throw StateError('Test fermé');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectPath,
      mapId: widget.entry.id,
    );
    _requireUnchangedMap(bundle, document.map);
    final GameState? initialGameState;
    if (bundle.manifest.newGame.enabled &&
        bundle.manifest.newGame.preSessionSceneId?.trim().isNotEmpty == true) {
      final interactions = HeadlessSceneInteractionPort();
      _preSessionInteractions = interactions;
      _preSessionSubscription = interactions.requests.listen((request) {
        if (mounted) setState(() => _preSessionRequest = request);
      });
      try {
        initialGameState = await prepareStudioPlaytestStart(
          bundle,
          projectPath,
          interactions: interactions,
        );
      } finally {
        await _preSessionSubscription?.cancel();
        _preSessionSubscription = null;
        interactions.close();
        _preSessionInteractions = null;
        if (mounted) setState(() => _preSessionRequest = null);
      }
    } else {
      initialGameState = await prepareStudioPlaytestStart(bundle, projectPath);
    }
    if (!mounted) throw StateError('Test fermé');
    final game = PlayableMapGame(
      bundle: bundle,
      projectFilePath: projectPath,
      initialGameState: initialGameState,
      saveRepository: _saves,
      initialMapActivationReason: MapActivationReason.initialBoot,
    );
    _game = game;
    _playerBundle = bundle;
    _playerServices = PlayerServiceRuntimeController.contextual(
      bagCapacity: bundle.manifest.bagCapacity,
      supportsRepel: true,
      currentGameState: () => game.playerServiceGameStateSnapshot,
      commitAndSave: game.commitAndSavePlayerServiceState,
      setInputLocked: (locked) => game.setExternalInputLock(
        RuntimeExternalInputLock.playerService,
        locked: locked,
      ),
      loadRecoveryCaps: (state) => loadRuntimePlayerServiceRecoveryCaps(
        gameState: state,
        projectRootDirectory: bundle.projectRootDirectory,
        pokemonConfig: bundle.manifest.pokemon,
      ),
      healingDisplayMapReader: game.playerServiceHealingDisplayMap,
      conditionContext: ScriptEvaluationContext(
        narrativeFactResolver: NarrativeFactRuntimeResolver.fromFacts(
          bundle.manifest.facts,
        ),
      ),
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      locale: 'fr',
    );
    game.setPlayerServiceRuntimeController(_playerServices!);
    game.setDialogueFlutterOverlayPreferred(true);
    setState(() => _ready = true);
    return game;
  }

  void _requireUnchangedMap(RuntimeMapBundle bundle, MapData document) {
    final expected = projectSpatialSmartTileModels(
      map: document,
      catalog: bundle.manifest.smartTileCatalog,
      sourceCellWidth: bundle.manifest.settings.tileWidth,
      sourceCellHeight: bundle.manifest.settings.tileHeight,
    );
    if (bundle.map != expected) {
      throw const StudioLaunchProblem(
        'La carte a changé pendant la préparation du test.',
        owner: StudioFailureOwner.map,
      );
    }
  }

  Future<bool> _prepareProjectAssets({ProjectManifest? project}) async {
    final prepareProjectAssets = widget.prepareProjectAssets;
    if (prepareProjectAssets != null) {
      await prepareProjectAssets(widget.session.directoryPath);
      return true;
    }
    if (widget.session.storage == ProjectSessionStorage.workingCatalog ||
        project?.pokemon.enabled == false) {
      return false;
    }
    await StudioProjectItemIcons.shared.prepare(
      widget.session.directoryPath,
      shouldContinue: () => mounted,
    );
    return true;
  }

  void _finishSpatialMount([Object? error]) {
    final ready = _spatialMountReady;
    if (ready == null || ready.isCompleted) return;
    if (error == null) {
      ready.complete();
    } else {
      ready.completeError(error);
    }
  }
}
