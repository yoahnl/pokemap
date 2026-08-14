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
      RuntimePresentationMediaPlaybackDiagnosticCodes.mediaMissing,
    );
    expect(snapshot.diagnosticMessage, 'Presentation media is unavailable.');
    expect(snapshot.diagnosticMessage, isNot(contains('/')));
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
  Future<void> setVolume(Object handle, double volume) async =>
      events.add('volume:$handle:$volume');

  @override
  Future<void> dispose(Object handle) async {
    events.add('dispose:$handle');
    if (failDisposals) throw StateError('decoder disposal failed');
    active.remove(handle);
  }
}
