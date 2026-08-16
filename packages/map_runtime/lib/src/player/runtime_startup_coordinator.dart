import 'dart:async';
import 'dart:io';

import 'package:map_core/map_core.dart';

import 'runtime_intro_sequence_controller.dart';
import 'runtime_initial_map_preloader.dart';
import 'runtime_presentation_media_selection.dart';
import 'runtime_player_coordinator.dart';
import 'runtime_player_models.dart';
import 'runtime_project_typography_loader.dart';
import 'runtime_startup_models.dart';
import 'runtime_startup_preparation.dart';
import 'runtime_splash_jingle_controller.dart';
import 'runtime_title_music_controller.dart';

/// Host boundary for work that is not already owned by the player coordinator.
abstract interface class RuntimeStartupPreparationPort {
  Future<void> prepareManifestAndIdentity();

  Future<ProjectPresentationProfile?> loadPresentationProfile();
}

/// Resolves project-relative identifiers under the host's narrow project or
/// installation root. The runtime never joins untrusted paths itself.
abstract interface class RuntimePresentationAssetResolver {
  Future<RuntimeResolvedAsset?> resolveImage(String projectRelativePath);

  Future<RuntimeResolvedAsset?> resolveMedia(String projectRelativePath);

  Future<bool> exists(String projectRelativePath);
}

/// Owns splash, intro and title-prompt sequencing before delegating the session
/// lifecycle to [RuntimePlayerCoordinator]. It contains no widget or host brand.
final class RuntimeStartupCoordinator {
  RuntimeStartupCoordinator({
    required RuntimePlayerCoordinator playerCoordinator,
    required RuntimeStartupPreparationPort preparationPort,
    required RuntimeInitialMapPreloadPort initialMapPreloadPort,
    required RuntimePresentationAssetResolver assetResolver,
    required RuntimeIntroSequenceController introController,
    required RuntimeSplashJingleController splashJingleController,
    required RuntimeTitleMusicController titleMusicController,
    RuntimeStartupClock clock = const SystemRuntimeStartupClock(),
    RuntimeHostSplashBranding? hostBranding,
    RuntimeStartupPresentationMetadata presentationMetadata =
        const RuntimeStartupPresentationMetadata(),
    RuntimeProjectTypographyLoader typographyLoader =
        const RuntimeProjectTypographyLoader(),
    Duration? minimumSplashDuration,
    bool reducedMotion = false,
    RuntimePresentationOrientation presentationOrientation =
        RuntimePresentationOrientation.landscape,
    Future<void> Function()? stopIntroPlayback,
    RuntimeStartupTimelineGate? initialTimelineGate,
  })  : _player = playerCoordinator,
        _preparationPort = preparationPort,
        _initialMapPreloadPort = initialMapPreloadPort,
        _assetResolver = assetResolver,
        _intro = introController,
        _splashJingle = splashJingleController,
        _titleMusic = titleMusicController,
        _clock = clock,
        _hostBranding = hostBranding,
        _presentationMetadata = presentationMetadata,
        _typographyLoader = typographyLoader,
        _minimumSplashDuration = minimumSplashDuration ??
            hostBranding?.minimumDisplayDuration ??
            const Duration(milliseconds: 7200),
        _splashExitDuration = hostBranding?.exitTransitionDuration ??
            const Duration(milliseconds: 1296),
        _finalCurtainDuration = hostBranding?.finalCurtainDuration ??
            const Duration(milliseconds: 280),
        _reducedMotion = reducedMotion,
        _presentationOrientation = presentationOrientation,
        _stopIntroPlayback = stopIntroPlayback ?? _noOp,
        _initialTimelineGate = initialTimelineGate,
        _snapshot = RuntimeStartupSnapshot(
          revision: 0,
          phase: RuntimeStartupPhase.preparing,
          progress: 0,
          currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
          isPreparationReady: false,
          isMinimumElapsed: false,
          isLifecycleActive: true,
          playerSnapshot: playerCoordinator.snapshot,
        ) {
    if (_minimumSplashDuration.isNegative) {
      throw ArgumentError.value(
        _minimumSplashDuration,
        'minimumSplashDuration',
        'must not be negative',
      );
    }
    if (_splashExitDuration.isNegative) {
      throw ArgumentError.value(
        _splashExitDuration,
        'exitTransitionDuration',
        'must not be negative',
      );
    }
    if (_finalCurtainDuration.isNegative) {
      throw ArgumentError.value(
        _finalCurtainDuration,
        'finalCurtainDuration',
        'must not be negative',
      );
    }
    _playerSubscription = _player.snapshots.listen(_onPlayerSnapshot);
  }

  final RuntimePlayerCoordinator _player;
  final RuntimeStartupPreparationPort _preparationPort;
  final RuntimeInitialMapPreloadPort _initialMapPreloadPort;
  final RuntimePresentationAssetResolver _assetResolver;
  final RuntimeIntroSequenceController _intro;
  final RuntimeSplashJingleController _splashJingle;
  final RuntimeTitleMusicController _titleMusic;
  final RuntimeStartupClock _clock;
  final RuntimeHostSplashBranding? _hostBranding;
  final RuntimeStartupPresentationMetadata _presentationMetadata;
  final RuntimeProjectTypographyLoader _typographyLoader;
  final Duration _minimumSplashDuration;
  final Duration _splashExitDuration;
  final Duration _finalCurtainDuration;
  final bool _reducedMotion;
  RuntimePresentationOrientation _presentationOrientation;
  final Future<void> Function() _stopIntroPlayback;
  final RuntimeStartupTimelineGate? _initialTimelineGate;
  final StreamController<RuntimeStartupSnapshot> _snapshots =
      StreamController<RuntimeStartupSnapshot>.broadcast();
  late final StreamSubscription<RuntimePlayerSnapshot> _playerSubscription;

  RuntimeStartupSnapshot _snapshot;
  RuntimeStartupPreparation? _activePreparation;
  _RuntimeStartupAttemptContext? _activeAttempt;
  RuntimeResolvedAsset? _titleMusicAsset;
  RuntimeStartupPhase? _resumePhase;
  int _generation = 0;
  int _presentationSelectionGeneration = 0;
  bool _started = false;
  bool _disposed = false;
  bool _preparationActivated = false;
  bool _splashHoldElapsed = false;
  bool _preparationReadyObserved = false;
  bool _initialTimelineConsumed = false;
  Future<void>? _pendingSplashExit;

  RuntimeStartupSnapshot get snapshot => _snapshot;
  Stream<RuntimeStartupSnapshot> get snapshots => _snapshots.stream;
  bool get isDisposed => _disposed;

  /// Starts work and returns immediately so lifecycle and dispose stay usable
  /// while slow host futures are still pending.
  void start() {
    _ensureOpen();
    if (_started) {
      throw StateError('The runtime startup coordinator has already started.');
    }
    _started = true;
    _startPreparationAttempt();
  }

  Future<RuntimeStartupCommandResult> dispatch(
    RuntimeStartupCommand command,
  ) async {
    if (_disposed) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.cancelled,
      );
    }
    if (command.snapshotRevision != _snapshot.revision) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.stale,
        safeMessage: 'The startup screen changed before this action arrived.',
      );
    }
    if (!_snapshot.isLifecycleActive || _snapshot.isTransitioning) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.unavailable,
      );
    }

    switch (command.action) {
      case RuntimeStartupAction.skipSplash:
        if (!_snapshot.canSkipSplash) return _unavailable();
        final attempt = _activeAttempt;
        if (attempt == null) return _unavailable();
        _activePreparation?.cancel();
        await _activatePreparedPresentation(_generation, attempt);
      case RuntimeStartupAction.skipIntro:
        if (!_snapshot.canSkipIntro) return _unavailable();
        return _finishIntro(
          expectedRevision: command.snapshotRevision,
          mutate: _intro.skip,
        );
      case RuntimeStartupAction.continueFromPoster:
        if (!_snapshot.canContinueFromPoster) return _unavailable();
        return _finishIntro(
          expectedRevision: command.snapshotRevision,
          mutate: _intro.continueFromPoster,
        );
      case RuntimeStartupAction.replayIntro:
        if (!_snapshot.canReplayIntro) return _unavailable();
        return _replayIntro(command.snapshotRevision);
      case RuntimeStartupAction.pressStart:
        if (!_snapshot.canPressStart) return _unavailable();
        _publishDesiredPhase(RuntimeStartupPhase.titleMenu);
      case RuntimeStartupAction.retryPreparation:
        if (!_snapshot.canRetry) return _unavailable();
        _startPreparationAttempt();
      case RuntimeStartupAction.requestBack:
        return _requestBack(command.snapshotRevision);
    }
    return const RuntimeStartupCommandResult(
      status: RuntimeStartupCommandStatus.accepted,
    );
  }

  Future<RuntimeStartupCommandResult> introPlaybackCompleted({
    required int snapshotRevision,
  }) {
    if (!_acceptsIntroCallback(snapshotRevision)) {
      return Future<RuntimeStartupCommandResult>.value(
        snapshotRevision != _snapshot.revision
            ? const RuntimeStartupCommandResult(
                status: RuntimeStartupCommandStatus.stale,
              )
            : _unavailable(),
      );
    }
    return _finishIntro(
      expectedRevision: snapshotRevision,
      mutate: _intro.playbackCompleted,
    );
  }

  Future<RuntimeStartupCommandResult> introPlaybackFailed({
    required int snapshotRevision,
    required String reason,
  }) async {
    if (!_acceptsIntroCallback(snapshotRevision)) {
      return snapshotRevision != _snapshot.revision
          ? const RuntimeStartupCommandResult(
              status: RuntimeStartupCommandStatus.stale,
            )
          : _unavailable();
    }
    final generation = _generation;
    _publish(_snapshot.next(isTransitioning: true));
    await _stopIntroSafely();
    if (!_isCurrent(generation)) return _cancelled();
    _intro.playbackFailed(reason);
    if (_intro.phase == RuntimeIntroPhase.poster) {
      _publishDesiredPhase(
        RuntimeStartupPhase.intro,
        introPhase: _intro.phase,
        isTransitioning: false,
        introCanReplay: _intro.canReplay,
      );
    } else {
      await _enterTitlePrompt(generation);
    }
    return _isCurrent(generation)
        ? const RuntimeStartupCommandResult(
            status: RuntimeStartupCommandStatus.accepted,
          )
        : _cancelled();
  }

  /// All title-menu actions flow through this seam. Launch actions await music
  /// shutdown before the player coordinator may create a session descriptor.
  Future<RuntimePlayerCommandResult> dispatchPlayerCommand({
    required int startupSnapshotRevision,
    required RuntimePlayerCommand command,
  }) async {
    _ensureOpen();
    if (startupSnapshotRevision != _snapshot.revision ||
        _snapshot.phase != RuntimeStartupPhase.titleMenu ||
        !_snapshot.isLifecycleActive) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.stale,
        safeMessage: 'The title menu changed before this action arrived.',
      );
    }
    final launchesSession = command.action == RuntimePlayerAction.newGame ||
        command.action == RuntimePlayerAction.continueGame ||
        command.action == RuntimePlayerAction.load;
    if (!launchesSession) {
      return _player.dispatch(command);
    }

    final generation = _generation;
    _publish(_snapshot.next(isTransitioning: true));
    final transitionRevision = _snapshot.revision;
    await _titleMusic.update(path: null, titleVisible: false);
    if (!_canCompleteTitleLaunch(generation, transitionRevision)) {
      await _restoreTitleAfterInterruptedLaunch(generation);
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.cancelled,
      );
    }
    _publishDesiredPhase(
      RuntimeStartupPhase.launchingSession,
      isTransitioning: false,
    );
    final result = await _player.dispatch(command);
    if (!_isCurrent(generation)) {
      return const RuntimePlayerCommandResult(
        status: RuntimePlayerCommandStatus.cancelled,
      );
    }
    if (result.status == RuntimePlayerCommandStatus.accepted) {
      _publishDesiredPhase(
        _player.snapshot.phase == RuntimePlayerPhase.playing
            ? RuntimeStartupPhase.completed
            : RuntimeStartupPhase.launchingSession,
        isTransitioning: false,
      );
    } else {
      await _titleMusic.update(
        path: _titleMusicAsset?.playbackLocation,
        titleVisible: true,
      );
      _publishDesiredPhase(
        RuntimeStartupPhase.titleMenu,
        isTransitioning: false,
      );
    }
    return result;
  }

  Future<RuntimeStartupCommandResult> _requestBack(
    int snapshotRevision,
  ) async {
    switch (_snapshot.phase) {
      case RuntimeStartupPhase.preparing ||
            RuntimeStartupPhase.splash ||
            RuntimeStartupPhase.titlePrompt ||
            RuntimeStartupPhase.recoverableError:
        return const RuntimeStartupCommandResult(
          status: RuntimeStartupCommandStatus.accepted,
        );
      case RuntimeStartupPhase.intro:
        if (_snapshot.canContinueFromPoster) {
          return _finishIntro(
            expectedRevision: snapshotRevision,
            mutate: _intro.continueFromPoster,
          );
        }
        if (_snapshot.canSkipIntro) {
          return _finishIntro(
            expectedRevision: snapshotRevision,
            mutate: _intro.skip,
          );
        }
        return const RuntimeStartupCommandResult(
          status: RuntimeStartupCommandStatus.accepted,
        );
      case RuntimeStartupPhase.titleMenu ||
            RuntimeStartupPhase.launchingSession ||
            RuntimeStartupPhase.completed:
        final result = await _player.requestBack(
          snapshotRevision: _player.snapshot.revision,
        );
        return RuntimeStartupCommandResult(
          status: switch (result.status) {
            RuntimePlayerCommandStatus.accepted =>
              RuntimeStartupCommandStatus.accepted,
            RuntimePlayerCommandStatus.stale =>
              RuntimeStartupCommandStatus.stale,
            RuntimePlayerCommandStatus.cancelled =>
              RuntimeStartupCommandStatus.cancelled,
            RuntimePlayerCommandStatus.unavailable ||
            RuntimePlayerCommandStatus.failed =>
              RuntimeStartupCommandStatus.unavailable,
          },
          safeMessage: result.safeMessage,
        );
      case RuntimeStartupPhase.lifecyclePaused:
        return _unavailable();
    }
  }

  Future<void> pauseForLifecycle() async {
    _ensureOpen();
    if (!_snapshot.isLifecycleActive) return;
    _resumePhase = _snapshot.phase;
    _publish(
      _snapshot.next(
        phase: RuntimeStartupPhase.lifecyclePaused,
        isLifecycleActive: false,
        suspendedPhase: _resumePhase,
      ),
    );
    _intro.pauseForLifecycle();
    await Future.wait<void>(<Future<void>>[
      _splashJingle.pauseForLifecycle(),
      _titleMusic.pauseForLifecycle(),
      _player.pauseForLifecycle(),
    ]);
  }

  Future<void> resumeFromLifecycle() async {
    _ensureOpen();
    if (_snapshot.isLifecycleActive) return;
    _intro.resumeAfterLifecycle();
    await Future.wait<void>(<Future<void>>[
      _splashJingle.resumeFromLifecycle(),
      _titleMusic.resumeFromLifecycle(),
      _player.resumeFromLifecycle(),
    ]);
    if (_disposed) return;
    final resumePhase = _resumePhase ?? RuntimeStartupPhase.splash;
    _resumePhase = null;
    _publish(
      _snapshot.next(
        phase: resumePhase,
        isLifecycleActive: true,
        clearSuspendedPhase: true,
        introPhase: _intro.phase,
      ),
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _presentationSelectionGeneration++;
    _activePreparation?.cancel();
    _initialMapPreloadPort.clear();
    _activeAttempt = null;
    await _playerSubscription.cancel();
    await _stopIntroSafely();
    _intro.skip();
    await _splashJingle.dispose();
    await _titleMusic.dispose();
    await _player.dispose();
    await _snapshots.close();
  }

  void _startPreparationAttempt() {
    final generation = ++_generation;
    final initialTimelineGate =
        _initialTimelineConsumed ? null : _initialTimelineGate;
    _initialTimelineConsumed = true;
    final attempt = _RuntimeStartupAttemptContext(
      orientation: _presentationOrientation,
    );
    _presentationSelectionGeneration++;
    _activePreparation?.cancel();
    _initialMapPreloadPort.clear();
    _activeAttempt = attempt;
    _preparationActivated = false;
    _splashHoldElapsed = false;
    _preparationReadyObserved = false;
    _pendingSplashExit = null;
    _titleMusicAsset = null;
    _resumePhase = null;
    _publish(
      _snapshot.next(
        phase: RuntimeStartupPhase.splash,
        // A retry never makes a visible loading bar move backwards. The new
        progress: _snapshot.progress,
        currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
        isPreparationReady: false,
        isMinimumElapsed: false,
        isLifecycleActive: true,
        clearSuspendedPhase: true,
        introPhase: RuntimeIntroPhase.idle,
        isTransitioning: false,
        clearFailure: true,
        diagnostics: const <RuntimeStartupDiagnostic>[],
        introCanReplay: false,
      ),
    );
    unawaited(_splashJingle.playOnce());

    // Existing player initialization is the canonical preference/save seam.
    // Both weighted units await the same concurrent load without duplicating it.
    final playerPreparation = _player.initialize();
    final presentationPreparation = _loadPresentationSafely(attempt);
    final typographyPreparation = presentationPreparation.then(
      (_) => _prepareTypography(attempt),
    );
    _watchSplashHold(
      generation,
      attempt,
      initialTimelineGate?.splashHoldElapsed,
    );
    final preparation = RuntimeStartupPreparation(
      clock: _clock,
      minimumDisplayDuration: _minimumSplashDuration,
      minimumDisplayElapsed: initialTimelineGate?.minimumDisplayElapsed,
    );
    _activePreparation = preparation;
    final result = preparation.run(
      operations: <RuntimeStartupPreparationStage,
          RuntimeStartupPreparationOperation>{
        RuntimeStartupPreparationStage.manifestAndIdentity: () async {
          try {
            await _preparationPort.prepareManifestAndIdentity();
            return const RuntimeStartupPreparationStepResult.completed();
          } on Object {
            return const RuntimeStartupPreparationStepResult.blockingFailure(
              RuntimeStartupFailure(
                code: 'manifestPreparationFailed',
                safeMessage: 'The game identity could not be prepared.',
              ),
            );
          }
        },
        RuntimeStartupPreparationStage.playerPreferences: () =>
            _preparePlayerTitleUnit(playerPreparation, 'preferencesFailed'),
        RuntimeStartupPreparationStage.saveDiscovery: () =>
            _preparePlayerTitleUnit(playerPreparation, 'saveDiscoveryFailed'),
        RuntimeStartupPreparationStage.initialMap: () async {
          await playerPreparation;
          if (_player.snapshot.phase != RuntimePlayerPhase.title) {
            return const RuntimeStartupPreparationStepResult.blockingFailure(
              RuntimeStartupFailure(
                code: 'initialMapPreparationFailed',
                safeMessage: 'The first map could not be prepared.',
              ),
            );
          }
          final save = _player.snapshot.continueSave;
          if (save == null || !save.canContinue) {
            return const RuntimeStartupPreparationStepResult.completed();
          }
          final request = RuntimeInitialMapPreloadRequest.continueGame(
            save.address,
          );
          try {
            await _initialMapPreloadPort.preloadInitialMap(
              request,
              onProgress: (progress) => preparation.reportStageProgress(
                RuntimeStartupPreparationStage.initialMap,
                progress.value,
              ),
            );
            return const RuntimeStartupPreparationStepResult.completed();
          } on Object {
            return const RuntimeStartupPreparationStepResult.blockingFailure(
              RuntimeStartupFailure(
                code: 'initialMapPreparationFailed',
                safeMessage: 'The first map could not be prepared.',
              ),
            );
          }
        },
        RuntimeStartupPreparationStage.presentationProfile: () async {
          await presentationPreparation;
          if (attempt.presentationLoadFailed) {
            return const RuntimeStartupPreparationStepResult.nonBlockingFailure(
              RuntimeStartupDiagnostic(
                code: 'presentationProfileUnavailable',
                safeMessage: 'The game presentation could not be loaded.',
              ),
            );
          }
          return typographyPreparation;
        },
        RuntimeStartupPreparationStage.splashBranding: () =>
            _prepareSplashBranding(attempt),
        RuntimeStartupPreparationStage.introAndPoster: () async {
          await presentationPreparation;
          return _prepareIntroAssets(attempt);
        },
        RuntimeStartupPreparationStage.titleMenuAndMusic: () async {
          await presentationPreparation;
          return _prepareTitleAssets(attempt);
        },
      },
      onChanged: (preparationSnapshot) {
        if (!_isCurrent(generation)) return;
        if (preparationSnapshot.isPreparationReady &&
            !_preparationReadyObserved) {
          _preparationReadyObserved = true;
          if (!_reducedMotion &&
              _splashHoldElapsed &&
              _splashExitDuration > Duration.zero) {
            _pendingSplashExit = _clock.delay(_splashExitDuration);
          }
        }
        _publish(
          _snapshot.next(
            progress: preparationSnapshot.progress > _snapshot.progress
                ? preparationSnapshot.progress
                : _snapshot.progress,
            currentStage: preparationSnapshot.currentStage,
            isPreparationReady: preparationSnapshot.isPreparationReady,
            isMinimumElapsed: preparationSnapshot.isMinimumElapsed,
            diagnostics: preparationSnapshot.diagnostics,
          ),
        );
      },
    );
    result.then(
      (value) => _handlePreparationResult(generation, attempt, value),
    );
  }

  void _watchSplashHold(
    int generation,
    _RuntimeStartupAttemptContext attempt,
    Future<void>? splashHoldElapsed,
  ) {
    if (_reducedMotion) return;
    final holdDuration = _minimumSplashDuration > _splashExitDuration
        ? _minimumSplashDuration - _splashExitDuration
        : Duration.zero;
    (splashHoldElapsed ?? _clock.delay(holdDuration)).then(
      (_) {
        if (_isActiveAttempt(generation, attempt)) {
          _splashHoldElapsed = true;
        }
      },
      onError: (_, __) {
        if (_isActiveAttempt(generation, attempt)) {
          _splashHoldElapsed = true;
        }
      },
    );
  }

  Future<ProjectPresentationProfile?> _loadPresentationSafely(
    _RuntimeStartupAttemptContext attempt,
  ) async {
    try {
      attempt.profile = await _preparationPort.loadPresentationProfile();
    } on Object {
      attempt.profile = null;
      attempt.presentationLoadFailed = true;
    }
    return attempt.profile;
  }

  Future<RuntimeStartupPreparationStepResult> _preparePlayerTitleUnit(
    Future<void> playerPreparation,
    String code,
  ) async {
    await playerPreparation;
    if (_player.snapshot.phase == RuntimePlayerPhase.title) {
      return const RuntimeStartupPreparationStepResult.completed();
    }
    return RuntimeStartupPreparationStepResult.blockingFailure(
      RuntimeStartupFailure(
        code: code,
        safeMessage: code == 'saveDiscoveryFailed'
            ? 'Saved games could not be checked safely.'
            : 'Player preferences could not be loaded.',
      ),
    );
  }

  Future<RuntimeStartupPreparationStepResult> _prepareSplashBranding(
    _RuntimeStartupAttemptContext attempt,
  ) async {
    final assetId = _hostBranding?.logoAssetId;
    if (assetId == null) {
      return const RuntimeStartupPreparationStepResult.absent();
    }
    try {
      attempt.hostLogo = await _assetResolver.resolveImage(assetId);
      return attempt.hostLogo == null
          ? const RuntimeStartupPreparationStepResult.nonBlockingFailure(
              RuntimeStartupDiagnostic(
                code: 'splashLogoUnavailable',
                safeMessage: 'The startup logo could not be displayed.',
              ),
            )
          : const RuntimeStartupPreparationStepResult.completed();
    } on Object {
      return const RuntimeStartupPreparationStepResult.nonBlockingFailure(
        RuntimeStartupDiagnostic(
          code: 'splashLogoUnavailable',
          safeMessage: 'The startup logo could not be displayed.',
        ),
      );
    }
  }

  Future<RuntimeStartupPreparationStepResult> _prepareIntroAssets(
    _RuntimeStartupAttemptContext attempt,
  ) async {
    final intro = attempt.profile?.intro;
    if (intro == null) {
      return const RuntimeStartupPreparationStepResult.absent();
    }
    final variant = selectRuntimePresentationVideo(
      intro.media,
      attempt.orientation,
    ).variant;
    final video = _resolveMediaSafely(variant.videoPath);
    final poster = _resolveImageSafely(variant.posterPath);
    final assets = await Future.wait<
        RuntimeResolvedAsset?>(<Future<RuntimeResolvedAsset?>>[
      video,
      poster,
    ]);
    attempt.introVideo = assets[0];
    attempt.introPoster = assets[1];
    final diagnostics = <RuntimeStartupDiagnostic>[];
    if (attempt.introVideo == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'introVideoUnavailable',
          safeMessage: 'The introduction video is unavailable.',
        ),
      );
    }
    if (attempt.introPoster == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'introPosterUnavailable',
          safeMessage: 'The introduction poster is unavailable.',
        ),
      );
    }
    return diagnostics.isEmpty
        ? const RuntimeStartupPreparationStepResult.completed()
        : RuntimeStartupPreparationStepResult.nonBlockingFailures(diagnostics);
  }

  Future<RuntimeStartupPreparationStepResult> _prepareTitleAssets(
    _RuntimeStartupAttemptContext attempt,
  ) async {
    final profile = attempt.profile;
    if (profile == null) {
      return const RuntimeStartupPreparationStepResult.absent();
    }
    final branding = profile.branding;
    final prompt = profile.titleMotion?.promptLoop;
    final menu = profile.titleMotion?.menuLoop;
    final promptVariant = prompt == null
        ? null
        : selectRuntimePresentationVideo(prompt, attempt.orientation).variant;
    final menuVariant = menu == null
        ? null
        : selectRuntimePresentationVideo(menu, attempt.orientation).variant;
    final hero = switch (branding.heroPath) {
      final String path => _resolveImageSafely(path),
      null => Future<RuntimeResolvedAsset?>.value(),
    };
    final logo = switch (branding.iconPath) {
      final String path => _resolveImageSafely(path),
      null => Future<RuntimeResolvedAsset?>.value(),
    };
    final music = switch (branding.titleMusicPath) {
      final String path => _resolveMediaSafely(path),
      null => Future<RuntimeResolvedAsset?>.value(),
    };
    final promptVideo = promptVariant == null
        ? Future<RuntimeResolvedAsset?>.value()
        : _resolveMediaSafely(promptVariant.videoPath);
    final promptPoster = promptVariant == null
        ? Future<RuntimeResolvedAsset?>.value()
        : _resolveImageSafely(promptVariant.posterPath);
    final menuVideo = menuVariant == null
        ? Future<RuntimeResolvedAsset?>.value()
        : _resolveMediaSafely(menuVariant.videoPath);
    final menuPoster = menuVariant == null
        ? Future<RuntimeResolvedAsset?>.value()
        : _resolveImageSafely(menuVariant.posterPath);
    final assets = await Future.wait<
        RuntimeResolvedAsset?>(<Future<RuntimeResolvedAsset?>>[
      hero,
      logo,
      music,
      promptVideo,
      promptPoster,
      menuVideo,
      menuPoster,
    ]);
    attempt.titleHero = assets[0];
    attempt.titleLogo = assets[1];
    attempt.titleMusic = assets[2];
    attempt.titlePromptVideo = assets[3];
    attempt.titlePromptPoster = assets[4];
    attempt.titleMenuVideo = assets[5];
    attempt.titleMenuPoster = assets[6];
    final diagnostics = <RuntimeStartupDiagnostic>[];
    if (branding.titleMusicPath != null && attempt.titleMusic == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titleMusicUnavailable',
          safeMessage: 'The title music is unavailable.',
        ),
      );
    }
    if (branding.heroPath != null && attempt.titleHero == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titleHeroUnavailable',
          safeMessage: 'The title artwork is unavailable.',
        ),
      );
    }
    if (branding.iconPath != null && attempt.titleLogo == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titleLogoUnavailable',
          safeMessage: 'The title logo is unavailable.',
        ),
      );
    }
    if (promptVariant != null && attempt.titlePromptVideo == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titlePromptVideoUnavailable',
          safeMessage: 'The title animation is unavailable.',
        ),
      );
    }
    if (promptVariant != null && attempt.titlePromptPoster == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titlePromptPosterUnavailable',
          safeMessage: 'The title poster is unavailable.',
        ),
      );
    }
    if (menuVariant != null && attempt.titleMenuVideo == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titleMenuVideoUnavailable',
          safeMessage: 'The menu animation is unavailable.',
        ),
      );
    }
    if (menuVariant != null && attempt.titleMenuPoster == null) {
      diagnostics.add(
        const RuntimeStartupDiagnostic(
          code: 'titleMenuPosterUnavailable',
          safeMessage: 'The menu poster is unavailable.',
        ),
      );
    }
    return diagnostics.isEmpty
        ? const RuntimeStartupPreparationStepResult.completed()
        : RuntimeStartupPreparationStepResult.nonBlockingFailures(diagnostics);
  }

  Future<RuntimeStartupPreparationStepResult> _prepareTypography(
    _RuntimeStartupAttemptContext attempt,
  ) async {
    final source = attempt.profile?.typography;
    if (source == null) {
      return attempt.profile == null
          ? const RuntimeStartupPreparationStepResult.absent()
          : const RuntimeStartupPreparationStepResult.completed();
    }
    final roles = <ProjectTypographyRole, ProjectTypographyRoleProfile>{
      ProjectTypographyRole.display: source.display,
      ProjectTypographyRole.body: source.body,
      ProjectTypographyRole.dialogue: source.dialogue,
      if (source.combat case final combat?)
        ProjectTypographyRole.combat: combat,
      ProjectTypographyRole.numbers: source.numbers,
    };
    final requests = <ProjectTypographyRole, RuntimeProjectFontRequest>{};
    final unavailable = <ProjectTypographyRole>{};
    for (final entry in roles.entries) {
      final profile = entry.value;
      File? file;
      final fontPath = profile.fontPath;
      if (fontPath != null) {
        final resolved = await _resolveMediaSafely(fontPath);
        if (resolved?.resolvedUri.scheme == 'file') {
          file = File.fromUri(resolved!.resolvedUri);
        } else {
          unavailable.add(entry.key);
        }
      }
      requests[entry.key] = RuntimeProjectFontRequest(
        file: file,
        family: profile.family,
        fallbackFamilies: profile.fallbackFamilies,
      );
    }
    final loaded = await _typographyLoader.load(requests);
    attempt.typography = loaded;
    unavailable.addAll(loaded.unavailableRoles);
    if (unavailable.isEmpty) {
      return const RuntimeStartupPreparationStepResult.completed();
    }
    return RuntimeStartupPreparationStepResult.nonBlockingFailures(
      <RuntimeStartupDiagnostic>[
        for (final role in unavailable)
          RuntimeStartupDiagnostic(
            code: 'typography${_capitalized(role.name)}Unavailable',
            safeMessage: 'A project font is unavailable.',
          ),
      ],
    );
  }

  Future<void> _handlePreparationResult(
    int generation,
    _RuntimeStartupAttemptContext attempt,
    RuntimeStartupPreparationResult result,
  ) async {
    if (!_isActiveAttempt(generation, attempt) || _preparationActivated) return;
    switch (result.status) {
      case RuntimeStartupPreparationStatus.cancelled:
        return;
      case RuntimeStartupPreparationStatus.blocked:
        _publishDesiredPhase(
          RuntimeStartupPhase.recoverableError,
          failure: result.snapshot.failure,
        );
      case RuntimeStartupPreparationStatus.ready:
        await _activatePreparedPresentation(generation, attempt);
    }
  }

  Future<void> _activatePreparedPresentation(
    int generation,
    _RuntimeStartupAttemptContext attempt,
  ) async {
    if (!_isActiveAttempt(generation, attempt) || _preparationActivated) return;
    if (attempt.orientation != _presentationOrientation) {
      attempt.orientation = _presentationOrientation;
      await Future.wait<RuntimeStartupPreparationStepResult>([
        _prepareIntroAssets(attempt),
        _prepareTitleAssets(attempt),
      ]);
      if (!_isActiveAttempt(generation, attempt)) return;
    }
    _preparationActivated = true;
    _titleMusicAsset = attempt.titleMusic;
    final resolved = _resolvedPresentation(attempt);
    final introProfile = attempt.profile?.intro;
    _publish(
      _snapshot.next(
        progress: 1,
        isPreparationReady: true,
        presentation: resolved,
      ),
    );
    final pendingSplashExit = _pendingSplashExit;
    if (!_reducedMotion && pendingSplashExit != null) {
      await pendingSplashExit;
      if (!_isActiveAttempt(generation, attempt)) return;
    }
    if (!_reducedMotion && _finalCurtainDuration > Duration.zero) {
      await _clock.delay(_finalCurtainDuration);
      if (!_isActiveAttempt(generation, attempt)) return;
    }
    await _splashJingle.stop();
    if (!_isActiveAttempt(generation, attempt)) return;
    _intro.start(
      hasVideo: attempt.introVideo != null,
      hasPoster: attempt.introPoster != null,
      reducedMotion: _reducedMotion,
      reducedMotionBehavior: introProfile?.reducedMotionBehavior == 'skip'
          ? RuntimeIntroReducedMotionBehavior.skip
          : RuntimeIntroReducedMotionBehavior.poster,
      allowReplay: introProfile?.allowReplay ?? false,
    );
    _publish(
      _snapshot.next(
        introPhase: _intro.phase,
        introCanReplay:
            (introProfile?.allowReplay ?? false) && attempt.introVideo != null,
      ),
    );
    if (_intro.phase == RuntimeIntroPhase.completed) {
      await _enterTitlePrompt(generation);
      return;
    }
    _publishDesiredPhase(
      RuntimeStartupPhase.intro,
      introPhase: _intro.phase,
      isTransitioning: false,
    );
    if (!_snapshot.isLifecycleActive) _intro.pauseForLifecycle();
  }

  /// Selects and resolves only the media needed by the new viewport family.
  /// Concrete players observe new asset ids and dispose their previous decoder
  /// before constructing the replacement.
  Future<void> updatePresentationOrientation(
    RuntimePresentationOrientation orientation,
  ) async {
    _ensureOpen();
    if (_presentationOrientation == orientation) return;
    _presentationOrientation = orientation;
    final attempt = _activeAttempt;
    if (!_preparationActivated || attempt == null) return;
    final generation = _generation;
    final selectionGeneration = ++_presentationSelectionGeneration;
    attempt.orientation = orientation;
    final results = await Future.wait<RuntimeStartupPreparationStepResult>([
      _prepareIntroAssets(attempt),
      _prepareTitleAssets(attempt),
    ]);
    if (!_isActiveAttempt(generation, attempt) ||
        selectionGeneration != _presentationSelectionGeneration ||
        attempt.orientation != orientation) {
      return;
    }
    final diagnostics = <RuntimeStartupDiagnostic>[
      ..._snapshot.diagnostics,
      for (final result in results) ...result.diagnostics,
    ];
    _publish(
      _snapshot.next(
        presentation: _resolvedPresentation(attempt),
        diagnostics: _uniqueDiagnostics(diagnostics),
      ),
    );
  }

  RuntimeStartupResolvedPresentation _resolvedPresentation(
    _RuntimeStartupAttemptContext attempt,
  ) =>
      RuntimeStartupResolvedPresentation(
        metadata: _presentationMetadata,
        orientation: attempt.orientation,
        profile: attempt.profile,
        hostLogo: attempt.hostLogo?.presentationAsset,
        introVideo: attempt.introVideo?.presentationAsset,
        introPoster: attempt.introPoster?.presentationAsset,
        titleHero: attempt.titleHero?.presentationAsset,
        titleLogo: attempt.titleLogo?.presentationAsset,
        titleMusic: attempt.titleMusic?.presentationAsset,
        titlePromptVideo: attempt.titlePromptVideo?.presentationAsset,
        titlePromptPoster: attempt.titlePromptPoster?.presentationAsset,
        titleMenuVideo: attempt.titleMenuVideo?.presentationAsset,
        titleMenuPoster: attempt.titleMenuPoster?.presentationAsset,
        typography: attempt.typography,
      );

  List<RuntimeStartupDiagnostic> _uniqueDiagnostics(
    Iterable<RuntimeStartupDiagnostic> diagnostics,
  ) {
    final seen = <String>{};
    return [
      for (final diagnostic in diagnostics)
        if (seen.add(diagnostic.code)) diagnostic,
    ];
  }

  Future<RuntimeStartupCommandResult> _finishIntro({
    required int expectedRevision,
    required void Function() mutate,
  }) async {
    if (expectedRevision != _snapshot.revision) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.stale,
      );
    }
    final generation = _generation;
    _publish(_snapshot.next(isTransitioning: true));
    await _stopIntroSafely();
    if (!_isCurrent(generation)) return _cancelled();
    mutate();
    await _enterTitlePrompt(generation);
    return _isCurrent(generation)
        ? const RuntimeStartupCommandResult(
            status: RuntimeStartupCommandStatus.accepted,
          )
        : _cancelled();
  }

  Future<RuntimeStartupCommandResult> _replayIntro(int expectedRevision) async {
    if (expectedRevision != _snapshot.revision) {
      return const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.stale,
      );
    }
    final generation = _generation;
    _publish(_snapshot.next(isTransitioning: true));
    await _titleMusic.update(path: null, titleVisible: false);
    if (!_isCurrent(generation)) return _cancelled();
    if (!_intro.replay()) {
      _publish(_snapshot.next(isTransitioning: false));
      return _unavailable();
    }
    _publishDesiredPhase(
      RuntimeStartupPhase.intro,
      introPhase: _intro.phase,
      isTransitioning: false,
    );
    return const RuntimeStartupCommandResult(
      status: RuntimeStartupCommandStatus.accepted,
    );
  }

  Future<void> _enterTitlePrompt(int generation) async {
    await _titleMusic.update(
      path: _titleMusicAsset?.playbackLocation,
      titleVisible: true,
    );
    if (!_isCurrent(generation)) return;
    final diagnostics = <RuntimeStartupDiagnostic>[
      ..._snapshot.diagnostics,
      if (_titleMusic.lastFailure != null)
        const RuntimeStartupDiagnostic(
          code: 'titleMusicPlaybackFailed',
          safeMessage: 'The title music could not be played.',
        ),
    ];
    _publishDesiredPhase(
      RuntimeStartupPhase.titlePrompt,
      introPhase: _intro.phase,
      isTransitioning: false,
      diagnostics: diagnostics,
    );
  }

  Future<RuntimeResolvedAsset?> _resolveImageSafely(String assetId) async {
    try {
      return await _assetResolver.resolveImage(assetId);
    } on Object {
      return null;
    }
  }

  Future<RuntimeResolvedAsset?> _resolveMediaSafely(String assetId) async {
    try {
      return await _assetResolver.resolveMedia(assetId);
    } on Object {
      return null;
    }
  }

  bool _canCompleteTitleLaunch(int generation, int transitionRevision) =>
      _isCurrent(generation) &&
      _snapshot.isLifecycleActive &&
      _snapshot.phase == RuntimeStartupPhase.titleMenu &&
      _snapshot.revision == transitionRevision;

  Future<void> _restoreTitleAfterInterruptedLaunch(int generation) async {
    if (!_isCurrent(generation)) return;
    await _titleMusic.update(
      path: _titleMusicAsset?.playbackLocation,
      titleVisible: true,
    );
    if (!_isCurrent(generation)) return;
    _publishDesiredPhase(
      RuntimeStartupPhase.titleMenu,
      isTransitioning: false,
    );
  }

  bool _acceptsIntroCallback(int revision) =>
      !_disposed &&
      revision == _snapshot.revision &&
      _snapshot.phase == RuntimeStartupPhase.intro &&
      !_snapshot.isTransitioning &&
      (_intro.phase == RuntimeIntroPhase.playing ||
          _intro.phase == RuntimeIntroPhase.paused);

  void _onPlayerSnapshot(RuntimePlayerSnapshot playerSnapshot) {
    if (_disposed) return;
    var desiredPhase = _effectivePhase;
    if (desiredPhase == RuntimeStartupPhase.launchingSession &&
        (playerSnapshot.phase == RuntimePlayerPhase.playing ||
            playerSnapshot.phase == RuntimePlayerPhase.paused)) {
      desiredPhase = RuntimeStartupPhase.completed;
    }
    if ((desiredPhase == RuntimeStartupPhase.launchingSession ||
            desiredPhase == RuntimeStartupPhase.completed) &&
        playerSnapshot.phase == RuntimePlayerPhase.title) {
      desiredPhase = RuntimeStartupPhase.titleMenu;
      unawaited(
        _titleMusic.update(
          path: _titleMusicAsset?.playbackLocation,
          titleVisible: true,
        ),
      );
    }
    if (_snapshot.phase == RuntimeStartupPhase.lifecyclePaused) {
      _resumePhase = desiredPhase;
      _publish(
        _snapshot.next(
          suspendedPhase: desiredPhase,
          playerSnapshot: playerSnapshot,
        ),
      );
      return;
    }
    _publish(
      _snapshot.next(
        phase: desiredPhase,
        playerSnapshot: playerSnapshot,
      ),
    );
  }

  RuntimeStartupPhase get _effectivePhase =>
      _snapshot.phase == RuntimeStartupPhase.lifecyclePaused
          ? _resumePhase ?? RuntimeStartupPhase.splash
          : _snapshot.phase;

  void _publishDesiredPhase(
    RuntimeStartupPhase phase, {
    RuntimeIntroPhase? introPhase,
    bool? isTransitioning,
    RuntimeStartupFailure? failure,
    List<RuntimeStartupDiagnostic>? diagnostics,
    bool? introCanReplay,
  }) {
    if (_snapshot.phase == RuntimeStartupPhase.lifecyclePaused) {
      _resumePhase = phase;
      _publish(
        _snapshot.next(
          suspendedPhase: phase,
          introPhase: introPhase,
          isTransitioning: isTransitioning,
          failure: failure,
          diagnostics: diagnostics,
          introCanReplay: introCanReplay,
        ),
      );
      return;
    }
    _publish(
      _snapshot.next(
        phase: phase,
        introPhase: introPhase,
        isTransitioning: isTransitioning,
        failure: failure,
        diagnostics: diagnostics,
        introCanReplay: introCanReplay,
      ),
    );
  }

  Future<void> _stopIntroSafely() async {
    try {
      await _stopIntroPlayback();
    } on Object {
      // A failed media stop must never trap the player before the title.
    }
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  bool _isActiveAttempt(
    int generation,
    _RuntimeStartupAttemptContext attempt,
  ) =>
      _isCurrent(generation) && identical(_activeAttempt, attempt);

  RuntimeStartupCommandResult _unavailable() =>
      const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.unavailable,
      );

  RuntimeStartupCommandResult _cancelled() => const RuntimeStartupCommandResult(
        status: RuntimeStartupCommandStatus.cancelled,
      );

  void _publish(RuntimeStartupSnapshot next) {
    if (_disposed) return;
    _snapshot = next;
    if (!_snapshots.isClosed) _snapshots.add(next);
  }

  void _ensureOpen() {
    if (_disposed) {
      throw StateError('The runtime startup coordinator is disposed.');
    }
  }

  static Future<void> _noOp() => Future<void>.value();
}

final class _RuntimeStartupAttemptContext {
  _RuntimeStartupAttemptContext({required this.orientation});

  RuntimePresentationOrientation orientation;
  ProjectPresentationProfile? profile;
  bool presentationLoadFailed = false;
  RuntimeResolvedAsset? hostLogo;
  RuntimeResolvedAsset? introVideo;
  RuntimeResolvedAsset? introPoster;
  RuntimeResolvedAsset? titleHero;
  RuntimeResolvedAsset? titleLogo;
  RuntimeResolvedAsset? titleMusic;
  RuntimeResolvedAsset? titlePromptVideo;
  RuntimeResolvedAsset? titlePromptPoster;
  RuntimeResolvedAsset? titleMenuVideo;
  RuntimeResolvedAsset? titleMenuPoster;
  RuntimeLoadedTypography? typography;
}

String _capitalized(String value) =>
    value.isEmpty ? value : '${value[0].toUpperCase()}${value.substring(1)}';
