import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'support/runtime_player_test_harness.dart';

void main() {
  test('startup snapshots enforce bounded immutable presentation state', () {
    expect(
      () => RuntimeStartupSnapshot(
        revision: 0,
        phase: RuntimeStartupPhase.preparing,
        progress: 1.1,
        currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
        isPreparationReady: false,
        isMinimumElapsed: false,
        isLifecycleActive: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => RuntimeStartupSnapshot(
        revision: 0,
        phase: RuntimeStartupPhase.lifecyclePaused,
        progress: 0,
        currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
        isPreparationReady: false,
        isMinimumElapsed: false,
        isLifecycleActive: true,
      ),
      throwsArgumentError,
    );
    final diagnostics = <RuntimeStartupDiagnostic>[
      const RuntimeStartupDiagnostic(code: 'warning', safeMessage: 'Warning'),
    ];
    final snapshot = RuntimeStartupSnapshot(
      revision: 0,
      phase: RuntimeStartupPhase.preparing,
      progress: 0,
      currentStage: RuntimeStartupPreparationStage.manifestAndIdentity,
      isPreparationReady: false,
      isMinimumElapsed: false,
      isLifecycleActive: true,
      diagnostics: diagnostics,
    );
    diagnostics.clear();

    expect(snapshot.diagnostics, hasLength(1));
    expect(
      () => snapshot.diagnostics.add(
        const RuntimeStartupDiagnostic(code: 'other', safeMessage: 'Other'),
      ),
      throwsUnsupportedError,
    );
  });

  test('owns boot through prompt with monotone revisions and no session',
      () async {
    final harness = _RuntimeStartupTestHarness();
    addTearDown(harness.dispose);
    final revisions = <int>[];
    final progress = <double>[];
    final subscription = harness.startup.snapshots.listen((snapshot) {
      revisions.add(snapshot.revision);
      progress.add(snapshot.progress);
    });
    addTearDown(subscription.cancel);

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.preparing);
    harness.startup.start();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);

    await _flushEvents();
    expect(harness.startup.snapshot.progress, 1);
    expect(harness.startup.snapshot.isPreparationReady, isTrue);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);
    expect(harness.player.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.player.adapters, isEmpty);

    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.startup.snapshot.playerSnapshot?.phase,
        RuntimePlayerPhase.title);
    expect(revisions, orderedEquals([...revisions]..sort()));
    expect(revisions.toSet(), hasLength(revisions.length));
    expect(progress, orderedEquals([...progress]..sort()));
  });

  test('finishes only the curtain when loading completes before the hold',
      () async {
    final clock = _ManualStartupClock();
    final harness = _RuntimeStartupTestHarness(clock: clock);
    addTearDown(harness.dispose);

    harness.startup.start();
    await _flushEvents();

    expect(harness.startup.snapshot.isPreparationReady, isTrue);
    expect(clock.pendingDurations, contains(const Duration(seconds: 7)));
    expect(
      clock.pendingDurations,
      contains(const Duration(milliseconds: 5704)),
    );

    clock.elapse(const Duration(milliseconds: 5704));
    clock.elapse(const Duration(seconds: 7));
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);
    expect(
      clock.pendingDurations,
      orderedEquals(<Duration>[const Duration(milliseconds: 280)]),
    );

    clock.elapse(const Duration(milliseconds: 280));
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
  });

  test('awaits the held timeline exit from real loading completion', () async {
    final loadingGate = Completer<void>();
    final clock = _ManualStartupClock();
    final harness = _RuntimeStartupTestHarness(
      clock: clock,
      initialMapPreloadPort: _MemoryInitialMapPreloadPort(
        gate: loadingGate.future,
      ),
    );
    addTearDown(harness.dispose);

    harness.startup.start();
    await _flushEvents();

    clock.elapse(const Duration(milliseconds: 5704));
    clock.elapse(const Duration(seconds: 7));
    await _flushEvents();

    expect(harness.startup.snapshot.isMinimumElapsed, isTrue);
    expect(harness.startup.snapshot.isPreparationReady, isFalse);

    loadingGate.complete();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);
    expect(harness.startup.snapshot.progress, 1);
    expect(
      clock.pendingDurations,
      orderedEquals(<Duration>[const Duration(milliseconds: 1296)]),
    );

    clock.elapse(const Duration(milliseconds: 1296));
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);
    expect(
      clock.pendingDurations,
      orderedEquals(<Duration>[const Duration(milliseconds: 280)]),
    );

    clock.elapse(const Duration(milliseconds: 280));
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
  });

  test('preloads the latest launchable save map before leaving the splash',
      () async {
    final gate = Completer<void>();
    final address = SaveSlotAddress(
      gameId: 'com.pokemap.runtime-player-test',
      profileId: 'player',
      slotId: 'main',
    );
    final preloader = _MemoryInitialMapPreloadPort(
      gate: gate.future,
      reportedProgress: 0.5,
    );
    final harness = _RuntimeStartupTestHarness(
      latestSave: PlayerSaveSummary(
        address: address,
        updatedAt: DateTime.utc(2026, 8, 9),
        playTimeSeconds: 120,
        status: SaveStatus.active,
        canContinue: true,
      ),
      initialMapPreloadPort: preloader,
    );
    addTearDown(harness.dispose);

    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(preloader.requests, hasLength(1));
    expect(
      preloader.requests.single.mode,
      RuntimeInitialMapPreloadMode.continueGame,
    );
    expect(preloader.requests.single.saveAddress, address);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);
    expect(harness.startup.snapshot.isPreparationReady, isFalse);
    expect(harness.startup.snapshot.progress, closeTo(0.825, 0.0001));

    gate.complete();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.startup.snapshot.isPreparationReady, isTrue);
  });

  test('preloads the project new game map when no save is launchable',
      () async {
    final preloader = _MemoryInitialMapPreloadPort();
    final harness = _RuntimeStartupTestHarness(
      initialMapPreloadPort: preloader,
    );
    addTearDown(harness.dispose);

    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(preloader.requests, hasLength(1));
    expect(
      preloader.requests.single.mode,
      RuntimeInitialMapPreloadMode.newGame,
    );
    expect(preloader.requests.single.saveAddress, isNull);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
  });

  test('an invalid discovered save falls back to the authored new game map',
      () async {
    final preloader = _MemoryInitialMapPreloadPort();
    final harness = _RuntimeStartupTestHarness(
      latestSave: PlayerSaveSummary(
        address: SaveSlotAddress(
          gameId: 'com.pokemap.runtime-player-test',
          profileId: 'player',
          slotId: 'main',
        ),
        updatedAt: DateTime.utc(2026, 8, 9),
        playTimeSeconds: 120,
        status: SaveStatus.active,
        canContinue: false,
        safeUnavailableReason: 'Save incompatible.',
      ),
      initialMapPreloadPort: preloader,
    );
    addTearDown(harness.dispose);

    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(preloader.requests, hasLength(1));
    expect(
      preloader.requests.single.mode,
      RuntimeInitialMapPreloadMode.newGame,
    );
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
  });

  test('preloads only the selected responsive media and switches on rotation',
      () async {
    final assets = _MemoryPresentationAssetResolver();
    const landscape = ProjectVideoVariantProfile(
      videoPath: 'assets/landscape.mp4',
      posterPath: 'assets/landscape.png',
      durationMilliseconds: 7000,
      width: 1920,
      height: 1080,
      bitrateKbps: 3000,
      sizeBytes: 5000000,
      videoCodec: 'h264',
    );
    const portrait = ProjectVideoVariantProfile(
      videoPath: 'assets/portrait.mp4',
      posterPath: 'assets/portrait.png',
      durationMilliseconds: 7000,
      width: 1080,
      height: 1920,
      bitrateKbps: 3000,
      sizeBytes: 5000000,
      videoCodec: 'h264',
    );
    final harness = _RuntimeStartupTestHarness(
      assetResolver: assets,
      presentationOrientation: RuntimePresentationOrientation.portrait,
      profile: const ProjectPresentationProfile(
        intro: ProjectIntroVideoProfile(
          media: ProjectResponsiveVideoProfile(
            landscape: landscape,
            portrait: portrait,
          ),
        ),
        titleMotion: ProjectTitleMotionProfile(
          promptLoop: ProjectResponsiveVideoProfile(
            landscape: landscape,
            portrait: portrait,
          ),
          menuLoop: ProjectResponsiveVideoProfile(
            landscape: landscape,
            portrait: portrait,
          ),
        ),
      ),
    );
    addTearDown(harness.dispose);

    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(assets.resolvedMediaPaths, isNot(contains('assets/landscape.mp4')));
    expect(
      harness.startup.snapshot.presentation?.orientation,
      RuntimePresentationOrientation.portrait,
    );
    expect(
      harness.startup.snapshot.presentation?.introVideo?.assetId,
      'assets/portrait.mp4',
    );
    expect(
      harness.startup.snapshot.presentation?.titlePromptVideo?.assetId,
      'assets/portrait.mp4',
    );
    expect(
      harness.startup.snapshot.presentation?.titleMenuPoster?.assetId,
      'assets/portrait.png',
    );

    await harness.startup.updatePresentationOrientation(
      RuntimePresentationOrientation.landscape,
    );

    expect(assets.resolvedMediaPaths, contains('assets/landscape.mp4'));
    expect(
      harness.startup.snapshot.presentation?.orientation,
      RuntimePresentationOrientation.landscape,
    );
    expect(
      harness.startup.snapshot.presentation?.titleMenuVideo?.assetId,
      'assets/landscape.mp4',
    );
  });

  test('a ready splash cannot be skipped before its minimum', () async {
    final harness = _RuntimeStartupTestHarness();
    addTearDown(harness.dispose);
    harness.startup.start();
    await _flushEvents();

    expect(harness.startup.snapshot.canSkipSplash, isFalse);
    expect(harness.startup.snapshot.isMinimumElapsed, isFalse);
    final skipped = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.skipSplash,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );

    expect(skipped.status, RuntimeStartupCommandStatus.unavailable);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.splash);

    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
  });

  test('skip is revisioned, stops intro first, then starts title music',
      () async {
    final stopGate = Completer<void>();
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
      stopIntroPlayback: () => stopGate.future,
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(harness.audio.played, isEmpty);
    final introRevision = harness.startup.snapshot.revision;
    final skipFuture = harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.skipIntro,
        snapshotRevision: introRevision,
      ),
    );
    await _flushEvents();

    expect(harness.audio.played, isEmpty);
    expect(harness.startup.snapshot.isTransitioning, isTrue);
    stopGate.complete();
    final skip = await skipFuture;

    expect(skip.status, RuntimeStartupCommandStatus.accepted);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.audio.played, <String>['/project/title.ogg']);

    final stale = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: introRevision,
      ),
    );
    expect(stale.status, RuntimeStartupCommandStatus.stale);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);

    final pressed = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );
    expect(pressed.status, RuntimeStartupCommandStatus.accepted);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titleMenu);
    expect(harness.audio.played, hasLength(1));
  });

  test('duplicate skip is idempotent while media shutdown is pending',
      () async {
    final stopGate = Completer<void>();
    var stopCalls = 0;
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
      stopIntroPlayback: () {
        stopCalls++;
        return stopGate.future;
      },
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    final revision = harness.startup.snapshot.revision;

    final firstSkip = harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.skipIntro,
        snapshotRevision: revision,
      ),
    );
    final duplicateSkip = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.skipIntro,
        snapshotRevision: revision,
      ),
    );

    expect(duplicateSkip.status, RuntimeStartupCommandStatus.stale);
    expect(stopCalls, 1);
    stopGate.complete();
    expect(
      (await firstSkip).status,
      RuntimeStartupCommandStatus.accepted,
    );
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.audio.played, hasLength(1));
  });

  test('reduced motion uses poster and continue cannot cross the prompt',
      () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
      reducedMotion: true,
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(harness.startup.snapshot.introPhase, RuntimeIntroPhase.poster);
    final revision = harness.startup.snapshot.revision;
    final continued = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.continueFromPoster,
        snapshotRevision: revision,
      ),
    );

    expect(continued.status, RuntimeStartupCommandStatus.accepted);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    final samePress = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: revision,
      ),
    );
    expect(samePress.status, RuntimeStartupCommandStatus.stale);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
  });

  test('video failure falls back to poster and replay rejects old callbacks',
      () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    final firstPlaybackRevision = harness.startup.snapshot.revision;

    final failed = await harness.startup.introPlaybackFailed(
      snapshotRevision: firstPlaybackRevision,
      reason: 'decoder unavailable',
    );
    expect(failed.status, RuntimeStartupCommandStatus.accepted);
    expect(harness.startup.snapshot.introPhase, RuntimeIntroPhase.poster);
    expect(harness.startup.snapshot.canReplayIntro, isTrue);

    final replayed = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.replayIntro,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );
    expect(replayed.status, RuntimeStartupCommandStatus.accepted);
    expect(harness.startup.snapshot.introPhase, RuntimeIntroPhase.playing);

    final lateCompletion = await harness.startup.introPlaybackCompleted(
      snapshotRevision: firstPlaybackRevision,
    );
    expect(lateCompletion.status, RuntimeStartupCommandStatus.stale);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
  });

  test('natural intro completion reaches the title exactly once', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    final revision = harness.startup.snapshot.revision;

    final completed = await harness.startup.introPlaybackCompleted(
      snapshotRevision: revision,
    );
    final duplicate = await harness.startup.introPlaybackCompleted(
      snapshotRevision: revision,
    );

    expect(completed.status, RuntimeStartupCommandStatus.accepted);
    expect(duplicate.status, RuntimeStartupCommandStatus.stale);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.audio.played, hasLength(1));
  });

  test('presentation loading failure is non-blocking and diagnosed', () async {
    final harness = _RuntimeStartupTestHarness(
      preparationPort: _MemoryStartupPreparationPort(
        failPresentation: true,
      ),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(
      harness.startup.snapshot.diagnostics.map((item) => item.code),
      contains('presentationProfileUnavailable'),
    );
  });

  test('optional title artwork failure preserves resolved music', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(includeIntro: false),
      assetResolver: _MemoryPresentationAssetResolver(
        failingImages: const <String>{'assets/hero.png'},
      ),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.startup.snapshot.presentation?.titleHero, isNull);
    expect(
      harness.startup.snapshot.presentation?.titleMusic?.assetId,
      'assets/title.ogg',
    );
    expect(harness.audio.played, <String>['/project/title.ogg']);
    expect(
      harness.startup.snapshot.diagnostics.map((item) => item.code),
      contains('titleHeroUnavailable'),
    );
  });

  test('optional poster failure preserves the playable intro video', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroOnly(),
      assetResolver: _MemoryPresentationAssetResolver(
        failingImages: const <String>{'assets/intro-poster.png'},
      ),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(harness.startup.snapshot.introPhase, RuntimeIntroPhase.playing);
    expect(
      harness.startup.snapshot.presentation?.introVideo?.assetId,
      'assets/intro.mp4',
    );
    expect(harness.startup.snapshot.presentation?.introPoster, isNull);
    expect(
      harness.startup.snapshot.diagnostics.map((item) => item.code),
      contains('introPosterUnavailable'),
    );
  });

  test('unavailable video falls back to its resolved poster', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroOnly(),
      assetResolver: _MemoryPresentationAssetResolver(
        failingMedia: const <String>{'assets/intro.mp4'},
      ),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(harness.startup.snapshot.introPhase, RuntimeIntroPhase.poster);
    expect(harness.startup.snapshot.presentation?.introVideo, isNull);
    expect(
      harness.startup.snapshot.presentation?.introPoster?.assetId,
      'assets/intro-poster.png',
    );
  });

  test('all optional media failures retain independent diagnostics', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
      assetResolver: _MemoryPresentationAssetResolver(
        failingImages: const <String>{
          'assets/hero.png',
          'assets/intro-poster.png',
        },
        failingMedia: const <String>{
          'assets/intro.mp4',
          'assets/title.ogg',
        },
      ),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(
      harness.startup.snapshot.diagnostics.map((item) => item.code),
      containsAll(<String>{
        'introVideoUnavailable',
        'introPosterUnavailable',
        'titleMusicUnavailable',
        'titleHeroUnavailable',
      }),
    );
  });

  test('lifecycle preserves splash, intro and prompt resume phases', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
    );
    addTearDown(harness.dispose);
    harness.startup.start();

    await harness.startup.pauseForLifecycle();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.lifecyclePaused);
    expect(
      harness.startup.snapshot.suspendedPhase,
      RuntimeStartupPhase.splash,
    );
    harness.clock.elapseMinimum();
    await _flushEvents();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.lifecyclePaused);
    expect(
      harness.startup.snapshot.suspendedPhase,
      RuntimeStartupPhase.intro,
    );

    await harness.startup.resumeFromLifecycle();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(harness.intro.phase, RuntimeIntroPhase.playing);

    await harness.startup.pauseForLifecycle();
    expect(harness.intro.phase, RuntimeIntroPhase.paused);
    await harness.startup.resumeFromLifecycle();
    expect(harness.intro.phase, RuntimeIntroPhase.playing);

    await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.skipIntro,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(harness.audio.stopCount, 0);
    await harness.startup.pauseForLifecycle();
    expect(harness.audio.stopCount, 1);
    await harness.startup.resumeFromLifecycle();
    expect(harness.audio.played, hasLength(2));
  });

  test('blocking preparation retries and ignores the previous attempt',
      () async {
    final firstManifest = Completer<void>();
    final port = _MemoryStartupPreparationPort(
      manifestGates: <Future<void>>[firstManifest.future, Future<void>.value()],
      failManifestAttempts: const <int>{1},
    );
    final harness = _RuntimeStartupTestHarness(
      preparationPort: port,
      clock: _ImmediateStartupClock(),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    firstManifest.complete();
    await _flushEvents();

    expect(
      harness.startup.snapshot.phase,
      RuntimeStartupPhase.recoverableError,
    );
    final retry = await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.retryPreparation,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );
    expect(retry.status, RuntimeStartupCommandStatus.accepted);
    await _flushEvents();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titlePrompt);
    expect(port.manifestAttempts, 2);
  });

  test('late work from a failed attempt cannot alter the retry snapshot',
      () async {
    final oldMediaGate = Completer<void>();
    final resolver = _MemoryPresentationAssetResolver(
      mediaGates: <Future<void>>[oldMediaGate.future, Future<void>.value()],
      mediaAssetIds: const <String>['old-intro', 'new-intro'],
    );
    final port = _MemoryStartupPreparationPort(
      profile: _presentationWithIntroOnly(),
      failManifestAttempts: const <int>{1},
    );
    final harness = _RuntimeStartupTestHarness(
      preparationPort: port,
      assetResolver: resolver,
      clock: _ImmediateStartupClock(),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    await _flushEvents();
    expect(
      harness.startup.snapshot.phase,
      RuntimeStartupPhase.recoverableError,
    );

    await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.retryPreparation,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );
    await _flushEvents();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(
      harness.startup.snapshot.presentation?.introVideo?.assetId,
      'new-intro',
    );
    final revisionAfterRetry = harness.startup.snapshot.revision;
    final progressAfterRetry = harness.startup.snapshot.progress;

    oldMediaGate.complete();
    await _flushEvents();

    expect(harness.startup.snapshot.revision, revisionAfterRetry);
    expect(harness.startup.snapshot.progress, progressAfterRetry);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    expect(
      harness.startup.snapshot.presentation?.introVideo?.assetId,
      'new-intro',
    );
  });

  test('dispose during preparation ignores late work and closes resources',
      () async {
    final manifestGate = Completer<void>();
    final port = _MemoryStartupPreparationPort(
      manifestGates: <Future<void>>[manifestGate.future],
    );
    final preloader = _MemoryInitialMapPreloadPort();
    final harness = _RuntimeStartupTestHarness(
      preparationPort: port,
      initialMapPreloadPort: preloader,
    );
    final snapshots = <RuntimeStartupSnapshot>[];
    final subscription = harness.startup.snapshots.listen(snapshots.add);
    harness.startup.start();
    await _flushEvents();
    final countBeforeDispose = snapshots.length;

    await harness.startup.dispose();
    manifestGate.complete();
    harness.clock.elapseMinimum();
    await _flushEvents();

    expect(harness.startup.isDisposed, isTrue);
    expect(snapshots, hasLength(countBeforeDispose));
    expect(harness.audio.stopCount, lessThanOrEqualTo(1));
    expect(preloader.clearCount, 2);
    await subscription.cancel();
  });

  test('dispose during intro blocks late callbacks and closes the stream',
      () async {
    final stopGate = Completer<void>();
    var stopCalls = 0;
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(),
      stopIntroPlayback: () {
        stopCalls++;
        return stopGate.future;
      },
    );
    final snapshots = <RuntimeStartupSnapshot>[];
    final streamDone = Completer<void>();
    harness.startup.snapshots.listen(
      snapshots.add,
      onDone: streamDone.complete,
    );
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.intro);
    final playbackRevision = harness.startup.snapshot.revision;
    final countBeforeDispose = snapshots.length;

    final disposeFuture = harness.startup.dispose();
    await _flushEvents();
    final lateCallback = await harness.startup.introPlaybackCompleted(
      snapshotRevision: playbackRevision,
    );

    expect(lateCallback.status, RuntimeStartupCommandStatus.unavailable);
    expect(stopCalls, 1);
    expect(snapshots, hasLength(countBeforeDispose));
    stopGate.complete();
    await disposeFuture;
    await streamDone.future;
    expect(harness.player.coordinator.isDisposed, isTrue);
    expect(harness.startup.isDisposed, isTrue);
  });

  test('title music is stopped before the player session starts', () async {
    final stopGate = Completer<void>();
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(includeIntro: false),
      audioStopGate: stopGate,
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );

    final launchFuture = harness.startup.dispatchPlayerCommand(
      startupSnapshotRevision: harness.startup.snapshot.revision,
      command: RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.player.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );
    await _flushEvents();

    expect(harness.audio.stopCount, 1);
    expect(harness.player.source.requests, isEmpty);
    stopGate.complete();
    final result = await launchFuture;

    expect(result.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.player.source.requests, hasLength(1));
    expect(
      harness.startup.snapshot.phase,
      RuntimeStartupPhase.launchingSession,
    );
  });

  test('returning from a session re-enters the runtime title menu', () async {
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(includeIntro: false),
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );
    final launched = await harness.startup.dispatchPlayerCommand(
      startupSnapshotRevision: harness.startup.snapshot.revision,
      command: RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.player.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );
    expect(launched.status, RuntimePlayerCommandStatus.accepted);
    harness.player.adapter.emitRunning();
    await harness.player.coordinator.settle();
    await _flushEvents();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.completed);

    await openHarnessPause(harness.player);
    harness.player.adapter.checkpoint = testPlayerCheckpoint();
    final returned = await harness.player.coordinator.dispatch(
      RuntimePlayerCommand(
        action: RuntimePlayerAction.returnToTitle,
        snapshotRevision: harness.player.coordinator.snapshot.revision,
      ),
    );
    await _flushEvents();

    expect(returned.status, RuntimePlayerCommandStatus.accepted);
    expect(harness.player.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titleMenu);
    expect(harness.audio.played, hasLength(2));
  });

  test('lifecycle pause cancels launch before session allocation', () async {
    final stopGate = Completer<void>();
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(includeIntro: false),
      audioStopGate: stopGate,
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );

    final launchFuture = harness.startup.dispatchPlayerCommand(
      startupSnapshotRevision: harness.startup.snapshot.revision,
      command: RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.player.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );
    await _flushEvents();
    final pauseFuture = harness.startup.pauseForLifecycle();

    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.lifecyclePaused);
    stopGate.complete();
    expect(
      (await launchFuture).status,
      RuntimePlayerCommandStatus.cancelled,
    );
    await pauseFuture;
    expect(harness.player.source.requests, isEmpty);
    expect(harness.startup.snapshot.isTransitioning, isFalse);

    await harness.startup.resumeFromLifecycle();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titleMenu);
    expect(harness.audio.played, hasLength(2));
  });

  test('lifecycle pause invalidates an in-flight descriptor allocation',
      () async {
    final descriptorGate = Completer<void>();
    final harness = _RuntimeStartupTestHarness(
      profile: _presentationWithIntroAndMusic(includeIntro: false),
      descriptorGate: descriptorGate.future,
    );
    addTearDown(harness.dispose);
    harness.startup.start();
    harness.clock.elapseMinimum();
    await _flushEvents();
    await harness.startup.dispatch(
      RuntimeStartupCommand(
        action: RuntimeStartupAction.pressStart,
        snapshotRevision: harness.startup.snapshot.revision,
      ),
    );

    final launchFuture = harness.startup.dispatchPlayerCommand(
      startupSnapshotRevision: harness.startup.snapshot.revision,
      command: RuntimePlayerCommand(
        action: RuntimePlayerAction.newGame,
        snapshotRevision: harness.player.coordinator.snapshot.revision,
        payload: const RuntimePlayerLoadSlot(
          profileId: 'player',
          slotId: 'slot_1',
        ),
      ),
    );
    await _flushEvents();
    expect(harness.player.source.requests, hasLength(1));

    final pauseFuture = harness.startup.pauseForLifecycle();
    descriptorGate.complete();
    expect(
      (await launchFuture).status,
      RuntimePlayerCommandStatus.cancelled,
    );
    await pauseFuture;

    expect(harness.player.adapters, isEmpty);
    expect(harness.player.coordinator.snapshot.phase, RuntimePlayerPhase.title);
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.lifecyclePaused);
    await harness.startup.resumeFromLifecycle();
    expect(harness.startup.snapshot.phase, RuntimeStartupPhase.titleMenu);
    expect(harness.audio.played, hasLength(2));
  });
}

ProjectPresentationProfile _presentationWithIntroAndMusic({
  bool includeIntro = true,
}) {
  return ProjectPresentationProfile(
    branding: const ProjectBrandingProfile(
      heroPath: 'assets/hero.png',
      titleMusicPath: 'assets/title.ogg',
    ),
    intro: includeIntro
        ? const ProjectIntroVideoProfile(
            media: ProjectResponsiveVideoProfile(
              landscape: ProjectVideoVariantProfile(
                videoPath: 'assets/intro.mp4',
                posterPath: 'assets/intro-poster.png',
                durationMilliseconds: 5000,
                width: 1280,
                height: 720,
                bitrateKbps: 4000,
                sizeBytes: 1024,
                videoCodec: 'h264',
                audioCodec: 'aac',
              ),
            ),
          )
        : null,
  );
}

ProjectPresentationProfile _presentationWithIntroOnly() {
  return const ProjectPresentationProfile(
    intro: ProjectIntroVideoProfile(
      media: ProjectResponsiveVideoProfile(
        landscape: ProjectVideoVariantProfile(
          videoPath: 'assets/intro.mp4',
          posterPath: 'assets/intro-poster.png',
          durationMilliseconds: 5000,
          width: 1280,
          height: 720,
          bitrateKbps: 4000,
          sizeBytes: 1024,
          videoCodec: 'h264',
          audioCodec: 'aac',
        ),
      ),
    ),
  );
}

final class _RuntimeStartupTestHarness {
  _RuntimeStartupTestHarness({
    ProjectPresentationProfile? profile,
    PlayerSaveSummary? latestSave,
    _MemoryStartupPreparationPort? preparationPort,
    _MemoryPresentationAssetResolver? assetResolver,
    RuntimeInitialMapPreloadPort? initialMapPreloadPort,
    RuntimeStartupClock? clock,
    Future<void> Function()? stopIntroPlayback,
    bool reducedMotion = false,
    Completer<void>? audioStopGate,
    Future<void>? descriptorGate,
    RuntimePresentationOrientation presentationOrientation =
        RuntimePresentationOrientation.landscape,
  })  : player = RuntimePlayerTestHarness(
          latestSave: latestSave,
          descriptorGate: descriptorGate,
        ),
        clock = clock is _ControlledStartupClock
            ? clock
            : clock == null
                ? _ControlledStartupClock()
                : _ControlledStartupClock() {
    effectiveClock = clock ?? this.clock;
    intro = RuntimeIntroSequenceController();
    audio = _FakeAudioDriver(stopGate: audioStopGate);
    music = RuntimeTitleMusicController(driver: audio);
    startup = RuntimeStartupCoordinator(
      playerCoordinator: player.coordinator,
      preparationPort:
          preparationPort ?? _MemoryStartupPreparationPort(profile: profile),
      initialMapPreloadPort:
          initialMapPreloadPort ?? _MemoryInitialMapPreloadPort(),
      assetResolver: assetResolver ?? _MemoryPresentationAssetResolver(),
      introController: intro,
      titleMusicController: music,
      clock: effectiveClock,
      minimumSplashDuration: const Duration(seconds: 7),
      reducedMotion: reducedMotion,
      presentationOrientation: presentationOrientation,
      stopIntroPlayback: stopIntroPlayback,
    );
  }

  final RuntimePlayerTestHarness player;
  final _ControlledStartupClock clock;
  late final RuntimeStartupClock effectiveClock;
  late final RuntimeIntroSequenceController intro;
  late final _FakeAudioDriver audio;
  late final RuntimeTitleMusicController music;
  late final RuntimeStartupCoordinator startup;

  Future<void> dispose() => startup.dispose();
}

final class _MemoryInitialMapPreloadPort
    implements RuntimeInitialMapPreloadPort {
  _MemoryInitialMapPreloadPort({this.gate, this.reportedProgress});

  final Future<void>? gate;
  final double? reportedProgress;
  final List<RuntimeInitialMapPreloadRequest> requests =
      <RuntimeInitialMapPreloadRequest>[];
  int clearCount = 0;

  @override
  Future<void> preloadInitialMap(
    RuntimeInitialMapPreloadRequest request, {
    RuntimeInitialMapPreloadProgressSink? onProgress,
  }) async {
    requests.add(request);
    if (reportedProgress case final value?) {
      onProgress?.call(
        RuntimeInitialMapPreloadProgress(
          stage: RuntimeInitialMapPreloadStage.mapData,
          value: value,
        ),
      );
    }
    await gate;
  }

  @override
  void clear() {
    clearCount++;
  }
}

final class _MemoryStartupPreparationPort
    implements RuntimeStartupPreparationPort {
  _MemoryStartupPreparationPort({
    this.profile,
    this.manifestGates = const <Future<void>>[],
    this.failManifestAttempts = const <int>{},
    this.failPresentation = false,
  });

  final ProjectPresentationProfile? profile;
  final List<Future<void>> manifestGates;
  final Set<int> failManifestAttempts;
  final bool failPresentation;
  int manifestAttempts = 0;

  @override
  Future<ProjectPresentationProfile?> loadPresentationProfile() async {
    if (failPresentation) throw StateError('presentation unavailable');
    return profile;
  }

  @override
  Future<void> prepareManifestAndIdentity() async {
    manifestAttempts++;
    if (manifestAttempts <= manifestGates.length) {
      await manifestGates[manifestAttempts - 1];
    }
    if (failManifestAttempts.contains(manifestAttempts)) {
      throw StateError('manifest unavailable');
    }
  }
}

final class _MemoryPresentationAssetResolver
    implements RuntimePresentationAssetResolver {
  _MemoryPresentationAssetResolver({
    this.mediaGates = const <Future<void>>[],
    this.mediaAssetIds = const <String>[],
    this.failingImages = const <String>{},
    this.failingMedia = const <String>{},
  });

  final List<Future<void>> mediaGates;
  final List<String> mediaAssetIds;
  final Set<String> failingImages;
  final Set<String> failingMedia;
  int mediaCalls = 0;
  final List<String> resolvedMediaPaths = <String>[];

  @override
  Future<bool> exists(String projectRelativePath) async => true;

  @override
  Future<RuntimeResolvedAsset?> resolveImage(String projectRelativePath) async {
    if (failingImages.contains(projectRelativePath)) {
      throw StateError('image unavailable');
    }
    return RuntimeResolvedAsset(
      assetId: projectRelativePath,
      resolvedUri: Uri.file('/project/${projectRelativePath.split('/').last}'),
      mediaType: 'image/png',
    );
  }

  @override
  Future<RuntimeResolvedAsset?> resolveMedia(String projectRelativePath) async {
    resolvedMediaPaths.add(projectRelativePath);
    mediaCalls++;
    final callIndex = mediaCalls - 1;
    if (callIndex < mediaGates.length) {
      await mediaGates[callIndex];
    }
    if (failingMedia.contains(projectRelativePath)) {
      throw StateError('media unavailable');
    }
    return RuntimeResolvedAsset(
      assetId: callIndex < mediaAssetIds.length
          ? mediaAssetIds[callIndex]
          : projectRelativePath,
      resolvedUri: Uri.file('/project/${projectRelativePath.split('/').last}'),
      mediaType:
          projectRelativePath.endsWith('.mp4') ? 'video/mp4' : 'audio/ogg',
    );
  }
}

final class _ControlledStartupClock implements RuntimeStartupClock {
  final Completer<void> _minimum = Completer<void>();

  void elapseMinimum() {
    if (!_minimum.isCompleted) _minimum.complete();
  }

  @override
  Future<void> delay(Duration duration) => _minimum.future;
}

final class _ImmediateStartupClock implements RuntimeStartupClock {
  @override
  Future<void> delay(Duration duration) => Future<void>.value();
}

final class _ManualStartupClock implements RuntimeStartupClock {
  final List<_ManualStartupDelay> _delays = <_ManualStartupDelay>[];

  List<Duration> get pendingDurations => <Duration>[
        for (final delay in _delays)
          if (!delay.completer.isCompleted) delay.duration,
      ];

  void elapse(Duration duration) {
    final delay = _delays.firstWhere(
      (delay) => !delay.completer.isCompleted && delay.duration == duration,
    );
    delay.completer.complete();
  }

  @override
  Future<void> delay(Duration duration) {
    final delay = _ManualStartupDelay(duration);
    _delays.add(delay);
    return delay.completer.future;
  }
}

final class _ManualStartupDelay {
  _ManualStartupDelay(this.duration);

  final Duration duration;
  final Completer<void> completer = Completer<void>();
}

final class _FakeAudioDriver implements FlameCinematicAudioDriver {
  _FakeAudioDriver({this.stopGate});

  final Completer<void>? stopGate;
  final List<String> played = <String>[];
  int stopCount = 0;

  @override
  Future<Object> play(
    String path, {
    required double volume,
    required bool loop,
  }) async {
    played.add(path);
    return Object();
  }

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async {
    stopCount++;
    await stopGate?.future;
  }
}

Future<void> _flushEvents() async {
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
}
