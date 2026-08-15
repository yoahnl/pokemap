import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/presentation_renderer.dart';

import '../../../../application/authoring_api/presentation_timeline_projection_gateway.dart';

final class PresentationStudioProjectContentController extends ChangeNotifier
    implements PresentationFrameContentPort {
  PresentationStudioProjectContentController({
    required this.projectRootPath,
    required PresentationTimelineProjectionMediaReader mediaReader,
    required PresentationTimelineProjectionGateway projectionGateway,
  }) : _mediaReader = mediaReader,
       _projectionGateway = projectionGateway;

  final String projectRootPath;
  final PresentationTimelineProjectionMediaReader _mediaReader;
  final PresentationTimelineProjectionGateway _projectionGateway;

  Map<String, _PresentationStudioVisualContent> _visuals =
      const <String, _PresentationStudioVisualContent>{};
  Map<String, PresentationTimelineMediaProjection> _captions =
      const <String, PresentationTimelineMediaProjection>{};
  int _generation = 0;
  bool _disposed = false;

  Future<void> prepare(PresentationCinematicAsset asset) async {
    final generation = ++_generation;
    final visualIds = <String>{
      for (final track in asset.tracks)
        for (final clip in track.clips)
          if (clip is PresentationVisualClip) ...<String>{
            clip.resourceId,
            if (clip.landscapeResourceId != null) clip.landscapeResourceId!,
            if (clip.portraitResourceId != null) clip.portraitResourceId!,
          },
    };
    final captionIds = <String>{
      for (final track in asset.tracks)
        for (final clip in track.clips)
          if (clip is PresentationCaptionClip) clip.captionId,
    };
    final visualEntries = await Future.wait(visualIds.map(_loadVisual));
    final captionEntries = await Future.wait(captionIds.map(_loadCaption));
    if (_disposed || generation != _generation) return;
    _visuals = Map<String, _PresentationStudioVisualContent>.unmodifiable(
      Map<String, _PresentationStudioVisualContent>.fromEntries(visualEntries),
    );
    _captions = Map<String, PresentationTimelineMediaProjection>.unmodifiable(
      Map<String, PresentationTimelineMediaProjection>.fromEntries(
        captionEntries,
      ),
    );
    notifyListeners();
  }

  Future<MapEntry<String, _PresentationStudioVisualContent>> _loadVisual(
    String mediaId,
  ) async {
    try {
      final media = await _mediaReader.read(projectRootPath, mediaId);
      return MapEntry(mediaId, _visualContent(mediaId, media));
    } on Object {
      return MapEntry(
        mediaId,
        _PresentationStudioVisualContent.unavailable(
          reason: PresentationContentUnavailableReason.unsupported,
          message: 'Impossible de préparer le média $mediaId',
        ),
      );
    }
  }

  Future<MapEntry<String, PresentationTimelineMediaProjection>> _loadCaption(
    String mediaId,
  ) async {
    try {
      final projection = await _projectionGateway.load(
        projectRootPath,
        PresentationTimelineProjectionRequest(
          mediaId: mediaId,
          kind: PresentationTimelineProjectionKind.captions,
          sampleCount: 1,
        ),
      );
      return MapEntry(mediaId, projection);
    } on Object {
      return MapEntry(
        mediaId,
        PresentationTimelineMediaProjection.unavailable(
          mediaId: mediaId,
          status: PresentationTimelineProjectionStatus.error,
          diagnostic: 'Impossible de préparer le sous-titre $mediaId',
        ),
      );
    }
  }

  @override
  PresentationVisualResolution resolveVisual({
    required PresentationVisualFrameClip clip,
    required PresentationFrameOrientation orientation,
  }) {
    final content = _visuals[clip.resourceId];
    if (content == null) {
      return PresentationVisualUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Média ${clip.resourceId} en cours de chargement',
      );
    }
    final bytes = content.bytes;
    if (bytes == null) {
      return PresentationVisualUnavailable(
        reason: content.reason,
        message: content.message,
      );
    }
    return PresentationVisualReady(
      child: Image.memory(
        bytes,
        key: ValueKey<String>('presentation-studio-media-${clip.resourceId}'),
        fit: BoxFit.cover,
        gaplessPlayback: true,
        errorBuilder: (context, error, stackTrace) => Semantics(
          label: 'Média ${clip.resourceId} illisible',
          child: const SizedBox.expand(),
        ),
      ),
    );
  }

  @override
  PresentationCaptionResolution resolveCaption({
    required PresentationCaptionFrameClip clip,
    required Locale locale,
  }) {
    final projection = _captions[clip.captionId];
    if (projection == null) {
      return PresentationCaptionUnavailable(
        reason: PresentationContentUnavailableReason.missing,
        message: 'Sous-titre ${clip.captionId} en cours de chargement',
      );
    }
    if (!projection.available) {
      return PresentationCaptionUnavailable(
        reason:
            projection.status == PresentationTimelineProjectionStatus.missing
            ? PresentationContentUnavailableReason.missing
            : PresentationContentUnavailableReason.unsupported,
        message:
            projection.diagnostic ??
            'Sous-titre ${clip.captionId} indisponible',
      );
    }
    for (final segment in projection.captions) {
      if (segment.startUs <= clip.elapsedUs && clip.elapsedUs < segment.endUs) {
        return PresentationCaptionReady(text: segment.text);
      }
    }
    return const PresentationCaptionReady(text: '');
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}

_PresentationStudioVisualContent _visualContent(
  String mediaId,
  PresentationTimelineProjectionMedia? media,
) {
  if (media == null || !media.sourceAvailable) {
    return _PresentationStudioVisualContent.unavailable(
      reason: PresentationContentUnavailableReason.missing,
      message: 'Média $mediaId introuvable',
    );
  }
  final bytes = switch (media.kind) {
    ProjectMediaKind.image || ProjectMediaKind.poster => media.sourceBytes,
    ProjectMediaKind.video => media.posterBytes,
    _ => null,
  };
  if (bytes != null) {
    return _PresentationStudioVisualContent.ready(bytes);
  }
  final supportedKind =
      media.kind == ProjectMediaKind.image ||
      media.kind == ProjectMediaKind.poster ||
      media.kind == ProjectMediaKind.video;
  return _PresentationStudioVisualContent.unavailable(
    reason: supportedKind
        ? PresentationContentUnavailableReason.missing
        : PresentationContentUnavailableReason.unsupported,
    message: supportedKind
        ? 'Aperçu de $mediaId introuvable'
        : 'Le média $mediaId ne peut pas être rendu sur une piste visuelle',
  );
}

final class _PresentationStudioVisualContent {
  const _PresentationStudioVisualContent.ready(Uint8List this.bytes)
    : reason = PresentationContentUnavailableReason.missing,
      message = '';

  const _PresentationStudioVisualContent.unavailable({
    required this.reason,
    required this.message,
  }) : bytes = null;

  final Uint8List? bytes;
  final PresentationContentUnavailableReason reason;
  final String message;
}
