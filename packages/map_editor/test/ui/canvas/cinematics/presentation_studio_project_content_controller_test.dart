import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/authoring_api/presentation_timeline_projection_gateway.dart';
import 'package:map_editor/src/ui/canvas/cinematics/presentation/presentation_studio_project_content_controller.dart';
import 'package:map_player_ui/presentation_renderer.dart';

void main() {
  test('the live video replaces the poster of its clip', () async {
    final playback = _StubVideoPlayback();
    final sink = PresentationStudioMediaSink(
      catalog: ProjectMediaCatalog(
        entries: <ProjectMediaAsset>[
          ProjectMediaAsset(
            id: 'intro-video',
            label: 'Vidéo d’intro',
            kind: ProjectMediaKind.video,
            sourceAssetId: 'asset-intro-video',
          ),
        ],
      ),
      mediaUris: <String, Uri>{'intro-video': Uri.file('/project/intro.mp4')},
      targetPlatform: PresentationMediaTargetPlatform.macos,
      videoPlayback: playback,
    );
    addTearDown(sink.dispose);
    final controller = PresentationStudioProjectContentController(
      projectRootPath: '/project',
      mediaReader: _MediaReader(
        <String, PresentationTimelineProjectionMedia>{},
      ),
      projectionGateway: _ProjectionGateway(
        <String, PresentationTimelineMediaProjection>{},
      ),
      mediaSink: sink,
    );
    addTearDown(controller.dispose);

    final videoAsset = _videoAsset();
    final clip = const PresentationCinematicEvaluator()
        .evaluate(videoAsset, timeUs: 1500000)
        .visuals
        .single;

    // Nothing decoded yet: the clip falls back to what the reader has, which
    // here is nothing at all.
    expect(
      controller.resolveVisual(
        clip: clip,
        orientation: PresentationFrameOrientation.landscape,
      ),
      isA<PresentationVisualUnavailable>(),
    );

    sink.synchronize(
      asset: videoAsset,
      frame: const PresentationCinematicEvaluator()
          .evaluate(videoAsset, timeUs: 1500000),
      orientation: PresentationFrameOrientation.landscape,
      running: true,
    );
    await sink.settled;

    final resolved = controller.resolveVisual(
      clip: clip,
      orientation: PresentationFrameOrientation.landscape,
    );
    expect(resolved, isA<PresentationVisualReady>());
    expect((resolved as PresentationVisualReady).child.key, _videoSurfaceKey);
  });

  testWidgets(
    'loads responsive project media and caption segments before rendering',
    (tester) async {
      final reader = _MediaReader(<String, PresentationTimelineProjectionMedia>{
        'image.shared': _image('image.shared', <int>[1, 2, 3]),
        'image.portrait': _image('image.portrait', <int>[4, 5, 6]),
      });
      final gateway = _ProjectionGateway(
        <String, PresentationTimelineMediaProjection>{
          'captions.fr': const PresentationTimelineMediaProjection.ready(
            mediaId: 'captions.fr',
            captions: <PresentationTimelineCaptionSegment>[
              PresentationTimelineCaptionSegment(
                startUs: 0,
                endUs: 900000,
                text: 'Bienvenue à Avelune',
              ),
            ],
          ),
        },
      );
      final controller = PresentationStudioProjectContentController(
        projectRootPath: '/project',
        mediaReader: reader,
        projectionGateway: gateway,
      );
      addTearDown(controller.dispose);
      final asset = _asset();

      await controller.prepare(asset);

      expect(
        reader.readMediaIds,
        containsAll(<String>{'image.shared', 'image.portrait'}),
      );
      final frame = const PresentationCinematicEvaluator().evaluate(
        asset,
        timeUs: 1500000,
      );
      final responsivePort = PresentationResponsiveFrameContentPort(
        delegate: controller,
        bindings: const <PresentationFrameMediaBinding>[
          PresentationFrameMediaBinding(
            clipId: 'visual',
            kind: PresentationFrameMediaKind.image,
            sharedResourceId: 'image.shared',
            portraitResourceId: 'image.portrait',
          ),
        ],
      );
      final visual = responsivePort.resolveVisual(
        clip: frame.visuals.single,
        orientation: PresentationFrameOrientation.portrait,
      );
      final caption = controller.resolveCaption(
        clip: frame.captions.single,
        locale: const Locale('fr'),
      );

      expect(visual, isA<PresentationVisualReady>());
      expect(
        (visual as PresentationVisualReady).child.key,
        const ValueKey<String>('presentation-studio-media-image.portrait'),
      );
      expect(caption, isA<PresentationCaptionReady>());
      expect((caption as PresentationCaptionReady).text, 'Bienvenue à Avelune');
    },
  );

  testWidgets('keeps missing and unsupported media explicit', (tester) async {
    final controller = PresentationStudioProjectContentController(
      projectRootPath: '/project',
      mediaReader: _MediaReader(<String, PresentationTimelineProjectionMedia>{
        'audio.wrong': PresentationTimelineProjectionMedia(
          mediaId: 'audio.wrong',
          kind: ProjectMediaKind.audio,
          sourceAvailable: true,
          sourceBytes: Uint8List.fromList(<int>[1]),
        ),
      }),
      projectionGateway: _ProjectionGateway(
        const <String, PresentationTimelineMediaProjection>{},
      ),
    );
    addTearDown(controller.dispose);
    final asset = _asset(
      resourceId: 'audio.wrong',
      captionId: 'captions.missing',
    );

    await controller.prepare(asset);
    final frame = const PresentationCinematicEvaluator().evaluate(
      asset,
      timeUs: 1500000,
    );

    final visual = controller.resolveVisual(
      clip: frame.visuals.single,
      orientation: PresentationFrameOrientation.landscape,
    );
    final caption = controller.resolveCaption(
      clip: frame.captions.single,
      locale: const Locale('fr'),
    );
    expect(visual, isA<PresentationVisualUnavailable>());
    expect(
      (visual as PresentationVisualUnavailable).reason,
      PresentationContentUnavailableReason.unsupported,
    );
    expect(caption, isA<PresentationCaptionUnavailable>());
    expect(
      (caption as PresentationCaptionUnavailable).reason,
      PresentationContentUnavailableReason.missing,
    );
  });

  testWidgets('ignores a stale project-media preparation', (tester) async {
    final delayed = Completer<PresentationTimelineProjectionMedia?>();
    final controller = PresentationStudioProjectContentController(
      projectRootPath: '/project',
      mediaReader: _SequencedMediaReader(delayed),
      projectionGateway: _ProjectionGateway(
        const <String, PresentationTimelineMediaProjection>{},
      ),
    );
    addTearDown(controller.dispose);

    final stalePreparation = controller.prepare(
      _asset(resourceId: 'image.old'),
    );
    await controller.prepare(_asset(resourceId: 'image.new'));
    delayed.complete(_image('image.old', <int>[1]));
    await stalePreparation;

    final frame = const PresentationCinematicEvaluator().evaluate(
      _asset(resourceId: 'image.new'),
      timeUs: 1500000,
    );
    final visual = controller.resolveVisual(
      clip: frame.visuals.single,
      orientation: PresentationFrameOrientation.landscape,
    );
    expect(visual, isA<PresentationVisualReady>());
    expect(
      (visual as PresentationVisualReady).child.key,
      const ValueKey<String>('presentation-studio-media-image.new'),
    );
  });
}

PresentationTimelineProjectionMedia _image(String mediaId, List<int> bytes) =>
    PresentationTimelineProjectionMedia(
      mediaId: mediaId,
      kind: ProjectMediaKind.image,
      sourceAvailable: true,
      sourceBytes: Uint8List.fromList(bytes),
    );

PresentationCinematicAsset _asset({
  String resourceId = 'image.shared',
  String captionId = 'captions.fr',
}) => PresentationCinematicAsset(
  id: 'opening',
  title: 'Ouverture',
  durationUs: 4000000,
  layers: <PresentationLayer>[
    PresentationLayer(id: 'background', label: 'Fond', zIndex: 0),
  ],
  tracks: <PresentationTrack>[
    PresentationTrack(
      id: 'visuals',
      label: 'Visuels',
      kind: PresentationTrackKind.visual,
      clips: <PresentationClip>[
        PresentationVisualClip(
          id: 'visual',
          startUs: 0,
          durationUs: 4000000,
          layerId: 'background',
          resourceId: resourceId,
          portraitResourceId: resourceId == 'image.shared'
              ? 'image.portrait'
              : null,
        ),
      ],
    ),
    PresentationTrack(
      id: 'captions',
      label: 'Sous-titres',
      kind: PresentationTrackKind.caption,
      clips: <PresentationClip>[
        PresentationCaptionClip(
          id: 'caption',
          startUs: 1000000,
          durationUs: 2000000,
          captionId: captionId,
          locale: 'fr',
        ),
      ],
    ),
  ],
);

final class _MediaReader implements PresentationTimelineProjectionMediaReader {
  _MediaReader(this.media);

  final Map<String, PresentationTimelineProjectionMedia> media;
  final List<String> readMediaIds = <String>[];

  @override
  Future<PresentationTimelineProjectionMedia?> read(
    String projectRootPath,
    String mediaId,
  ) async {
    readMediaIds.add(mediaId);
    return media[mediaId];
  }
}

final class _ProjectionGateway
    implements PresentationTimelineProjectionGateway {
  _ProjectionGateway(this.projections);

  final Map<String, PresentationTimelineMediaProjection> projections;

  @override
  Future<PresentationTimelineMediaProjection> load(
    String projectRootPath,
    PresentationTimelineProjectionRequest request,
  ) async =>
      projections[request.mediaId] ??
      PresentationTimelineMediaProjection.unavailable(
        mediaId: request.mediaId,
        status: PresentationTimelineProjectionStatus.missing,
        diagnostic: 'Média introuvable',
      );
}

final class _SequencedMediaReader
    implements PresentationTimelineProjectionMediaReader {
  _SequencedMediaReader(this.delayed);

  final Completer<PresentationTimelineProjectionMedia?> delayed;

  @override
  Future<PresentationTimelineProjectionMedia?> read(
    String projectRootPath,
    String mediaId,
  ) {
    if (mediaId == 'image.old') return delayed.future;
    return Future<PresentationTimelineProjectionMedia?>.value(
      _image(mediaId, <int>[2]),
    );
  }
}

const _videoSurfaceKey = ValueKey<String>('montage-video-surface');

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

final class _StubVideoPlayback implements PresentationStudioVideoPlayback {
  @override
  Future<Object> prepare(Uri source, {required double initialVolume}) async =>
      Object();

  @override
  Future<void> play(Object handle) async {}

  @override
  Future<void> pause(Object handle) async {}

  @override
  Future<void> seek(Object handle, Duration position) async {}

  @override
  Future<void> setVolume(Object handle, double volume) async {}

  @override
  Widget buildVideo(Object handle) =>
      const SizedBox.shrink(key: _videoSurfaceKey);

  @override
  Future<void> dispose(Object handle) async {}
}
