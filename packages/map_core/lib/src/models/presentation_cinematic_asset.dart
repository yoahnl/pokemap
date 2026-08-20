import 'package:meta/meta.dart' show immutable;

import 'presentation_dialogue_contract.dart';

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

enum PresentationVisualMediaKind { image, video, poster }

enum PresentationMarkerKind { ordinary, interactionCue }

enum PresentationTextWeight { regular, medium, bold }

enum PresentationTextAlignment { start, center, end }

enum PresentationTextWrapping { wrap, noWrap }

enum PresentationAudioKind { music, voice, soundEffect }

enum PresentationAudioBus { music, voice, effects }

enum PresentationCaptionStyle { standard, highContrast }

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
    List<PresentationVisualFolder> visualFolders =
        const <PresentationVisualFolder>[],
    List<PresentationTrack> tracks = const <PresentationTrack>[],
  }) : id = _requiredString(id, r'$.id'),
       title = _requiredString(title, r'$.title'),
       description = _optionalString(description),
       layers = List<PresentationLayer>.unmodifiable(layers),
       visualFolders = List<PresentationVisualFolder>.unmodifiable(
         visualFolders,
       ),
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

  static const int schemaVersion = 3;
  static const int ticksPerSecond = 1000000;
  static const String timeUnit = 'microsecond';
  static const List<String> capabilities = <String>['cinematic.presentation'];

  final String id;
  final String title;
  final String? description;
  final int durationUs;
  final List<PresentationLayer> layers;
  final List<PresentationVisualFolder> visualFolders;
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

    final orderedLayerIds = layers.toList()
      ..sort((left, right) {
        final zOrder = right.zIndex.compareTo(left.zIndex);
        return zOrder != 0 ? zOrder : left.id.compareTo(right.id);
      });
    final orderedIds = orderedLayerIds.map((layer) => layer.id).toList();
    final folderIds = <String>{};
    final assignedLayerIds = <String>{};
    for (
      var folderIndex = 0;
      folderIndex < visualFolders.length;
      folderIndex += 1
    ) {
      final folder = visualFolders[folderIndex];
      if (!folderIds.add(folder.id)) {
        throw PresentationCinematicValidationException(
          code: PresentationCinematicValidationErrorCode.duplicateId,
          message: 'Duplicate visual folder id ${folder.id}',
          path:
              r'$.visualFolders'
              '[$folderIndex].id',
        );
      }
      final positions = <int>[];
      for (
        var layerIndex = 0;
        layerIndex < folder.layerIds.length;
        layerIndex += 1
      ) {
        final layerId = folder.layerIds[layerIndex];
        final position = orderedIds.indexOf(layerId);
        if (position < 0) {
          throw PresentationCinematicValidationException(
            code: PresentationCinematicValidationErrorCode.danglingLayer,
            message: 'Unknown visual folder layer id $layerId',
            path:
                r'$.visualFolders'
                '[$folderIndex].layerIds[$layerIndex]',
          );
        }
        if (!assignedLayerIds.add(layerId)) {
          throw PresentationCinematicValidationException(
            code: PresentationCinematicValidationErrorCode.invalidValue,
            message: 'A visual layer can belong to only one folder',
            path:
                r'$.visualFolders'
                '[$folderIndex].layerIds[$layerIndex]',
          );
        }
        positions.add(position);
      }
      for (var index = 0; index < positions.length; index += 1) {
        if (positions[index] != positions.first + index) {
          throw PresentationCinematicValidationException(
            code: PresentationCinematicValidationErrorCode.invalidValue,
            message: 'A visual folder must form one contiguous z-order block',
            path:
                r'$.visualFolders'
                '[$folderIndex].layerIds',
          );
        }
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
        final layerId = switch (clip) {
          PresentationVisualClip() => clip.layerId,
          PresentationTextClip() => clip.layerId,
          _ => null,
        };
        if (layerId != null) {
          if (!layerIds.contains(layerId)) {
            throw PresentationCinematicValidationException(
              code: PresentationCinematicValidationErrorCode.danglingLayer,
              message: 'Unknown layer id $layerId',
              path: '$clipPath.layerId',
            );
          }
        }
      }
    }
  }

  PresentationVisualFolder? folderForLayer(String layerId) {
    for (final folder in visualFolders) {
      if (folder.layerIds.contains(layerId)) return folder;
    }
    return null;
  }

  bool isLayerEffectivelyVisible(String layerId) {
    final layer = _layer(layerId);
    return layer.visible && !(folderForLayer(layerId)?.hidden ?? false);
  }

  bool isLayerEffectivelyLocked(String layerId) {
    final layer = _layer(layerId);
    return layer.locked || (folderForLayer(layerId)?.locked ?? false);
  }

  PresentationLayer _layer(String layerId) {
    for (final layer in layers) {
      if (layer.id == layerId) return layer;
    }
    throw ArgumentError.value(layerId, 'layerId', 'unknown layer');
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
          _listEquals(other.visualFolders, visualFolders) &&
          _listEquals(other.tracks, tracks);

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    durationUs,
    Object.hashAll(layers),
    Object.hashAll(visualFolders),
    Object.hashAll(tracks),
  );
}

@immutable
final class PresentationLayer {
  PresentationLayer({
    required String id,
    required String label,
    required this.zIndex,
    this.visible = true,
    this.locked = false,
  }) : id = _requiredString(id, 'PresentationLayer.id'),
       label = _requiredString(label, 'PresentationLayer.label');

  final String id;
  final String label;
  final int zIndex;
  final bool visible;
  final bool locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationLayer &&
          other.id == id &&
          other.label == label &&
          other.zIndex == zIndex &&
          other.visible == visible &&
          other.locked == locked;

  @override
  int get hashCode => Object.hash(id, label, zIndex, visible, locked);
}

@immutable
final class PresentationVisualFolder {
  PresentationVisualFolder({
    required String id,
    required String label,
    List<String> layerIds = const <String>[],
    this.hidden = false,
    this.locked = false,
  }) : id = _requiredString(id, 'PresentationVisualFolder.id'),
       label = _requiredString(label, 'PresentationVisualFolder.label'),
       layerIds = List<String>.unmodifiable(
         layerIds.map(
           (layerId) =>
               _requiredString(layerId, 'PresentationVisualFolder.layerIds'),
         ),
       ) {
    if (layerIds.toSet().length != layerIds.length) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.duplicateId,
        message: 'A visual folder cannot contain a layer twice',
        path: 'PresentationVisualFolder.layerIds',
      );
    }
  }

  final String id;
  final String label;
  final List<String> layerIds;
  final bool hidden;
  final bool locked;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationVisualFolder &&
          other.id == id &&
          other.label == label &&
          _listEquals(other.layerIds, layerIds) &&
          other.hidden == hidden &&
          other.locked == locked;

  @override
  int get hashCode =>
      Object.hash(id, label, Object.hashAll(layerIds), hidden, locked);
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
    this.holdPolicy = PresentationHoldTrackPolicy.frozen,
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

  /// What this track's media do while an interaction cue holds the
  /// timeline: frozen by default, ambient continuation only when explicitly
  /// authored (BETA-CIN-077).
  final PresentationHoldTrackPolicy holdPolicy;
  final List<PresentationClip> clips;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTrack &&
          other.id == id &&
          other.label == label &&
          other.kind == kind &&
          other.holdPolicy == holdPolicy &&
          _listEquals(other.clips, clips);

  @override
  int get hashCode =>
      Object.hash(id, label, kind, holdPolicy, Object.hashAll(clips));
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
    this.mediaKind = PresentationVisualMediaKind.image,
    String? landscapeResourceId,
    String? portraitResourceId,
    this.landscapeCompositionOverride,
    this.portraitCompositionOverride,
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
       landscapeResourceId = _optionalString(landscapeResourceId),
       portraitResourceId = _optionalString(portraitResourceId),
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
  final PresentationVisualMediaKind mediaKind;
  final String? landscapeResourceId;
  final String? portraitResourceId;
  final PresentationVisualComposition? landscapeCompositionOverride;
  final PresentationVisualComposition? portraitCompositionOverride;
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
          other.mediaKind == mediaKind &&
          other.landscapeResourceId == landscapeResourceId &&
          other.portraitResourceId == portraitResourceId &&
          other.landscapeCompositionOverride == landscapeCompositionOverride &&
          other.portraitCompositionOverride == portraitCompositionOverride &&
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
    mediaKind,
    landscapeResourceId,
    portraitResourceId,
    landscapeCompositionOverride,
    portraitCompositionOverride,
    easing,
    from,
    to,
    transitionIn,
    transitionOut,
  );
}

@immutable
final class PresentationTextStyle {
  PresentationTextStyle({
    String? fontFamily,
    this.fontSize = 48,
    this.weight = PresentationTextWeight.regular,
    this.alignment = PresentationTextAlignment.center,
    this.wrapping = PresentationTextWrapping.wrap,
    String colorHex = '#FFFFFF',
    this.respectSafeArea = true,
  }) : fontFamily = _optionalString(fontFamily),
       colorHex = _colorHex(colorHex, 'PresentationTextStyle.colorHex') {
    _positiveFinite(fontSize, 'PresentationTextStyle.fontSize');
  }

  final String? fontFamily;
  final double fontSize;
  final PresentationTextWeight weight;
  final PresentationTextAlignment alignment;
  final PresentationTextWrapping wrapping;
  final String colorHex;
  final bool respectSafeArea;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTextStyle &&
          other.fontFamily == fontFamily &&
          other.fontSize == fontSize &&
          other.weight == weight &&
          other.alignment == alignment &&
          other.wrapping == wrapping &&
          other.colorHex == colorHex &&
          other.respectSafeArea == respectSafeArea;

  @override
  int get hashCode => Object.hash(
    fontFamily,
    fontSize,
    weight,
    alignment,
    wrapping,
    colorHex,
    respectSafeArea,
  );
}

@immutable
final class PresentationTextClip extends PresentationClip {
  PresentationTextClip({
    required super.id,
    required super.startUs,
    required super.durationUs,
    required String layerId,
    required String text,
    String? localizationKey,
    PresentationTextStyle? style,
    this.easing = PresentationEasing.linear,
    PresentationVisualComposition? from,
    PresentationVisualComposition? to,
    this.landscapeCompositionOverride,
    this.portraitCompositionOverride,
    PresentationVisualTransition? transitionIn,
    PresentationVisualTransition? transitionOut,
  }) : layerId = _requiredString(layerId, 'PresentationTextClip.layerId'),
       text = _requiredString(text, 'PresentationTextClip.text'),
       localizationKey = _optionalString(localizationKey),
       style = style ?? PresentationTextStyle(),
       from = from ?? PresentationVisualComposition.identity,
       to = to ?? PresentationVisualComposition.identity,
       transitionIn = transitionIn ?? PresentationVisualTransition.none,
       transitionOut = transitionOut ?? PresentationVisualTransition.none,
       super(allowZeroDuration: false) {
    if (this.transitionIn.durationUs > durationUs) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Entry transition exceeds clip duration',
        path: 'PresentationTextClip.transitionIn',
      );
    }
    if (this.transitionOut.durationUs > durationUs) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Exit transition exceeds clip duration',
        path: 'PresentationTextClip.transitionOut',
      );
    }
  }

  final String layerId;
  final String text;
  final String? localizationKey;
  final PresentationTextStyle style;
  final PresentationEasing easing;
  final PresentationVisualComposition from;
  final PresentationVisualComposition to;
  final PresentationVisualComposition? landscapeCompositionOverride;
  final PresentationVisualComposition? portraitCompositionOverride;
  final PresentationVisualTransition transitionIn;
  final PresentationVisualTransition transitionOut;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.visual;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationTextClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.layerId == layerId &&
          other.text == text &&
          other.localizationKey == localizationKey &&
          other.style == style &&
          other.easing == easing &&
          other.from == from &&
          other.to == to &&
          other.landscapeCompositionOverride == landscapeCompositionOverride &&
          other.portraitCompositionOverride == portraitCompositionOverride &&
          other.transitionIn == transitionIn &&
          other.transitionOut == transitionOut;

  @override
  int get hashCode => Object.hash(
    id,
    startUs,
    durationUs,
    layerId,
    text,
    localizationKey,
    style,
    easing,
    from,
    to,
    landscapeCompositionOverride,
    portraitCompositionOverride,
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
    this.audioKind = PresentationAudioKind.music,
    String? landscapeResourceId,
    String? portraitResourceId,
    this.volume = 1,
    this.loop = false,
    this.fadeInUs = 0,
    this.fadeOutUs = 0,
    this.bus = PresentationAudioBus.music,
  }) : resourceId = _requiredString(
         resourceId,
         'PresentationAudioClip.resourceId',
       ),
       landscapeResourceId = _optionalString(landscapeResourceId),
       portraitResourceId = _optionalString(portraitResourceId),
       super(allowZeroDuration: false) {
    _unitInterval(volume, 'PresentationAudioClip.volume');
    if (fadeInUs < 0 || fadeInUs > durationUs) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'fadeInUs must fit inside the clip duration',
        path: 'PresentationAudioClip.fadeInUs',
      );
    }
    if (fadeOutUs < 0 || fadeOutUs > durationUs) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'fadeOutUs must fit inside the clip duration',
        path: 'PresentationAudioClip.fadeOutUs',
      );
    }
    if (audioKind == PresentationAudioKind.music &&
        this.landscapeResourceId != null) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Music must use one shared source',
        path: 'PresentationAudioClip.landscapeResourceId',
      );
    }
    if (audioKind == PresentationAudioKind.music &&
        this.portraitResourceId != null) {
      throw const PresentationCinematicValidationException(
        code: PresentationCinematicValidationErrorCode.invalidValue,
        message: 'Music must use one shared source',
        path: 'PresentationAudioClip.portraitResourceId',
      );
    }
  }

  final String resourceId;
  final PresentationAudioKind audioKind;
  final String? landscapeResourceId;
  final String? portraitResourceId;
  final double volume;
  final bool loop;
  final int fadeInUs;
  final int fadeOutUs;
  final PresentationAudioBus bus;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.audio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationAudioClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.resourceId == resourceId &&
          other.audioKind == audioKind &&
          other.landscapeResourceId == landscapeResourceId &&
          other.portraitResourceId == portraitResourceId &&
          other.volume == volume &&
          other.loop == loop &&
          other.fadeInUs == fadeInUs &&
          other.fadeOutUs == fadeOutUs &&
          other.bus == bus;

  @override
  int get hashCode => Object.hash(
    id,
    startUs,
    durationUs,
    resourceId,
    audioKind,
    landscapeResourceId,
    portraitResourceId,
    volume,
    loop,
    fadeInUs,
    fadeOutUs,
    bus,
  );
}

@immutable
final class PresentationCaptionClip extends PresentationClip {
  PresentationCaptionClip({
    required super.id,
    required super.startUs,
    required super.durationUs,
    required String captionId,
    String locale = 'und',
    this.style = PresentationCaptionStyle.standard,
    this.fallbackToProjectDefault = true,
  }) : captionId = _requiredString(
         captionId,
         'PresentationCaptionClip.captionId',
       ),
       locale = _requiredString(locale, 'PresentationCaptionClip.locale'),
       super(allowZeroDuration: false);

  final String captionId;
  final String locale;
  final PresentationCaptionStyle style;
  final bool fallbackToProjectDefault;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.caption;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationCaptionClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.durationUs == durationUs &&
          other.captionId == captionId &&
          other.locale == locale &&
          other.style == style &&
          other.fallbackToProjectDefault == fallbackToProjectDefault;

  @override
  int get hashCode => Object.hash(
    id,
    startUs,
    durationUs,
    captionId,
    locale,
    style,
    fallbackToProjectDefault,
  );
}

@immutable
final class PresentationMarkerClip extends PresentationClip {
  PresentationMarkerClip({
    required super.id,
    required super.startUs,
    required String label,
    this.markerKind = PresentationMarkerKind.ordinary,
    this.required = false,
  }) : label = _requiredString(label, 'PresentationMarkerClip.label'),
       super(durationUs: 0, allowZeroDuration: true);

  final String label;
  final PresentationMarkerKind markerKind;
  final bool required;

  @override
  PresentationTrackKind get trackKind => PresentationTrackKind.marker;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PresentationMarkerClip &&
          other.id == id &&
          other.startUs == startUs &&
          other.label == label &&
          other.markerKind == markerKind &&
          other.required == required;

  @override
  int get hashCode => Object.hash(id, startUs, label, markerKind, required);
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

String _colorHex(String value, String path) {
  final normalized = _requiredString(value, path).toUpperCase();
  if (!RegExp(r'^#[0-9A-F]{6}([0-9A-F]{2})?$').hasMatch(normalized)) {
    throw PresentationCinematicValidationException(
      code: PresentationCinematicValidationErrorCode.invalidValue,
      message: 'Color must use #RRGGBB or #RRGGBBAA',
      path: path,
    );
  }
  return normalized;
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
