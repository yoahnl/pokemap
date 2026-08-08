import 'dart:async';

import 'package:map_core/map_core.dart';

import 'runtime_intro_sequence_controller.dart';
import 'runtime_player_coordinator.dart';
import 'runtime_player_models.dart';
import 'runtime_startup_models.dart';
import 'runtime_startup_preparation.dart';
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
    required RuntimePresentationAssetResolver assetResolver,
    required RuntimeIntroSequenceController introController,
    required RuntimeTitleMusicController titleMusicController,
    RuntimeStartupClock clock = const SystemRuntimeStartupClock(),
    RuntimeHostSplashBranding? hostBranding,
    Duration? minimumSplashDuration,
    bool reducedMotion = false,
    Future<void> Function()? stopIntroPlayback,
  })  : _player = playerCoordinator,
        _preparationPort = preparationPort,
        _assetResolver = assetResolver,
        _intro = introController,
        _titleMusic = titleMusicController,
        _clock = clock,
        _hostBranding = hostBranding,
        _minimumSplashDuration = minimumSplashDuration ??
            hostBranding?.minimumDisplayDuration ??
            const Duration(milliseconds: 7200),
        _reducedMotion = reducedMotion,
        _stopIntroPlayback = stopIntroPlayback ?? _noOp,
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
    _playerSubscription = _player.snapshots.listen(_onPlayerSnapshot);
  }

  final RuntimePlayerCoordinator _player;
  final RuntimeStartupPreparationPort _preparationPort;
  final RuntimePresentationAssetResolver _assetResolver;
  final RuntimeIntroSequenceController _intro;
  final RuntimeTitleMusicController _titleMusic;
  final RuntimeStartupClock _clock;
  final RuntimeHostSplashBranding? _hostBranding;
  final Duration _minimumSplashDuration;
  final bool _reducedMotion;
  final Future<void> Function() _stopIntroPlayback;
  final StreamController<RuntimeStartupSnapshot> _snapshots =
      StreamController<RuntimeStartupSnapshot>.broadcast();
  late final StreamSubscription<RuntimePlayerSnapshot> _playerSubscription;

  RuntimeStartupSnapshot _snapshot;
  RuntimeStartupPreparation? _activePreparation;
  _RuntimeStartupAttemptContext? _activeAttempt;
  RuntimeResolvedAsset? _titleMusicAsset;
  RuntimeStartupPhase? _resumePhase;
  int _generation = 0;
  bool _started = false;
  bool _disposed = false;
  bool _preparationActivated = false;

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
      _titleMusic.pauseForLifecycle(),
      _player.pauseForLifecycle(),
    ]);
  }

  Future<void> resumeFromLifecycle() async {
    _ensureOpen();
    if (_snapshot.isLifecycleActive) return;
    _intro.resumeAfterLifecycle();
    await Future.wait<void>(<Future<void>>[
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
    _activePreparation?.cancel();
    _activeAttempt = null;
    await _playerSubscription.cancel();
    await _stopIntroSafely();
    _intro.skip();
    await _titleMusic.dispose();
    await _player.dispose();
    await _snapshots.close();
  }

  void _startPreparationAttempt() {
    final generation = ++_generation;
    final attempt = _RuntimeStartupAttemptContext();
    _activePreparation?.cancel();
    _activeAttempt = attempt;
    _preparationActivated = false;
    _titleMusicAsset = null;
    _resumePhase = null;
    _publish(
      _snapshot.next(
        phase: RuntimeStartupPhase.splash,
        // A retry never makes a visible loading bar move backwards. The new
        // attempt still recomputes every real unit before it can continue.
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

    // Existing player initialization is the canonical preference/save seam.
    // Both weighted units await the same concurrent load without duplicating it.
    final playerPreparation = _player.initialize();
    final presentationPreparation = _loadPresentationSafely(attempt);
    final preparation = RuntimeStartupPreparation(
      clock: _clock,
      minimumDisplayDuration: _minimumSplashDuration,
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
          return attempt.profile == null
              ? const RuntimeStartupPreparationStepResult.absent()
              : const RuntimeStartupPreparationStepResult.completed();
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
    final video = _resolveMediaSafely(intro.videoPath);
    final poster = switch (intro.posterPath) {
      final String path => _resolveImageSafely(path),
      null => Future<RuntimeResolvedAsset?>.value(),
    };
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
    if (intro.posterPath != null && attempt.introPoster == null) {
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
    final branding = attempt.profile?.branding;
    if (branding == null) {
      return const RuntimeStartupPreparationStepResult.absent();
    }
    final hero = switch (branding.heroPath) {
      final String path => _resolveImageSafely(path),
      null => Future<RuntimeResolvedAsset?>.value(),
    };
    final music = switch (branding.titleMusicPath) {
      final String path => _resolveMediaSafely(path),
      null => Future<RuntimeResolvedAsset?>.value(),
    };
    final assets = await Future.wait<
        RuntimeResolvedAsset?>(<Future<RuntimeResolvedAsset?>>[
      hero,
      music,
    ]);
    attempt.titleHero = assets[0];
    attempt.titleMusic = assets[1];
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
    return diagnostics.isEmpty
        ? const RuntimeStartupPreparationStepResult.completed()
        : RuntimeStartupPreparationStepResult.nonBlockingFailures(diagnostics);
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
    _preparationActivated = true;
    _titleMusicAsset = attempt.titleMusic;
    final resolved = RuntimeStartupResolvedPresentation(
      profile: attempt.profile,
      hostLogo: attempt.hostLogo?.presentationAsset,
      introVideo: attempt.introVideo?.presentationAsset,
      introPoster: attempt.introPoster?.presentationAsset,
      titleHero: attempt.titleHero?.presentationAsset,
      titleMusic: attempt.titleMusic?.presentationAsset,
    );
    final introProfile = attempt.profile?.intro;
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
        progress: 1,
        isPreparationReady: true,
        presentation: resolved,
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
  ProjectPresentationProfile? profile;
  bool presentationLoadFailed = false;
  RuntimeResolvedAsset? hostLogo;
  RuntimeResolvedAsset? introVideo;
  RuntimeResolvedAsset? introPoster;
  RuntimeResolvedAsset? titleHero;
  RuntimeResolvedAsset? titleMusic;
}
