import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/presentation_timeline_projection_gateway.dart';

void main() {
  test(
    'deduplicates shared media and ignores a cancelled late projection',
    () async {
      final gateway = _ControlledProjectionGateway();
      final controller = PresentationTimelineProjectionController(
        projectRootPath: '/project',
        gateway: gateway,
      );
      addTearDown(controller.dispose);
      final first = PresentationAudioClip(
        id: 'music-a',
        startUs: 0,
        durationUs: 1000000,
        resourceId: 'opening-music',
      );
      final second = PresentationAudioClip(
        id: 'music-b',
        startUs: 1000000,
        durationUs: 1000000,
        resourceId: 'opening-music',
      );

      controller.sync(clips: [first, second], pixelsPerSecond: 80);

      expect(gateway.requests, hasLength(1));
      expect(
        controller.projectionFor(first, pixelsPerSecond: 80)?.loading,
        isTrue,
      );

      controller.sync(clips: const [], pixelsPerSecond: 80);
      gateway.completeNext(
        const PresentationTimelineMediaProjection.ready(
          mediaId: 'opening-music',
          waveform: <double>[0.2, 0.8],
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.projectionFor(first, pixelsPerSecond: 80), isNull);
    },
  );

  test(
    'zoom bucket regenerates a waveform once and shares the result',
    () async {
      final gateway = _ImmediateProjectionGateway();
      final controller = PresentationTimelineProjectionController(
        projectRootPath: '/project',
        gateway: gateway,
      );
      addTearDown(controller.dispose);
      final clip = PresentationAudioClip(
        id: 'music',
        startUs: 0,
        durationUs: 1000000,
        resourceId: 'opening-music',
      );

      controller.sync(clips: [clip], pixelsPerSecond: 80);
      await Future<void>.delayed(Duration.zero);
      controller.sync(clips: [clip], pixelsPerSecond: 90);
      await Future<void>.delayed(Duration.zero);
      controller.sync(clips: [clip], pixelsPerSecond: 220);
      await Future<void>.delayed(Duration.zero);

      expect(gateway.requests.map((request) => request.sampleCount), [64, 128]);
      expect(
        controller.projectionFor(clip, pixelsPerSecond: 220)?.waveform,
        <double>[0.25, 0.75],
      );
    },
  );

  test('invalidate regenerates only the targeted media projection', () async {
    final gateway = _ImmediateProjectionGateway();
    final controller = PresentationTimelineProjectionController(
      projectRootPath: '/project',
      gateway: gateway,
    );
    addTearDown(controller.dispose);
    final audio = PresentationAudioClip(
      id: 'audio',
      startUs: 0,
      durationUs: 1000000,
      resourceId: 'audio-media',
    );
    final captions = PresentationCaptionClip(
      id: 'captions',
      startUs: 0,
      durationUs: 1000000,
      captionId: 'caption-media',
    );

    controller.sync(clips: [audio, captions], pixelsPerSecond: 80);
    await Future<void>.delayed(Duration.zero);
    controller.invalidateMedia('audio-media');
    controller.sync(clips: [audio, captions], pixelsPerSecond: 80);
    await Future<void>.delayed(Duration.zero);

    expect(gateway.requests.map((request) => request.mediaId), [
      'audio-media',
      'caption-media',
      'audio-media',
    ]);
  });

  test(
    'canonical gateway prepares WAV waveforms outside the timeline',
    () async {
      final gateway = CanonicalPresentationTimelineProjectionGateway(
        reader: _MemoryProjectionReader(
          PresentationTimelineProjectionMedia(
            mediaId: 'voice',
            kind: ProjectMediaKind.audio,
            sourceAvailable: true,
            sourceBytes: _pcmWav(<int>[-32768, 0, 32767, 0]),
          ),
        ),
      );

      final projection = await gateway.load(
        '/project',
        const PresentationTimelineProjectionRequest(
          mediaId: 'voice',
          kind: PresentationTimelineProjectionKind.audio,
          sampleCount: 4,
        ),
      );

      expect(projection.status, PresentationTimelineProjectionStatus.ready);
      expect(projection.waveform[0], 1);
      expect(projection.waveform[1], 0);
      expect(projection.waveform[2], closeTo(1, 0.001));
      expect(projection.waveform[3], 0);
    },
  );

  test(
    'canonical gateway normalizes a video poster and records fallback',
    () async {
      final poster = image.Image(width: 4, height: 2)
        ..setPixelRgb(0, 0, 30, 80, 160);
      final gateway = CanonicalPresentationTimelineProjectionGateway(
        reader: _MemoryProjectionReader(
          PresentationTimelineProjectionMedia(
            mediaId: 'intro-video',
            kind: ProjectMediaKind.video,
            sourceAvailable: true,
            posterBytes: Uint8List.fromList(image.encodePng(poster)),
            fallbackUsed: true,
          ),
        ),
      );

      final projection = await gateway.load(
        '/project',
        const PresentationTimelineProjectionRequest(
          mediaId: 'intro-video',
          kind: PresentationTimelineProjectionKind.video,
          sampleCount: 64,
        ),
      );

      expect(projection.status, PresentationTimelineProjectionStatus.ready);
      expect(image.decodePng(projection.thumbnailBytes!), isNotNull);
      expect(projection.fallbackUsed, isTrue);
    },
  );

  test('canonical gateway parses WEBVTT segments before rendering', () async {
    final gateway = CanonicalPresentationTimelineProjectionGateway(
      reader: _MemoryProjectionReader(
        PresentationTimelineProjectionMedia(
          mediaId: 'captions-fr',
          kind: ProjectMediaKind.captions,
          sourceAvailable: true,
          sourceBytes: Uint8List.fromList(
            utf8.encode('WEBVTT\n\n00:00:01.000 --> 00:00:02.500\nBonjour !\n'),
          ),
        ),
      ),
    );

    final projection = await gateway.load(
      '/project',
      const PresentationTimelineProjectionRequest(
        mediaId: 'captions-fr',
        kind: PresentationTimelineProjectionKind.captions,
        sampleCount: 64,
      ),
    );

    expect(projection.status, PresentationTimelineProjectionStatus.ready);
    expect(projection.captions.single.startUs, 1000000);
    expect(projection.captions.single.endUs, 2500000);
    expect(projection.captions.single.text, 'Bonjour !');
  });

  test('canonical gateway reports missing media without throwing', () async {
    final gateway = CanonicalPresentationTimelineProjectionGateway(
      reader: _MemoryProjectionReader(null),
    );

    final projection = await gateway.load(
      '/project',
      const PresentationTimelineProjectionRequest(
        mediaId: 'missing',
        kind: PresentationTimelineProjectionKind.audio,
        sampleCount: 64,
      ),
    );

    expect(projection.status, PresentationTimelineProjectionStatus.missing);
    expect(projection.diagnostic, 'Média introuvable');
  });
}

final class _ControlledProjectionGateway
    implements PresentationTimelineProjectionGateway {
  final List<PresentationTimelineProjectionRequest> requests = [];
  final List<Completer<PresentationTimelineMediaProjection>> _completers = [];

  @override
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  ) {
    requests.add(request);
    final completer = Completer<PresentationTimelineMediaProjection>();
    _completers.add(completer);
    return completer.future;
  }

  void completeNext(PresentationTimelineMediaProjection projection) {
    _completers.removeAt(0).complete(projection);
  }
}

final class _ImmediateProjectionGateway
    implements PresentationTimelineProjectionGateway {
  final List<PresentationTimelineProjectionRequest> requests = [];

  @override
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  ) async {
    requests.add(request);
    return PresentationTimelineMediaProjection.ready(
      mediaId: request.mediaId,
      waveform: request.kind == PresentationTimelineProjectionKind.audio
          ? const <double>[0.25, 0.75]
          : const <double>[],
    );
  }
}

final class _MemoryProjectionReader
    implements PresentationTimelineProjectionMediaReader {
  const _MemoryProjectionReader(this.media);

  final PresentationTimelineProjectionMedia? media;

  @override
  Future<PresentationTimelineProjectionMedia?> read(
    String projectRootPath,
    String mediaId,
  ) async => media;
}

Uint8List _pcmWav(List<int> samples) {
  final dataLength = samples.length * 2;
  final bytes = Uint8List(44 + dataLength);
  final data = ByteData.sublistView(bytes);
  bytes.setRange(0, 4, ascii.encode('RIFF'));
  data.setUint32(4, 36 + dataLength, Endian.little);
  bytes.setRange(8, 12, ascii.encode('WAVE'));
  bytes.setRange(12, 16, ascii.encode('fmt '));
  data.setUint32(16, 16, Endian.little);
  data.setUint16(20, 1, Endian.little);
  data.setUint16(22, 1, Endian.little);
  data.setUint32(24, 44100, Endian.little);
  data.setUint32(28, 88200, Endian.little);
  data.setUint16(32, 2, Endian.little);
  data.setUint16(34, 16, Endian.little);
  bytes.setRange(36, 40, ascii.encode('data'));
  data.setUint32(40, dataLength, Endian.little);
  for (var index = 0; index < samples.length; index += 1) {
    data.setInt16(44 + index * 2, samples[index], Endian.little);
  }
  return bytes;
}
