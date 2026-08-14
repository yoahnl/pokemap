import 'package:meta/meta.dart' show immutable;

enum PresentationTrackKind { visual, audio, caption, marker }

enum PresentationEasing { linear, easeIn, easeOut, easeInOut }

enum PresentationVisualTransitionKind {
  none,
  fade,
  slideLeft,
  slideRight,
  slideUp,
  slideDown,
}

enum PresentationMarkerKind { ordinary, interactionCue }

enum PresentationCinematicValidationErrorCode {
  invalidValue,
  duplicateId,
  danglingLayer,
  incompatibleTrack,
  outOfBounds,
}

final class PresentationCinematicValidationException implements Exception {
  const PresentationCinematicValidationException({
    required this.code,
    required this.message,
    required this.path,
  });

  final PresentationCinematicValidationErrorCode code;
  final String message;
  final String path;

  @override
  String toString() =>
      'PresentationCinematicValidationException(${code.name}) at $path: $message';
}

@immutable
final class PresentationCinematicAsset {
  PresentationCinematicAsset({
    required String id,
    required String title,
    String? description,
    required this.durationUs,
    List<PresentationLayer> layers = const <PresentationLayer>[],
    List<PresentationTrack> tracks = const <PresentationTrack>[],
  }) : id = _requiredString(id, r'$.id'),
       title = _requiredString(title, r'$.title'),
       description = _optionalString(description),
       layers = List<PresentationLayer>.unmodifiable(layers),
       tracks = List<PresentationTrack>.unmodifiable(tracks) {
    if (durationUs <= 0) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'durationUs must be greater than zero',
        path: r'$.durationUs',
      );
    }
    _validateIdsAndReferences();
  }

  static const int schemaVersion = 1;
  static const int ticksPerSecond = 1000000;
  static const String timeUnit = 'microsecond';
  static const List<String> capabilities = <String>['cinematic.presentation'];

  final String id;
  final String title;
  final String? description;
  final int durationUs;
  final List<PresentationLayer> layers;
  final List<PresentationTrack> tracks;

  void _validateIdsAndReferences() {
    final layerIds = <String>{};
    for (var index = 0; index < layers.length; index += 1) {
      if (!layerIds.add(layers[index].id)) {
        throw PresentationCinematicValidationException(
          code: PresentationCinematicValidationErrorCode.duplicateId,
          message: 'Duplicate layer id ${layers[index].id}',
          path:
              r'$.layers'
              '[$index].id',
        );
      }
    }

    final trackIds = <String>{};
    final clipIds = <String>{};
    for (var trackIndex = 0; trackIndex < tracks.length; trackIndex += 1) {
      final track = tracks[trackIndex];
      if (!trackIds.add(track.id)) {
        throw PresentationCinematicValidationException(
          code: PresentationCinematicValidationErrorCode.duplicateId,
          message: 'Duplicate track id ${track.id}',
          path:
              r'$.tracks'
              '[$trackIndex].id',
        );
      }
      for (var clipIndex = 0; clipIndex < track.clips.length; clipIndex += 1) {
        final clip = track.clips[clipIndex];
        final clipPath =
            r'$.tracks'
            '[$trackIndex].clips[$clipIndex]';
        if (!clipIds.add(clip.id)) {
          throw PresentationCinematicValidationException(
            code: PresentationCinematicValidationErrorCode.duplicateId,
            message: 'Duplicate clip id ${clip.id}',
            path: '$clipPath.id',
          );
        }
        final exceedsDuration = clip is PresentationMarkerClip
            ? clip.startUs > durationUs
            : clip.endUs > durationUs;
        if (exceedsDuration) {
          throw PresentationCinematicValidationException(
            code: PresentationCinematicValidationErrorCode.outOfBounds,
            message: 'Clip ${clip.id} exceeds cinematic duration',
            path: clipPath,
          );
        }
        if (clip case final PresentationVisualClip visualClip) {
          if (!layerIds.contains(visualClip.layerId)) {
            throw PresentationCinematicValidationException(
              code: PresentationCinematicValidationErrorCode.danglingLayer,
              message: 'Unknown layer id ${visualClip.layerId}',
              path: '$clipPath.layerId',
            );
          }
        }
      }
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCinematicAsset &&
          other.id == id &&
          other.title == title &&
          other.description == description &&
          other.durationUs == durationUs &&
          _listEquals(other.layers, layers) &&
          _listEquals(other.tracks, tracks);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    durationUs,
    Object.hashAll(layers),
    Object.hashAll(tracks),
  );
}

@immutable
final class PresentationLayer {
  PresentationLayer({
    required String id,
    required String label,
    required this.zIndex,
  }) : id = _requiredString(id, 'PresentationLayer.id'),
       label = _requiredString(label, 'PresentationLayer.label');

  final String id;
  final String label;
  final int zIndex;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationLayer &&
          other.id == id &&
          other.label == label &&
          other.zIndex == zIndex;

  @override
  int get hashCode => Object.hash(id, label, zIndex);
}

@immutable
final class PresentationVisualComposition {
  PresentationVisualComposition({
    this.translateX = 0,
    this.translateY = 0,
    this.scaleX = 1,
    this.scaleY = 1,
    this.rotationTurns = 0,
    this.opacity = 1,
    this.cropLeft = 0,
    this.cropTop = 0,
    this.cropRight = 0,
    this.cropBottom = 0,
  }) {
    _finite(translateX, 'PresentationVisualComposition.translateX');
    _finite(translateY, 'PresentationVisualComposition.translateY');
    _positiveFinite(scaleX, 'PresentationVisualComposition.scaleX');
    _positiveFinite(scaleY, 'PresentationVisualComposition.scaleY');
    _finite(rotationTurns, 'PresentationVisualComposition.rotationTurns');
    _unitInterval(opacity, 'PresentationVisualComposition.opacity');
    _cropValue(cropLeft, 'PresentationVisualComposition.cropLeft');
    _cropValue(cropTop, 'PresentationVisualComposition.cropTop');
    _cropValue(cropRight, 'PresentationVisualComposition.cropRight');
    _cropValue(cropBottom, 'PresentationVisualComposition.cropBottom');
    if (cropLeft + cropRight >= 1) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Horizontal crop must leave visible content',
        path: 'PresentationVisualComposition.cropLeft',
      );
    }
    if (cropTop + cropBottom >= 1) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Vertical crop must leave visible content',
        path: 'PresentationVisualComposition.cropTop',
      );
    }
  }

  static final identity = PresentationVisualComposition();

  final double translateX;
  final double translateY;
  final double scaleX;
  final double scaleY;
  final double rotationTurns;
  final double opacity;
  final double cropLeft;
  final double cropTop;
  final double cropRight;
  final double cropBottom;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationVisualComposition &&
          other.translateX == translateX &&
          other.translateY == translateY &&
          other.scaleX == scaleX &&
          other.scaleY == scaleY &&
          other.rotationTurns == rotationTurns &&
          other.opacity == opacity &&
          other.cropLeft == cropLeft &&
          other.cropTop == cropTop &&
          other.cropRight == cropRight &&
          other.cropBottom == cropBottom;

  @override
  int get hashCode => Object.hash(
    translateX,
    translateY,
    scaleX,
    scaleY,
    rotationTurns,
    opacity,
    cropLeft,
    cropTop,
    cropRight,
    cropBottom,
  );
}

@immutable
final class PresentationVisualTransition {
  PresentationVisualTransition({
    this.kind = PresentationVisualTransitionKind.none,
    this.durationUs = 0,
  }) {
    if (durationUs < 0 ||
        (kind == PresentationVisualTransitionKind.none && durationUs != 0) ||
        (kind != PresentationVisualTransitionKind.none && durationUs == 0)) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Transition duration does not match its kind',
        path: 'PresentationVisualTransition.durationUs',
      );
    }
  }

  static final none = PresentationVisualTransition();

  final PresentationVisualTransitionKind kind;
  final int durationUs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationVisualTransition &&
          other.kind == kind &&
          other.durationUs == durationUs;

  @override
  int get hashCode => Object.hash(kind, durationUs);
}

@immutable
final class PresentationTrack {
  PresentationTrack({
    required String id,
    required String label,
    required this.kind,
    List<PresentationClip> clips = const <PresentationClip>[],
  }) : id = _requiredString(id, 'PresentationTrack.id'),
       label = _requiredString(label, 'PresentationTrack.label'),
       clips = List<PresentationClip>.unmodifiable(clips) {
    for (var index = 0; index < clips.length; index += 1) {
      if (clips[index].trackKind != kind) {
        throw PresentationCinematicValidationException(
          code: PresentationCinematicValidationErrorCode.incompatibleTrack,
          message: 'Clip ${clips[index].id} cannot belong to ${kind.name}',
          path: 'PresentationTrack.clips[$index]',
        );
      }
    }
  }

  final String id;
  final String label;
  final PresentationTrackKind kind;
  final List<PresentationClip> clips;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTrack &&
          other.id == id &&
          other.label == label &&
          other.kind == kind &&
          _listEquals(other.clips, clips);

  @override
  int get hashCode => Object.hash(id, label, kind, Object.hashAll(clips));
}

@immutable
sealed class PresentationClip {
  PresentationClip({
    required String id,
    required this.startUs,
    required this.durationUs,
    required bool allowZeroDuration,
  }) : id = _requiredString(id, 'PresentationClip.id') {
    if (startUs < 0) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'startUs must not be negative',
        path: 'PresentationClip.startUs',
      );
    }
    if (durationUs < 0 || (!allowZeroDuration && durationUs == 0)) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'durationUs must be positive for non-marker clips',
        path: 'PresentationClip.durationUs',
      );
    }
  }

  final String id;
  final int startUs;
  final int durationUs;

  PresentationTrackKind get trackKind;

  int get endUs => startUs + durationUs;
}

@immutable
final class PresentationVisualClip extends PresentationClip {
  PresentationVisualClip({
    required super.id,
    required super.startUs,
    required super.durationUs,
    required String layerId,
    required String resourceId,
    this.easing = PresentationEasing.linear,
    PresentationVisualComposition? from,
    PresentationVisualComposition? to,
    PresentationVisualTransition? transitionIn,
    PresentationVisualTransition? transitionOut,
  }) : layerId = _requiredString(layerId, 'PresentationVisualClip.layerId'),
       resourceId = _requiredString(
         resourceId,
         'PresentationVisualClip.resourceId',
       ),
       from = from ?? PresentationVisualComposition.identity,
       to = to ?? PresentationVisualComposition.identity,
       transitionIn = transitionIn ?? PresentationVisualTransition.none,
       transitionOut = transitionOut ?? PresentationVisualTransition.none,
       super(allowZeroDuration: false) {
    if (this.transitionIn.durationUs > durationUs) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Entry transition exceeds clip duration',
        path: 'PresentationVisualClip.transitionIn',
      );
    }
    if (this.transitionOut.durationUs > durationUs) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Exit transition exceeds clip duration',
        path: 'PresentationVisualClip.transitionOut',
      );
    }
  }

  final String layerId;
  final String resourceId;
  final PresentationEasing easing;
  final PresentationVisualComposition from;
  final PresentationVisualComposition to;
  final PresentationVisualTransition transitionIn;
  final PresentationVisualTransition transitionOut;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.visual;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationVisualClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.layerId == layerId &&
          other.resourceId == resourceId &&
          other.easing == easing &&
          other.from == from &&
          other.to == to &&
          other.transitionIn == transitionIn &&
          other.transitionOut == transitionOut;

  @override
  int get hashCode => Object.hash(
    id,
    startUs,
    durationUs,
    layerId,
    resourceId,
    easing,
    from,
    to,
    transitionIn,
    transitionOut,
  );
}

@immutable
final class PresentationAudioClip extends PresentationClip {
  PresentationAudioClip({
    required super.id,
    required super.startUs,
    required super.durationUs,
    required String resourceId,
  }) : resourceId = _requiredString(
         resourceId,
         'PresentationAudioClip.resourceId',
       ),
       super(allowZeroDuration: false);

  final String resourceId;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.audio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.resourceId == resourceId;

  @override
  int get hashCode => Object.hash(id, startUs, durationUs, resourceId);
}

@immutable
final class PresentationCaptionClip extends PresentationClip {
  PresentationCaptionClip({
    required super.id,
    required super.startUs,
    required super.durationUs,
    required String captionId,
  }) : captionId = _requiredString(
         captionId,
         'PresentationCaptionClip.captionId',
       ),
       super(allowZeroDuration: false);

  final String captionId;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.caption;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCaptionClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.captionId == captionId;

  @override
  int get hashCode => Object.hash(id, startUs, durationUs, captionId);
}

@immutable
final class PresentationMarkerClip extends PresentationClip {
  PresentationMarkerClip({
    required super.id,
    required super.startUs,
    required String label,
    this.markerKind = PresentationMarkerKind.ordinary,
  }) : label = _requiredString(label, 'PresentationMarkerClip.label'),
       super(durationUs: 0, allowZeroDuration: true);

  final String label;
  final PresentationMarkerKind markerKind;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.marker;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationMarkerClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.label == label &&
          other.markerKind == markerKind;

  @override
  int get hashCode => Object.hash(id, startUs, label, markerKind);
}

String _requiredString(String value, String path) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw PresentationCinematicValidationException(
      code: PresentationCinematicValidationErrorCode.invalidValue,
      message: 'Value must not be empty',
      path: path,
    );
  }
  return trimmed;
}

String? _optionalString(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? null : trimmed;
}

void _finite(double value, String path) {
  if (!value.isFinite) {
    throw PresentationCinematicValidationException(
      code: PresentationCinematicValidationErrorCode.invalidValue,
      message: 'Value must be finite',
      path: path,
    );
  }
}

void _positiveFinite(double value, String path) {
  if (!value.isFinite || value <= 0) {
    throw PresentationCinematicValidationException(
      code: PresentationCinematicValidationErrorCode.invalidValue,
      message: 'Value must be finite and greater than zero',
      path: path,
    );
  }
}

void _unitInterval(double value, String path) {
  if (!value.isFinite || value < 0 || value > 1) {
    throw PresentationCinematicValidationException(
      code: PresentationCinematicValidationErrorCode.invalidValue,
      message: 'Value must be between zero and one',
      path: path,
    );
  }
}

void _cropValue(double value, String path) {
  if (!value.isFinite || value < 0 || value >= 1) {
    throw PresentationCinematicValidationException(
      code: PresentationCinematicValidationErrorCode.invalidValue,
      message: 'Crop must be at least zero and less than one',
      path: path,
    );
  }
}

bool _listEquals<T>(List<T> left, List<T> right) {
  if (identical(left, right)) {
    return true;
  }
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}
