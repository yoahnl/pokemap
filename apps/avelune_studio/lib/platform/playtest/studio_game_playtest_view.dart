import 'dart:async';
import 'dart:io';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

import '../../presentation/shared/widgets/buttons/studio_button.dart';
import '../../presentation/shared/widgets/feedback/studio_notice.dart';
import 'studio_game_playtest.dart';
import '../../features/rendering/application/studio_rendering_preferences.dart';

class StudioGamePlaytestView extends StatefulWidget {
  const StudioGamePlaytestView({
    super.key,
    required this.projectFilePath,
    required this.onClose,
    this.renderingPreferences,
  });
  final String projectFilePath;
  final VoidCallback onClose;
  final StudioRenderingPreferences? renderingPreferences;
  @override
  State<StudioGamePlaytestView> createState() => _StudioGamePlaytestViewState();
}

class _StudioGamePlaytestViewState extends State<StudioGamePlaytestView>
    with WidgetsBindingObserver {
  final _shell = PlayerRuntimeStartupShellController();
  final _startupImageBudget = RuntimeResourceBudget();
  final _viewport = GlobalKey();
  final _closed = Completer<void>();
  StudioGamePlaytest? _game;
  late RuntimePlayerCoordinatorViewController _playerController;
  RuntimeStartupSnapshot? _snapshot;
  StreamSubscription<RuntimeStartupSnapshot>? _subscription;
  PlayableMapGame? _map;
  SpatialExplorationGameSessionRuntime? _spatial;
  Completer<void>? _spatialReady;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_prepare());
  }

  Future<void> _prepare() async {
    try {
      final game = await StudioGamePlaytest.prepare(
        projectFilePath: widget.projectFilePath,
        renderingPreferences: widget.renderingPreferences,
        onExit: () async {
          if (mounted) widget.onClose();
        },
        stopIntroPlayback: _shell.stopIntroPlayback,
        mountGame: (map) async {
          if (!mounted) throw StateError('Le test a été fermé.');
          map.setDialogueFlutterOverlayPreferred(true);
          setState(() => _map = map);
          await Future.any([map.loaded, _closed.future]);
        },
        unmountGame: (map) async {
          if (mounted && identical(_map, map)) setState(() => _map = null);
        },
        mountSpatial: (runtime) async {
          if (!mounted) throw StateError('Le test a été fermé.');
          final ready = Completer<void>();
          _spatialReady = ready;
          setState(() => _spatial = runtime);
          await Future.any([ready.future, _closed.future]);
        },
        unmountSpatial: (runtime) async {
          if (mounted && identical(_spatial, runtime)) {
            setState(() => _spatial = null);
          }
        },
      );
      if (!mounted) {
        await game.dispose();
        return;
      }
      setState(() {
        _game = game;
        _playerController = RuntimePlayerCoordinatorViewController(game.player);
        _snapshot = game.startup.snapshot;
      });
      _subscription = game.startup.snapshots.listen((value) {
        if (mounted) setState(() => _snapshot = value);
      });
      game.startup.start();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final game = _game;
    if (game == null) return;
    if (state == AppLifecycleState.resumed) {
      unawaited(game.startup.resumeFromLifecycle());
      unawaited(game.presentation.controller.resumeAfterLifecycle());
    } else {
      unawaited(game.startup.pauseForLifecycle());
      unawaited(game.presentation.controller.pauseForLifecycle());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (!_closed.isCompleted) _closed.complete();
    unawaited(_subscription?.cancel());
    unawaited(_game?.dispose());
    _startupImageBudget.dispose();
    super.dispose();
  }

  Future<PlayerImageLease> _loadPlayerImage(
    String path, {
    required bool Function() isCurrent,
  }) async {
    final lease = await loadRuntimeUiImageFromFilePath(
      path,
      resourceBudget: _startupImageBudget,
      isCurrent: isCurrent,
    );
    return PlayerImageLease(image: lease.image, onDispose: lease.dispose);
  }

  ImageProvider? _image(RuntimeStartupPresentationAsset? asset) {
    final resolved = asset == null
        ? null
        : _game?.assets.resolvedAsset(asset.assetId);
    return resolved == null
        ? null
        : FileImage(File.fromUri(resolved.resolvedUri));
  }

  PlayerIntroVideoSource? _video(
    RuntimeStartupPresentationAsset? asset,
    ProjectResponsiveVideoProfile? profile, {
    bool looping = false,
  }) {
    final resolved = asset == null
        ? null
        : _game?.assets.resolvedAsset(asset.assetId);
    if (resolved == null || profile == null) return null;
    final variant = selectRuntimePresentationVideo(
      profile,
      _snapshot!.presentation?.orientation ??
          RuntimePresentationOrientation.landscape,
    ).variant;
    return PlayerIntroVideoSource(
      videoUri: resolved.resolvedUri,
      looping: looping,
      volume: looping ? 0 : 1,
      aspectRatio: variant.width / variant.height,
      focalX: variant.focalX,
      focalY: variant.focalY,
      captionsLoader: variant.captionsPath == null
          ? null
          : () => _game!.assets.loadText(variant.captionsPath!),
    );
  }

  Widget _scene(BuildContext context) {
    final spatial = _spatial;
    if (spatial != null && spatial.session != null) {
      return SizedBox.expand(
        key: _viewport,
        child: Stack(
          fit: StackFit.expand,
          children: [
            SpatialOverworldPresentation(
              battle: spatial.battle,
              child: SpatialExplorationView(
                key: ObjectKey(spatial),
                session: spatial.session!,
                audioMixer: spatial.audioMixer,
                keyboardInputEnabled: false,
                onReady: () {
                  if (identical(spatial, _spatial) &&
                      !(_spatialReady?.isCompleted ?? true)) {
                    _spatialReady!.complete();
                  }
                },
                onError: (error) {
                  if (identical(spatial, _spatial) &&
                      !(_spatialReady?.isCompleted ?? true)) {
                    _spatialReady!.completeError(error);
                  }
                },
              ),
            ),
            if (spatial.battle case final battle?)
              ListenableBuilder(
                listenable: battle,
                builder: (_, _) => battle.isActive
                    ? SpatialBattleView(
                        runtime: battle,
                        keyboardInputEnabled: false,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
      );
    }
    final map = _map;
    return SizedBox.expand(
      key: _viewport,
      child: map == null
          ? const SizedBox.expand()
          : GameWidget(game: map, autofocus: false),
    );
  }

  Widget _player(BuildContext context) {
    final game = _game!;
    final snapshot = _snapshot!;
    final resolved = snapshot.presentation;
    final presentation = resolved == null
        ? const RuntimePlayerPresentation(
            title: RuntimePlayerTitlePresentation(author: ''),
          )
        : RuntimePlayerPresentation.fromRuntime(
            resolved,
            imageForAsset: _image,
          );
    final profile = resolved?.profile;
    final controller = game.presentation.controller;
    final size = MediaQuery.sizeOf(context);
    final orientation = size.height > size.width
        ? PresentationFrameOrientation.portrait
        : PresentationFrameOrientation.landscape;
    if (controller.orientation != orientation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) controller.setOrientation(orientation);
      });
    }
    final reducedMotion =
        snapshot.playerSnapshot?.preferences?.accessibility.reducedMotion ??
        false;
    final baseTheme = Theme.of(context).brightness == Brightness.dark
        ? PokeMapPlayerTheme.dark(reducedMotion: reducedMotion)
        : PokeMapPlayerTheme.light(reducedMotion: reducedMotion);
    return PlayerImageScope(
      identity: _startupImageBudget,
      loader: _loadPlayerImage,
      child: Theme(
        data: presentation.applyTo(baseTheme),
        child: PlayerRuntimeStartupShell(
          key: const ValueKey('studio-game-startup'),
          controller: _shell,
          branding: studioGameBranding,
          snapshot: snapshot,
          titlePresentation: presentation.title,
          audioMixer: game.audioMixer,
          reducedMotion: reducedMotion,
          introSource: _video(resolved?.introVideo, profile?.intro?.media),
          introPoster: _image(resolved?.introPoster),
          titlePromptSource: _video(
            resolved?.titlePromptVideo,
            profile?.titleMotion?.promptLoop,
            looping: true,
          ),
          titlePromptPoster: _image(resolved?.titlePromptPoster),
          titleMenuSource: _video(
            resolved?.titleMenuVideo,
            profile?.titleMotion?.menuLoop,
            looping: true,
          ),
          titleMenuPoster: _image(resolved?.titleMenuPoster),
          onPresentationOrientationChanged: (value) {
            unawaited(game.startup.updatePresentationOrientation(value));
          },
          onStartupCommand: (command) {
            unawaited(game.startup.dispatch(command));
          },
          onPlayerCommand: (command) => game.startup.dispatchPlayerCommand(
            startupSnapshotRevision: snapshot.revision,
            command: command,
          ),
          onIntroPlaybackCompleted: (revision) {
            unawaited(
              game.startup.introPlaybackCompleted(snapshotRevision: revision),
            );
          },
          onIntroPlaybackFailed: (revision, reason) {
            unawaited(
              game.startup.introPlaybackFailed(
                snapshotRevision: revision,
                reason: reason,
              ),
            );
          },
          sessionBuilder: (_, _) => PokeMapPlayerSessionView(
            projectAudio: () => _map?.projectAudio ?? _spatial?.projectAudio,
            controller: _playerController,
            imageLoader: _loadPlayerImage,
            imageScopeIdentity: _startupImageBudget,
            titlePresentation: presentation.title,
            pauseMenuLabels: presentation.pauseMenuLabels,
            pausePresentation: presentation.pausePresentation,
            gameplayInputRoute: game.sessions.handleInput,
            gameplayViewportKey: _viewport,
            gameplayInputAuthority:
                _map?.inputAuthorityListenable ?? _spatial?.inputAuthority,
            overworldInteractions:
                _map?.overworldInteractions ?? _spatial?.overworldInteractions,
            hitTestOverworldInteraction: _map?.hitTestOverworldInteraction,
            onOverworldInteraction: game.sessions.dispatchOverworldInteraction,
            dialoguePresentation:
                _map?.dialoguePresentationListenable ??
                _spatial?.dialoguePresentationListenable,
            onDialogueCommand:
                _map?.dispatchDialoguePresentationCommand ??
                _spatial?.dispatchDialoguePresentationCommand,
            battlePresentation:
                _map?.battleCommandOverlayListenable ??
                _spatial?.battle?.battlePresentationListenable,
            onBattleCommand:
                _map?.dispatchBattlePresentationCommand ??
                _spatial?.battle?.dispatchBattlePresentationCommand,
            menuInteractionBlocked: _map?.battleExitTransitionVisible,
            presentationFrame: controller,
            presentationContentPort: controller,
            onPresentationSkip: () async {
              await controller.skipActive();
            },
            gameSceneBuilder: _scene,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Tester le jeu depuis le début',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StudioButton(
                  label: 'Retour à Studio',
                  icon: Icons.close,
                  secondary: true,
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: _error != null
                ? Center(
                    child: StudioNotice(
                      'Le jeu ne peut pas démarrer : $_error',
                    ),
                  )
                : _game == null
                ? const Center(child: CircularProgressIndicator())
                : _player(context),
          ),
        ],
      ),
    ),
  );
}
