import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  group('presentation studio media sink', () {
    test('a running clock starts the frame audio at its evaluated position',
        () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);

      sink.synchronize(
        asset: _asset(),
        frame: _frameAt(1200000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;

      expect(driver.log, ['play:opening-music@1200000:loop=true:type=audio/ogg']);
      expect(sink.diagnostic, isNull);
    });

    test('a stopped clock never reaches the audio device', () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);

      sink.synchronize(
        asset: _asset(),
        frame: _frameAt(1200000),
        orientation: PresentationFrameOrientation.landscape,
        running: false,
      );
      await sink.settled;

      expect(driver.log, isEmpty);
    });

    test('pausing suspends the channel instead of stopping it', () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);
      final asset = _asset();

      sink.synchronize(
        asset: asset,
        frame: _frameAt(1000000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      driver.log.clear();

      sink.synchronize(
        asset: asset,
        frame: _frameAt(1016666),
        orientation: PresentationFrameOrientation.landscape,
        running: false,
      );
      await sink.settled;
      expect(driver.log, ['pause']);

      sink.synchronize(
        asset: asset,
        frame: _frameAt(1016666),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      // Resumed, never restarted: an author toggling playback must not hear
      // the music jump back to its first note.
      expect(driver.log, ['pause', 'resume']);
    });

    test('advancing frame by frame keeps the same channel', () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);
      final asset = _asset();

      for (var frame = 0; frame < 20; frame += 1) {
        sink.synchronize(
          asset: asset,
          frame: _frameAt(frame * 16666),
          orientation: PresentationFrameOrientation.landscape,
          running: true,
        );
        await sink.settled;
      }

      expect(driver.log, ['play:opening-music@0:loop=true:type=audio/ogg']);
    });

    test('scrubbing restarts the channel at the new instant', () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);
      final asset = _asset();

      sink.synchronize(
        asset: asset,
        frame: _frameAt(200000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      driver.log.clear();

      // A jump no tick could produce: the author dragged the playhead.
      sink.synchronize(
        asset: asset,
        frame: _frameAt(3500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;

      expect(driver.log, ['stop', 'play:opening-music@3500000:loop=true:type=audio/ogg']);
    });

    test('scrubbing while paused releases, so the next play starts there',
        () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);
      final asset = _asset();

      sink.synchronize(
        asset: asset,
        frame: _frameAt(200000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      sink.synchronize(
        asset: asset,
        frame: _frameAt(200000),
        orientation: PresentationFrameOrientation.landscape,
        running: false,
      );
      await sink.settled;
      driver.log.clear();

      sink.synchronize(
        asset: asset,
        frame: _frameAt(5000000),
        orientation: PresentationFrameOrientation.landscape,
        running: false,
      );
      await sink.settled;
      expect(driver.log, ['stop']);

      sink.synchronize(
        asset: asset,
        frame: _frameAt(5000000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      expect(driver.log, ['stop', 'play:opening-music@5000000:loop=true:type=audio/ogg']);
    });

    test('releasing stops every channel', () async {
      final driver = _RecordingAudioDriver();
      final sink = _sink(driver);
      addTearDown(sink.dispose);

      sink.synchronize(
        asset: _asset(),
        frame: _frameAt(500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      driver.log.clear();

      await sink.release();

      expect(driver.log, ['stop']);
    });

    test('a video clip entering the frame prepares and seeks its decoder',
        () async {
      final video = _RecordingVideoPlayback();
      final sink = _videoSink(video);
      addTearDown(sink.dispose);
      final asset = _videoAsset();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      expect(video.log, isEmpty, reason: 'the clip has not started yet');
      expect(sink.videoFor('intro-video'), isNull);

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(1500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;

      expect(video.log, ['prepare:intro.mp4', 'seek:500000', 'play']);
      expect(sink.videoFor('intro-video'), isNotNull);
    });

    test('leaving the clip disposes the decoder and takes back the picture',
        () async {
      final video = _RecordingVideoPlayback();
      final sink = _videoSink(video);
      addTearDown(sink.dispose);
      final asset = _videoAsset();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(1500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      video.log.clear();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(6000000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;

      expect(video.log, ['dispose']);
      expect(sink.videoFor('intro-video'), isNull);
    });

    test('pausing pauses the picture, resuming resyncs it', () async {
      final video = _RecordingVideoPlayback();
      final sink = _videoSink(video);
      addTearDown(sink.dispose);
      final asset = _videoAsset();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(1500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      video.log.clear();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(1516666),
        orientation: PresentationFrameOrientation.landscape,
        running: false,
      );
      await sink.settled;
      expect(video.log, ['pause']);

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(1516666),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      expect(video.log, ['pause', 'seek:516666', 'play']);
    });

    test('scrubbing inside the clip seeks the picture', () async {
      final video = _RecordingVideoPlayback();
      final sink = _videoSink(video);
      addTearDown(sink.dispose);
      final asset = _videoAsset();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(1500000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;
      video.log.clear();

      sink.synchronize(
        asset: asset,
        frame: _videoFrameAt(4000000),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;

      expect(video.log, ['seek:3000000']);
    });

    test('a source that will not open is not retried on every frame',
        () async {
      final driver = _RecordingAudioDriver()
        ..failWith = StateError('AVPlayerItem.Status.failed');
      final sink = _sink(driver);
      addTearDown(sink.dispose);
      final asset = _asset();

      for (var frame = 0; frame < 30; frame += 1) {
        sink.synchronize(
          asset: asset,
          frame: _frameAt(frame * 16666),
          orientation: PresentationFrameOrientation.landscape,
          running: true,
        );
        await sink.settled;
      }

      // One attempt, one diagnostic. Re-planning the same start sixty times a
      // second hammers the audio device for a file it has already refused.
      expect(driver.log, isEmpty);
      expect(sink.diagnostic, isNotNull);
      expect(sink.unplayableResourceIds, contains('opening-music'));
    });

    test('a media missing from the catalog reports instead of throwing',
        () async {
      final driver = _RecordingAudioDriver();
      final sink = PresentationStudioMediaSink(
        catalog: ProjectMediaCatalog(entries: const <ProjectMediaAsset>[]),
        mediaUris: const <String, Uri>{},
        targetPlatform: PresentationMediaTargetPlatform.macos,
        audioDriver: driver,
      );
      addTearDown(sink.dispose);

      sink.synchronize(
        asset: _asset(),
        frame: _frameAt(0),
        orientation: PresentationFrameOrientation.landscape,
        running: true,
      );
      await sink.settled;

      expect(driver.log, isEmpty);
      expect(sink.diagnostic, isNotNull);
    });
  });
}

final class _RecordingVideoPlayback
    implements PresentationStudioVideoPlayback {
  final List<String> log = <String>[];
  var _handles = 0;

  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) async {
    log.add('prepare:${source.pathSegments.last}');
    return 'video-${_handles++}';
  }

  @override
  Future<void> play(Object handle) async => log.add('play');

  @override
  Future<void> pause(Object handle) async => log.add('pause');

  @override
  Future<void> seek(Object handle, Duration position) async =>
      log.add('seek:${position.inMicroseconds}');

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Widget buildVideo(Object handle) => const SizedBox.shrink(key: _videoKey);

  @override
  Future<void> dispose(Object handle) async => log.add('dispose');
}

const _videoKey = ValueKey<String>('video-surface');

ProjectMediaCatalog _videoCatalog() => ProjectMediaCatalog(
      entries: <ProjectMediaAsset>[
        ProjectMediaAsset(
          id: 'intro-video',
          label: 'Vidéo d’intro',
          kind: ProjectMediaKind.video,
          sourceAssetId: 'asset-intro-video',
        ),
      ],
    );

PresentationCinematicAsset _videoAsset() => PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 8000000,
      layers: <PresentationLayer>[
        PresentationLayer(id: 'picture', label: 'Image', zIndex: 0),
      ],
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'visuals',
          label: 'Visuels',
          kind: PresentationTrackKind.visual,
          clips: <PresentationClip>[
            PresentationVisualClip(
              id: 'video-clip',
              startUs: 1000000,
              durationUs: 4000000,
              layerId: 'picture',
              resourceId: 'intro-video',
              mediaKind: PresentationVisualMediaKind.video,
            ),
          ],
        ),
      ],
    );

PresentationStudioMediaSink _videoSink(_RecordingVideoPlayback video) =>
    PresentationStudioMediaSink(
      catalog: _videoCatalog(),
      mediaUris: <String, Uri>{
        'intro-video': Uri.file('/project/intro.mp4'),
      },
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioDriver: _RecordingAudioDriver(),
      videoPlayback: video,
    );

PresentationFrame _videoFrameAt(int timeUs) =>
    const PresentationCinematicEvaluator()
        .evaluate(_videoAsset(), timeUs: timeUs);

PresentationStudioMediaSink _sink(_RecordingAudioDriver driver) =>
    PresentationStudioMediaSink(
      catalog: ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'opening-music',
            label: 'Musique d’ouverture',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset-opening-music',
            technicalMetadata: ProjectMediaTechnicalMetadata(
              mediaType: 'audio/ogg',
              container: 'ogg',
              codec: 'vorbis',
              sizeBytes: 2048,
              durationMilliseconds: 8000,
            ),
          ),
        ],
      ),
      mediaUris: <String, Uri>{
        'opening-music': Uri.file('/project/opening-music.ogg'),
      },
      targetPlatform: PresentationMediaTargetPlatform.macos,
      audioDriver: driver,
    );

PresentationCinematicAsset _asset() => PresentationCinematicAsset(
      id: 'opening',
      title: 'Opening',
      durationUs: 8000000,
      tracks: <PresentationTrack>[
        PresentationTrack(
          id: 'music',
          label: 'Musique',
          kind: PresentationTrackKind.audio,
          clips: <PresentationClip>[
            PresentationAudioClip(
              id: 'music-clip',
              startUs: 0,
              durationUs: 8000000,
              resourceId: 'opening-music',
              audioKind: PresentationAudioKind.music,
              bus: PresentationAudioBus.music,
              loop: true,
            ),
          ],
        ),
      ],
    );

PresentationFrame _frameAt(int timeUs) =>
    const PresentationCinematicEvaluator().evaluate(_asset(), timeUs: timeUs);

final class _RecordingAudioDriver implements RuntimePresentationAudioDriver {
  final List<String> log = <String>[];
  Object? failWith;
  var _handles = 0;

  @override
  Future<Object> play(
    Uri source, {
    required double volume,
    required bool loop,
    required Duration position,
    String? mimeType,
  }) async {
    if (failWith != null) throw failWith!;
    log.add(
      'play:${source.pathSegments.last.split('.').first}'
      '@${position.inMicroseconds}:loop=$loop'
      '${mimeType == null ? '' : ':type=$mimeType'}',
    );
    return 'handle-${_handles++}';
  }

  @override
  Future<void> pause(Object handle) async => log.add('pause');

  @override
  Future<void> resume(Object handle) async => log.add('resume');

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Future<void> stop(Object handle) async => log.add('stop');
}
