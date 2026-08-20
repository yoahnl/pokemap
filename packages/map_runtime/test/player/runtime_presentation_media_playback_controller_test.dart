import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('mixer-managed video follows master bus and ducking before play',
      () async {
    final driver = _RecordingVideoDriver();
    final mixer = RuntimeAudioMixer(
      mix: const RuntimeAudioMix(masterVolume: 0.5, musicVolume: 0.4),
    );
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
      audioMixer: mixer,
    );

    final snapshot = await controller.playVideo(
      'opening-video',
      audioMode: RuntimePresentationVideoAudioMode.mixerManaged,
      sourceVolume: 0.5,
    );
    await mixer.setDucking(
      owner: 'voice',
      bus: RuntimeAudioBus.music,
      gain: 0.25,
    );
    await mixer.transitionTo(
      const RuntimeAudioMix(masterVolume: 0.8, musicVolume: 0.5),
    );

    expect(
        snapshot.status, RuntimePresentationMediaPlaybackStatus.playingVideo);
    expect(snapshot.resolvedMediaId, 'opening-video');
    expect(driver.events, [
      'prepare:opening.mp4:0.1',
      'play:video-1',
      'volume:video-1:0.025',
      'volume:video-1:0.05',
    ]);
  });

  test('muted video never registers an audible mixer channel', () async {
    final driver = _RecordingVideoDriver();
    final mixer = RuntimeAudioMixer();
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
      audioMixer: mixer,
    );

    await controller.playVideo('opening-video');
    await mixer.transitionTo(
      const RuntimeAudioMix(masterVolume: 0.2, musicVolume: 0.3),
    );

    expect(driver.events, [
      'prepare:opening.mp4:0.0',
      'play:video-1',
    ]);
  });

  test('decoder failure follows canonical fallback to a poster', () async {
    final driver = _RecordingVideoDriver()..failingSources.add('opening.mp4');
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
    );

    final snapshot = await controller.playVideo('opening-video');

    expect(
        snapshot.status, RuntimePresentationMediaPlaybackStatus.showingPoster);
    expect(snapshot.resolvedMediaId, 'opening-poster');
    expect(snapshot.usedFallback, isTrue);
    expect(snapshot.diagnosticCode, isNull);
    expect(driver.events, [
      'prepare:opening.mp4:0.0',
    ]);
  });

  test('replacement disposes the old decoder before allocating the next',
      () async {
    final driver = _RecordingVideoDriver();
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
    );

    await controller.playVideo('opening-video');
    await controller.playVideo('chapter-video');

    expect(driver.events, [
      'prepare:opening.mp4:0.0',
      'play:video-1',
      'dispose:video-1',
      'prepare:chapter.mp4:0.0',
      'play:video-2',
    ]);
    expect(driver.maximumActiveDecoders, 1);
  });

  test('failed eviction blocks replacement with a stable diagnostic', () async {
    final driver = _RecordingVideoDriver();
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
    );
    await controller.playVideo('opening-video');
    driver.failDisposals = true;

    final snapshot = await controller.playVideo('chapter-video');

    expect(snapshot.status, RuntimePresentationMediaPlaybackStatus.failed);
    expect(
      snapshot.diagnosticCode,
      RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
    );
    expect(driver.events, [
      'prepare:opening.mp4:0.0',
      'play:video-1',
      'dispose:video-1',
    ]);
    expect(driver.maximumActiveDecoders, 1);
  });

  test('missing media fails with a stable path-free diagnostic', () async {
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: _RecordingVideoDriver(),
    );

    final snapshot = await controller.playVideo('missing-video');

    expect(snapshot.status, RuntimePresentationMediaPlaybackStatus.failed);
    expect(
      snapshot.diagnosticCode,
      PresentationDiagnosticCodes.mediaMissing,
    );
    expect(snapshot.diagnosticSeverity, PresentationDiagnosticSeverity.error);
    expect(snapshot.diagnosticMessage, 'Presentation media is unavailable.');
    expect(snapshot.diagnosticMessage, isNot(contains('/')));
  });

  test('lifecycle pause and resume control the active decoder', () async {
    final driver = _RecordingVideoDriver();
    final mixer = RuntimeAudioMixer();
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
      audioMixer: mixer,
    );

    await controller.playVideo(
      'opening-video',
      audioMode: RuntimePresentationVideoAudioMode.mixerManaged,
    );
    await controller.pauseForLifecycle();
    await controller.resumeAfterLifecycle();
    await controller.release();
    await mixer.transitionTo(
      const RuntimeAudioMix(masterVolume: 0.5, musicVolume: 0.5),
    );

    expect(driver.events, [
      'prepare:opening.mp4:1.0',
      'play:video-1',
      'pause:video-1',
      'play:video-1',
      'dispose:video-1',
    ]);
    expect(
      controller.snapshot,
      RuntimePresentationMediaPlaybackSnapshot.idle,
    );
    expect(driver.active, isEmpty);
    expect(RuntimePresentationMediaPlaybackController.maximumActiveDecoderCount,
        1);
    expect(RuntimePresentationMediaPlaybackController.maximumCachedDecoderCount,
        0);
  });

  test('hold and lifecycle suspend the video for independent reasons',
      () async {
    final driver = _RecordingVideoDriver();
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
      audioMixer: RuntimeAudioMixer(),
    );

    await controller.playVideo(
      'opening-video',
      audioMode: RuntimePresentationVideoAudioMode.mixerManaged,
    );
    await controller.pauseForHold();
    await controller.pauseForLifecycle();
    await controller.resumeFromHold();
    expect(
      driver.events,
      [
        'prepare:opening.mp4:1.0',
        'play:video-1',
        'pause:video-1',
      ],
      reason: 'the app is still backgrounded: answering the interaction must '
          'NOT resume the video — hold and lifecycle are independent reasons '
          '(BETA-CIN-077)',
    );
    await controller.resumeAfterLifecycle();
    expect(driver.events.last, 'play:video-1');
    await controller.release();
    expect(driver.events.last, 'dispose:video-1');
  });

  test('dispose invalidates a decoder prepared by a late callback', () async {
    final driver = _DeferredVideoDriver();
    final controller = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (media) => Uri.parse('file:///${media.sourceAssetId}'),
      videoDriver: driver,
    );

    final playback = controller.playVideo('opening-video');
    await driver.prepareStarted.future;
    final disposal = controller.dispose();
    driver.completePreparation();
    await playback;
    await disposal;

    expect(driver.events, ['prepare:opening.mp4', 'dispose:video-late']);
    expect(driver.active, isEmpty);
    expect(
      controller.snapshot,
      RuntimePresentationMediaPlaybackSnapshot.idle,
    );

    final afterDispose = await controller.playVideo('chapter-video');
    expect(afterDispose.status, RuntimePresentationMediaPlaybackStatus.failed);
    expect(
      afterDispose.diagnosticCode,
      RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
    );
  });

  test('double skip and late completion publish one terminal result', () async {
    final driver = _RecordingVideoDriver();
    final media = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (asset) => Uri.parse('file:///${asset.sourceAssetId}'),
      videoDriver: driver,
    );
    await media.playVideo('opening-video');
    final terminals = <RuntimePresentationExecutionTerminal>[];
    final execution = RuntimePresentationExecutionController(
      mediaController: media,
      onTerminal: terminals.add,
    );
    final token = execution.start();

    final firstSkip = execution.skip(token);
    final secondSkip = execution.skip(token);
    await firstSkip;
    await secondSkip;
    await execution.complete(token);

    expect(terminals, hasLength(1));
    expect(terminals.single.result, RuntimePresentationExecutionResult.skipped);
    expect(execution.snapshot.terminal, same(terminals.single));
    expect(
      driver.events.where((event) => event.startsWith('dispose:')),
      ['dispose:video-1'],
    );
    expect(driver.active, isEmpty);
  });

  test('stale run callbacks cannot terminate a newer execution', () async {
    final media = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (asset) => Uri.parse('file:///${asset.sourceAssetId}'),
      videoDriver: _RecordingVideoDriver(),
    );
    final terminals = <RuntimePresentationExecutionTerminal>[];
    final execution = RuntimePresentationExecutionController(
      mediaController: media,
      onTerminal: terminals.add,
    );
    final first = execution.start();
    await execution.cancel(first);
    final second = execution.start();

    await execution.fail(first, diagnosticCode: 'late.decoder.callback');

    expect(execution.snapshot.phase, RuntimePresentationExecutionPhase.running);
    expect(execution.snapshot.runToken, second);
    expect(terminals, hasLength(1));

    await execution.complete(second);
    expect(terminals.map((terminal) => terminal.result), [
      RuntimePresentationExecutionResult.cancelled,
      RuntimePresentationExecutionResult.completed,
    ]);
  });

  test('execution lifecycle pauses and resumes before terminal cleanup',
      () async {
    final driver = _RecordingVideoDriver();
    final media = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (asset) => Uri.parse('file:///${asset.sourceAssetId}'),
      videoDriver: driver,
    );
    await media.playVideo('opening-video');
    final execution = RuntimePresentationExecutionController(
      mediaController: media,
    );
    final token = execution.start();

    await execution.pauseForLifecycle(token);
    expect(execution.snapshot.phase, RuntimePresentationExecutionPhase.paused);
    await execution.resumeAfterLifecycle(token);
    expect(execution.snapshot.phase, RuntimePresentationExecutionPhase.running);
    await execution.complete(token);

    expect(driver.events, [
      'prepare:opening.mp4:0.0',
      'play:video-1',
      'pause:video-1',
      'play:video-1',
      'dispose:video-1',
    ]);
  });

  test('dispose cancels an active execution once and forbids restart',
      () async {
    final media = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (asset) => Uri.parse('file:///${asset.sourceAssetId}'),
      videoDriver: _RecordingVideoDriver(),
    );
    final terminals = <RuntimePresentationExecutionTerminal>[];
    final execution = RuntimePresentationExecutionController(
      mediaController: media,
      onTerminal: terminals.add,
    );
    execution.start();

    await execution.dispose();
    await execution.dispose();

    expect(terminals, hasLength(1));
    expect(
      terminals.single.result,
      RuntimePresentationExecutionResult.cancelled,
    );
    expect(
      terminals.single.cancellationReason,
      RuntimePresentationCancellationReason.disposed,
    );
    expect(execution.start, throwsStateError);
  });

  test('lifecycle media failure terminates the run once', () async {
    final driver = _RecordingVideoDriver()..failPauses = true;
    final media = RuntimePresentationMediaPlaybackController(
      catalog: _catalog(),
      targetPlatform: PresentationMediaTargetPlatform.android,
      resolveUri: (asset) => Uri.parse('file:///${asset.sourceAssetId}'),
      videoDriver: driver,
    );
    await media.playVideo('opening-video');
    final terminals = <RuntimePresentationExecutionTerminal>[];
    final execution = RuntimePresentationExecutionController(
      mediaController: media,
      onTerminal: terminals.add,
    );
    final token = execution.start();

    await execution.pauseForLifecycle(token);
    await execution.skip(token);

    expect(terminals, hasLength(1));
    expect(terminals.single.result, RuntimePresentationExecutionResult.failed);
    expect(
      terminals.single.diagnosticCode,
      RuntimePresentationMediaPlaybackDiagnosticCodes.playbackFailed,
    );
    expect(driver.active, isEmpty);
  });
}

ProjectMediaCatalog _catalog() => ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        _video(
          id: 'opening-video',
          sourceAssetId: 'opening.mp4',
          fallbackMediaId: 'opening-poster',
        ),
        _poster(id: 'opening-poster', sourceAssetId: 'opening.png'),
        _video(id: 'chapter-video', sourceAssetId: 'chapter.mp4'),
      ],
    );

ProjectMediaAsset _video({
  required String id,
  required String sourceAssetId,
  String? fallbackMediaId,
}) =>
    ProjectMediaAsset(
      id: id,
      label: id,
      kind: ProjectMediaKind.video,
      sourceAssetId: sourceAssetId,
      fallbackMediaId: fallbackMediaId,
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'video/mp4',
        container: 'mp4',
        codec: 'h264',
        audioCodec: 'aac',
        sizeBytes: 1024,
        width: 1920,
        height: 1080,
        durationMilliseconds: 1000,
      ),
    );

ProjectMediaAsset _poster({
  required String id,
  required String sourceAssetId,
}) =>
    ProjectMediaAsset(
      id: id,
      label: id,
      kind: ProjectMediaKind.poster,
      sourceAssetId: sourceAssetId,
      technicalMetadata: ProjectMediaTechnicalMetadata(
        mediaType: 'image/png',
        container: 'png',
        codec: 'png',
        sizeBytes: 512,
        width: 1920,
        height: 1080,
      ),
    );

final class _RecordingVideoDriver
    implements RuntimePresentationVideoPlaybackDriver {
  final events = <String>[];
  final failingSources = <String>{};
  final active = <Object>{};
  var maximumActiveDecoders = 0;
  var failDisposals = false;
  var failPauses = false;
  var _nextHandle = 1;

  @override
  Future<Object> prepare(
    Uri source, {
    required double initialVolume,
  }) async {
    events.add('prepare:${source.pathSegments.last}:$initialVolume');
    if (failingSources.contains(source.pathSegments.last)) {
      throw StateError('decoder failed for ${source.toFilePath()}');
    }
    final handle = 'video-${_nextHandle++}';
    active.add(handle);
    if (active.length > maximumActiveDecoders) {
      maximumActiveDecoders = active.length;
    }
    return handle;
  }

  @override
  Future<void> play(Object handle) async => events.add('play:$handle');

  @override
  Future<void> pause(Object handle) async {
    events.add('pause:$handle');
    if (failPauses) throw StateError('pause failed');
  }

  @override
  Future<void> setVolume(Object handle, double volume) async =>
      events.add('volume:$handle:$volume');

  @override
  Future<void> dispose(Object handle) async {
    events.add('dispose:$handle');
    if (failDisposals) throw StateError('decoder disposal failed');
    active.remove(handle);
  }
}

final class _DeferredVideoDriver
    implements RuntimePresentationVideoPlaybackDriver {
  final prepareStarted = Completer<void>();
  final _preparation = Completer<Object>();
  final events = <String>[];
  final active = <Object>{};

  void completePreparation() {
    active.add('video-late');
    _preparation.complete('video-late');
  }

  @override
  Future<Object> prepare(
    Uri source, {
    required double initialVolume,
  }) {
    events.add('prepare:${source.pathSegments.last}');
    prepareStarted.complete();
    return _preparation.future;
  }

  @override
  Future<void> play(Object handle) async => events.add('play:$handle');

  @override
  Future<void> pause(Object handle) async => events.add('pause:$handle');

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> dispose(Object handle) async {
    events.add('dispose:$handle');
    active.remove(handle);
  }
}
