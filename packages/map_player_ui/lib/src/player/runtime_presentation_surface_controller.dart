import 'dart:async';
import 'dart:io';

import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'presentation_frame_renderer.dart';
import 'presentation_video_playback_driver.dart';
import 'runtime_presentation_frame_surface.dart';

final class RuntimePresentationSurfaceController
    extends ValueNotifier<RuntimePresentationFrameSnapshot?>
    implements
        ScenePresentationCinematicRuntimePlayer,
        PresentationFrameContentPort {
  RuntimePresentationSurfaceController({
    required this.catalog,
    required Map<String, Uri> mediaUris,
    required PresentationMediaTargetPlatform targetPlatform,
    required RuntimePresentationVideoPlaybackDriver videoDriver,
    RuntimeAudioMixer? audioMixer,
    RuntimePresentationFrameDeltas? frameDeltas,
    RuntimePresentationBeforeTerminal? beforeTerminal,
    this.reduceMotion = false,
    this.reduceFlashes = false,
    this.showCaptions = true,
    PresentationFrameOrientation orientation =
        PresentationFrameOrientation.landscape,
  })  : mediaUris = Map<String, Uri>.unmodifiable(mediaUris),
        _orientation = orientation,
        _videoDriver = videoDriver,
        super(null) {
    final mixer = audioMixer ?? RuntimeAudioMixer();
    _mediaController = RuntimePresentationMediaPlaybackController(
      catalog: catalog,
      targetPlatform: targetPlatform,
      resolveUri: _resolveMediaUri,
      videoDriver: videoDriver,
      audioMixer: mixer,
    );
    _audioController = RuntimePresentationAudioController(
      catalog: catalog,
      resolveUri: _resolveMediaUri,
      driver: FlameRuntimePresentationAudioDriver(),
      mixer: mixer,
    );
    _executionController = RuntimePresentationExecutionController(
      mediaController: _mediaController,
    );
    _playbackController = RuntimePresentationScenePlaybackController(
      executionController: _executionController,
      audioController: _audioController,
      onFrame: _publishFrame,
      frameDeltas: frameDeltas,
      resolveVisualMediaId: _resolveVisualMediaId,
      beforeTerminal: beforeTerminal ?? _detachBeforeTerminal,
    );
  }

  final ProjectMediaCatalog catalog;
  final Map<String, Uri> mediaUris;
  final RuntimePresentationVideoPlaybackDriver _videoDriver;
  final bool reduceMotion;
  final bool reduceFlashes;
  final bool showCaptions;

  late final RuntimePresentationMediaPlaybackController _mediaController;
  late final RuntimePresentationExecutionController _executionController;
  late final RuntimePresentationAudioController _audioController;
  late final RuntimePresentationScenePlaybackController _playbackController;
  PresentationFrameOrientation _orientation;
  bool _closed = false;

  PresentationExecutionReceipt? get lastReceipt =>
      _executionController.lastReceipt;

  bool get isPlaying => _playbackController.isPlaying;

  PresentationFrameOrientation get orientation => _orientation;

  void setOrientation(PresentationFrameOrientation value) {
    if (_orientation == value) return;
    _orientation = value;
    final current = this.value;
    if (current == null) return;
    this.value = RuntimePresentationFrameSnapshot(
      assetRevision: current.assetRevision,
      frame: current.frame,
      orientation: value,
      orientationOverrides: current.orientationOverrides,
      mediaBindings: current.mediaBindings,
      reduceMotion: current.reduceMotion,
      reduceFlashes: current.reduceFlashes,
      showCaptions: current.showCaptions,
    );
  }

  @override
  Future<RuntimePresentationExecutionTerminal> playPresentationCinematic(
    ScenePresentationCinematicRuntimeRequest request,
  ) {
    unawaited(_preloadCaptions(request.asset));
    return _playbackController.playPresentationCinematic(request);
  }

  final _captionSegmentsByMediaId =
      <String, List<PresentationCaptionSegment>>{};
  final _captionFailuresByMediaId =
      <String, PresentationCaptionUnavailable>{};

  /// Loads and decodes the WebVTT captions referenced by the asset's caption
  /// clips through the SAME shared decoder the Studio preview uses —
  /// BETA-CIN-078. Failures are kept as explicit per-media diagnostics.
  Future<void> _preloadCaptions(PresentationCinematicAsset asset) async {
    for (final track in asset.tracks) {
      for (final clip in track.clips) {
        if (clip is! PresentationCaptionClip) continue;
        final mediaId = clip.captionId;
        if (_captionSegmentsByMediaId.containsKey(mediaId) ||
            _captionFailuresByMediaId.containsKey(mediaId)) {
          continue;
        }
        final media = catalog.find(mediaId);
        if (media == null || media.kind != ProjectMediaKind.captions) {
          _captionFailuresByMediaId[mediaId] = PresentationCaptionUnavailable(
            reason: PresentationContentUnavailableReason.missing,
            message: 'Sous-titre $mediaId introuvable dans le catalogue',
          );
          continue;
        }
        try {
          final bytes =
              await File.fromUri(_resolveMediaUri(media)).readAsBytes();
          _captionSegmentsByMediaId[mediaId] =
              decodePresentationCaptionWebVtt(bytes);
        } on FormatException catch (error) {
          _captionFailuresByMediaId[mediaId] = PresentationCaptionUnavailable(
            reason: PresentationContentUnavailableReason.unsupported,
            message: error.message,
          );
        } on Object {
          _captionFailuresByMediaId[mediaId] = PresentationCaptionUnavailable(
            reason: PresentationContentUnavailableReason.missing,
            message: 'Sous-titre $mediaId illisible',
          );
        }
      }
    }
  }

  Future<RuntimePresentationExecutionTerminal?> skipActive() =>
      _playbackController.skipActive();

  Future<RuntimePresentationExecutionTerminal?> cancelActive() =>
      _playbackController.cancelActive();

  Future<void> pauseForLifecycle() => _playbackController.pauseForLifecycle();

  Future<void> resumeAfterLifecycle() =>
      _playbackController.resumeAfterLifecycle();

  void _publishFrame(
    ScenePresentationCinematicRuntimeRequest request,
    PresentationFrame? frame,
  ) {
    if (_closed) return;
    if (frame == null) {
      value = null;
      return;
    }
    value = RuntimePresentationFrameSnapshot(
      assetRevision: request.contentHash,
      frame: frame,
      orientation: _orientation,
      orientationOverrides: _orientationOverrides(request.asset),
      mediaBindings: _mediaBindings(request.asset),
      reduceMotion: reduceMotion,
      reduceFlashes: reduceFlashes,
      showCaptions: showCaptions,
    );
  }

  PresentationFrameOrientationOverrides _orientationOverrides(
    PresentationCinematicAsset asset,
  ) =>
      PresentationFrameOrientationOverrides(
        visualsByClipId: <String, PresentationVisualOrientationOverride>{
          for (final track in asset.tracks)
            for (final clip in track.clips)
              if ((clip is PresentationVisualClip ||
                      clip is PresentationTextClip) &&
                  (_landscapeCompositionOverride(clip) != null ||
                      _portraitCompositionOverride(clip) != null))
                clip.id: PresentationVisualOrientationOverride(
                  landscape: _landscapeCompositionOverride(clip),
                  portrait: _portraitCompositionOverride(clip),
                  reducedMotionLandscape: _landscapeCompositionOverride(clip),
                  reducedMotionPortrait: _portraitCompositionOverride(clip),
                ),
        },
      );

  String _resolveVisualMediaId(
    ScenePresentationCinematicRuntimeRequest request,
    PresentationVisualFrameClip frameClip,
  ) {
    for (final track in request.asset.tracks) {
      for (final clip in track.clips) {
        if (clip is! PresentationVisualClip || clip.id != frameClip.clipId) {
          continue;
        }
        return switch (_orientation) {
          PresentationFrameOrientation.landscape =>
            clip.landscapeResourceId ?? clip.resourceId,
          PresentationFrameOrientation.portrait =>
            clip.portraitResourceId ?? clip.resourceId,
        };
      }
    }
    return frameClip.resourceId;
  }

  Uri _resolveMediaUri(ProjectMediaAsset media) {
    final uri = mediaUris[media.id];
    if (uri == null || uri.scheme != 'file') {
      throw StateError('Installed Presentation media ${media.id} is missing.');
    }
    return uri;
  }

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    final media = catalog.find(clip.resourceId);
    if (media == null) {
      return PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Presentation media ${clip.resourceId} is missing.',
      );
    }
    if (media.kind == ProjectMediaKind.video) {
      final playback = _mediaController.snapshot;
      final handle = playback.videoHandle;
      if (handle != null &&
          playback.resolvedMediaId != null &&
          _videoDriver is VideoPlayerPresentationPlaybackDriver) {
        return PresentationVisualReady(
          child: _videoDriver.buildVideo(handle),
        );
      }
      final posterId = media.posterMediaId;
      if (posterId != null) return _resolveFileVisual(posterId);
      return const PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.unsupported,
        message: 'The Presentation video decoder is unavailable.',
      );
    }
    if (media.kind != ProjectMediaKind.image &&
        media.kind != ProjectMediaKind.poster) {
      return const PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.unsupported,
        message: 'This Presentation media is not visual.',
      );
    }
    return _resolveFileVisual(media.id);
  }

  PresentationVisualResolution _resolveFileVisual(String mediaId) {
    final uri = mediaUris[mediaId];
    if (uri == null || uri.scheme != 'file') {
      return PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Installed Presentation media $mediaId is missing.',
      );
    }
    return PresentationVisualReady(
      child: Image.file(
        File.fromUri(uri),
        key: ValueKey<String>('runtime-presentation-media-$mediaId'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (_, __, ___) => const SizedBox.expand(),
      ),
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) {
    final failure = _captionFailuresByMediaId[clip.captionId];
    if (failure != null) return failure;
    final segments = _captionSegmentsByMediaId[clip.captionId];
    if (segments == null) {
      return PresentationCaptionUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Sous-titre ${clip.captionId} en cours de chargement',
      );
    }
    final active = activePresentationCaptionSegment(
      segments,
      elapsedUs: clip.elapsedUs,
    );
    return PresentationCaptionReady(text: active?.text ?? '');
  }

  Future<void> _detachBeforeTerminal() async {
    if (value == null) return;
    value = null;
    SchedulerBinding.instance.scheduleFrame();
    await SchedulerBinding.instance.endOfFrame.timeout(
      const Duration(milliseconds: 250),
      onTimeout: () {},
    );
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    value = null;
    await _playbackController.dispose();
  }

  @override
  void dispose() {
    unawaited(close());
    super.dispose();
  }
}

PresentationVisualComposition? _landscapeCompositionOverride(
  PresentationClip clip,
) =>
    switch (clip) {
      PresentationVisualClip() => clip.landscapeCompositionOverride,
      PresentationTextClip() => clip.landscapeCompositionOverride,
      _ => null,
    };

PresentationVisualComposition? _portraitCompositionOverride(
  PresentationClip clip,
) =>
    switch (clip) {
      PresentationVisualClip() => clip.portraitCompositionOverride,
      PresentationTextClip() => clip.portraitCompositionOverride,
      _ => null,
    };

List<PresentationFrameMediaBinding> _mediaBindings(
  PresentationCinematicAsset asset,
) =>
    <PresentationFrameMediaBinding>[
      for (final track in asset.tracks)
        for (final clip in track.clips)
          if (clip is PresentationVisualClip)
            PresentationFrameMediaBinding(
              clipId: clip.id,
              kind: switch (clip.mediaKind) {
                PresentationVisualMediaKind.image =>
                  PresentationFrameMediaKind.image,
                PresentationVisualMediaKind.video =>
                  PresentationFrameMediaKind.video,
                PresentationVisualMediaKind.poster =>
                  PresentationFrameMediaKind.poster,
              },
              landscapeResourceId: clip.landscapeResourceId,
              portraitResourceId: clip.portraitResourceId,
              sharedResourceId: clip.resourceId,
            ),
    ];
