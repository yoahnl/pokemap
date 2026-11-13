import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_story/map_story.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:path/path.dart' as p;

import 'studio_playtest_session.dart';
import 'studio_playtest_start.dart';
import '../../features/playtest/contracts/studio_playtest_controls.dart';
import 'studio_playtest_player_view.dart';
import 'studio_spatial_playtest.dart';
import 'studio_spatial_playtest_view.dart';
import '../../features/pokemon/data/studio_project_item_icons.dart';
import '../../features/verification/application/studio_failure_diagnosis.dart';

export 'studio_playtest_session.dart';
export '../../features/playtest/contracts/studio_playtest_controls.dart';

import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';

class StudioPlaytestView extends StatefulWidget {
  const StudioPlaytestView({
    super.key,
    required this.session,
    required this.entry,
    required this.expectedRevision,
    required this.port,
    required this.onClose,
    this.testSession,
    this.previewVisuals,
    this.prepareProjectAssets,
    this.spatialViewBuilder,
    this.controls,
  });

  final StudioPlaytestControls? controls;
  final ProjectSession session;
  final ProjectMapEntry entry;
  final String expectedRevision;
  final MapWorkspacePort port;
  final VoidCallback onClose;
  final StudioPlaytestSession? testSession;
  final ValueListenable<SpatialVisualPatch>? previewVisuals;
  final Future<void> Function(String projectRoot)? prepareProjectAssets;
  final Widget Function(
    BuildContext context,
    StudioSpatialPlaytest playtest,
    VoidCallback onReady,
    void Function(Object) onError,
  )?
  spatialViewBuilder;

  @override
  State<StudioPlaytestView> createState() => _StudioPlaytestViewState();
}

class _StudioPlaytestViewState extends State<StudioPlaytestView> {
  late Future<Object> _loading = _load();
  PlayableMapGame? _game;
  RuntimeMapBundle? _playerBundle;
  PlayerServiceRuntimeController? _playerServices;
  SpatialExplorationSession? _spatial;
  StudioSpatialPlaytest? _spatialPlaytest;
  late final _saves = widget.testSession ?? StudioPlaytestSession();
  bool _busy = false;
  String? _message;
  bool _spatialPaused = false;
  bool _ready = false;
  Completer<void>? _spatialMountReady;
  HeadlessSceneInteractionPort? _preSessionInteractions;
  StreamSubscription<SceneInteractionRequest>? _preSessionSubscription;
  SceneInteractionRequest? _preSessionRequest;

  late StudioPlaytestControls _controls;

  @override
  void initState() {
    super.initState();
    _controls = widget.controls ?? StudioPlaytestControls();
    _attachControls();
  }

  @override
  void didUpdateWidget(StudioPlaytestView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.controls, widget.controls)) {
      _controls.detach(this);
      _controls = widget.controls ?? StudioPlaytestControls();
      _attachControls();
    }
  }

  void _attachControls() {
    _controls.attach(
      this,
      status: () => StudioPlaytestStatus(
        ready: _ready,
        busy: _busy,
        hasSave: _saves.hasSave,
        paused: _spatialPaused,
        spatial: _spatialPlaytest != null,
        diagonal: _spatial?.movement.allowDiagonalMovement ?? false,
        message: _message,
      ),
      requestClose: () => widget.onClose(),
      save: _save,
      resume: _resume,
      newGame: _newGame,
      togglePause: _toggleSpatialPause,
      setSpeed: (speed) => _game?.setTestSpeed(speed),
      toggleDiagonal: () {
        final playtest = _spatialPlaytest;
        final spatial = _spatial;
        if (playtest == null ||
            spatial == null ||
            !playtest.runtime.inputAuthority.value.acceptsOverworldInput) {
          return;
        }
        setState(
          () => spatial.movement.setDiagonalMovement(
            !spatial.movement.allowDiagonalMovement,
          ),
        );
      },
    );
  }

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);
    _controls.statusChanged();
  }

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

  @override
  void dispose() {
    _controls.detach(this);
    _preSessionInteractions?.close();
    unawaited(_preSessionSubscription?.cancel());
    _game?.pauseEngine();
    _finishSpatialMount(StateError('Test fermé'));
    unawaited(_spatialPlaytest?.dispose());
    final services = _playerServices;
    final deleteSaves = widget.testSession == null;
    unawaited(() async {
      await services?.dispose();
      if (deleteSaves) await _saves.delete();
    }());
    super.dispose();
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

  Future<void> _save() async {
    setState(() => _busy = true);
    var saved = false;
    try {
      saved = _spatialPlaytest == null
          ? await _game?.saveGame() ?? false
          : await _spatialPlaytest!.save();
    } catch (_) {
      saved = false;
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = saved
          ? 'Test enregistré en mémoire pour cette session.'
          : 'Terminez l’interaction avant d’enregistrer le test.';
    });
  }

  Future<void> _resume() async {
    if (_busy || !_ready) return;
    setState(() => _busy = true);
    if (_spatialPlaytest != null) {
      _replaceTest(restoreSpatialSave: true);
      return;
    }
    final loaded = await _game?.loadGame() ?? false;
    if (!mounted) return;
    setState(() {
      _busy = false;
      _message = loaded ? 'Sauvegarde du test reprise.' : 'Reprise impossible pendant cette interaction ou après ce changement.';
    });
  }

  Future<void> _newGame() async {
    if (_busy || !_ready) return;
    _replaceTest(restoreSpatialSave: false);
  }

  void _replaceTest({required bool restoreSpatialSave}) {
    final previous = _spatialPlaytest;
    final services = _playerServices;
    _game?.pauseEngine();
    setState(() {
      _playerServices = null;
      _playerBundle = null;
      _game = null;
      _spatialPlaytest = null;
      _spatial = null;
      _ready = false;
      _spatialPaused = false;
      _busy = false;
      _message = restoreSpatialSave
          ? 'Reprise de la sauvegarde du test…'
          : 'Préparation d’une nouvelle partie…';
      _loading = () async {
        await WidgetsBinding.instance.endOfFrame;
        await services?.dispose();
        await previous?.dispose();
        if (!restoreSpatialSave) await _saves.delete();
        if (!mounted) throw StateError('Test fermé');
        final loaded = await _load(restoreSpatialSave: restoreSpatialSave);
        if (mounted) {
          setState(
            () => _message = restoreSpatialSave
                ? 'Sauvegarde du test reprise.'
                : 'Nouvelle partie : état de test réinitialisé.',
          );
        }
        return loaded;
      }();
    });
  }

  Future<void> _toggleSpatialPause() async {
    final runtime = _spatialPlaytest?.runtime;
    if (runtime == null) return;
    if (_spatialPaused) {
      await runtime.resume();
    } else {
      await runtime.pause();
    }
    if (mounted) setState(() => _spatialPaused = !_spatialPaused);
  }

  Widget _launchFailure(BuildContext context, Object error) {
    final diagnosis = diagnoseLaunchFailure(error);
    return Center(child: Text('${diagnosis.summary}\n${diagnosis.detail}'));
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<Object>(
    future: _loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return _launchFailure(context, snapshot.error!);
      }
      if (_preSessionRequest case final request?) {
        return Localizations.override(
          context: context,
          delegates: PokeMapPlayerLocalizations.localizationsDelegates,
          child: Theme(
            data: Theme.of(context).brightness == Brightness.dark
                ? PokeMapPlayerTheme.dark()
                : PokeMapPlayerTheme.light(),
            child: PlayerSceneInteractionSurface(
              request: request,
              onResult: (result) {
                final resolution = _preSessionInteractions?.resolve(result);
                if (resolution?.isAccepted == true && mounted) {
                  if (result is SceneCancelledInteractionResult) {
                    widget.onClose();
                    return;
                  }
                  setState(() => _preSessionRequest = null);
                }
              },
            ),
          ),
        );
      }
      final game = snapshot.connectionState == ConnectionState.done
          ? snapshot.data
          : (_spatial == null ? null : _spatialPlaytest);
      if (game == null) {
        return const Center(child: CircularProgressIndicator());
      }
      if (game is StudioSpatialPlaytest) {
        if (!identical(game, _spatialPlaytest)) {
          return const Center(child: CircularProgressIndicator());
        }
        void ready() {
          if (mounted && identical(game, _spatialPlaytest)) {
            _finishSpatialMount();
          }
        }

        void failed(Object error) {
          if (mounted && identical(game, _spatialPlaytest)) {
            _finishSpatialMount(error);
          }
        }

        final builder = widget.spatialViewBuilder;
        if (builder != null) {
          return builder(context, game, ready, failed);
        }
        return StudioSpatialPlaytestView(
          key: ObjectKey(game),
          runtime: game.runtime,
          previewVisuals: widget.previewVisuals,
          onReady: ready,
          onError: failed,
        );
      }
      return StudioPlaytestPlayerView(
        key: ObjectKey(game),
        game: game as PlayableMapGame,
        bundle: _playerBundle!,
        services: _playerServices!,
      );
    },
  );
}

class StudioPlaytestSaveRepository extends StudioPlaytestSession {}
