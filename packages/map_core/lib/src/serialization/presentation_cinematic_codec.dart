import '../models/presentation_cinematic_asset.dart';

enum PresentationCinematicCodecErrorCode {
  invalidRoot,
  unsupportedSchema,
  unsupportedCapability,
  unsupportedKind,
  unexpectedField,
  invalidValue,
  duplicateId,
  danglingReference,
  incompatibleTrack,
  outOfBounds,
}

class PresentationCinematicCodecException extends FormatException {
  PresentationCinematicCodecException({
    required this.code,
    required String message,
    required this.path,
  }) : super(message);

  final PresentationCinematicCodecErrorCode code;
  final String path;

  @override
  String toString() =>
      'PresentationCinematicCodecException(${code.name}) at $path: $message';
}

final class UnsupportedPresentationCinematicSchema
    extends PresentationCinematicCodecException {
  UnsupportedPresentationCinematicSchema(this.schemaVersion)
    : super(
        code: PresentationCinematicCodecErrorCode.unsupportedSchema,
        message: schemaVersion == null
            ? 'Presentation cinematic schemaVersion 1 is required'
            : 'Unsupported Presentation cinematic schemaVersion: '
                  '$schemaVersion',
        path: r'$.schemaVersion',
      );

  final Object? schemaVersion;
}

PresentationCinematicAsset decodePresentationCinematicAsset(Object? json) {
  final root = _object(json, path: r'$', root: true);
  _allowedFields(root, const {
    'schemaVersion',
    'capabilities',
    'timebase',
    'id',
    'title',
    'description',
    'durationUs',
    'layers',
    'tracks',
  }, path: r'$');

  final schemaVersion = root['schemaVersion'];
  if (schemaVersion != PresentationCinematicAsset.schemaVersion) {
    throw UnsupportedPresentationCinematicSchema(schemaVersion);
  }
  _validateCapabilities(root['capabilities']);
  _validateTimebase(root['timebase']);

  try {
    return PresentationCinematicAsset(
      id: _string(root['id'], path: r'$.id'),
      title: _string(root['title'], path: r'$.title'),
      description: _optionalString(root['description'], path: r'$.description'),
      durationUs: _integer(root['durationUs'], path: r'$.durationUs'),
      layers: _decodeLayers(root['layers']),
      tracks: _decodeTracks(root['tracks']),
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: r'$');
  }
}

Map<String, Object?> encodePresentationCinematicAsset(
  PresentationCinematicAsset asset,
) {
  return {
    'schemaVersion': PresentationCinematicAsset.schemaVersion,
    'capabilities': List<String>.of(PresentationCinematicAsset.capabilities),
    'timebase': {
      'unit': PresentationCinematicAsset.timeUnit,
      'ticksPerSecond': PresentationCinematicAsset.ticksPerSecond,
    },
    'id': asset.id,
    'title': asset.title,
    if (asset.description != null) 'description': asset.description,
    'durationUs': asset.durationUs,
    'layers': [for (final layer in asset.layers) _encodeLayer(layer)],
    'tracks': [for (final track in asset.tracks) _encodeTrack(track)],
  };
}

void _validateCapabilities(Object? value) {
  final capabilities = _list(value, path: r'$.capabilities');
  for (var index = 0; index < capabilities.length; index += 1) {
    final capability = capabilities[index];
    if (!PresentationCinematicAsset.capabilities.contains(capability)) {
      throw PresentationCinematicCodecException(
        code: PresentationCinematicCodecErrorCode.unsupportedCapability,
        message: 'Unsupported capability: $capability',
        path:
            r'$.capabilities'
            '[$index]',
      );
    }
  }
  if (capabilities.length != PresentationCinematicAsset.capabilities.length) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.unsupportedCapability,
      message: 'Exactly cinematic.presentation is required',
      path: r'$.capabilities',
    );
  }
}

void _validateTimebase(Object? value) {
  final timebase = _object(value, path: r'$.timebase');
  _allowedFields(timebase, const {
    'unit',
    'ticksPerSecond',
  }, path: r'$.timebase');
  if (timebase['unit'] != PresentationCinematicAsset.timeUnit ||
      timebase['ticksPerSecond'] != PresentationCinematicAsset.ticksPerSecond) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Timebase must be microsecond at 1000000 ticks per second',
      path: r'$.timebase',
    );
  }
}

List<PresentationLayer> _decodeLayers(Object? value) {
  final layers = _list(value, path: r'$.layers');
  return List<PresentationLayer>.unmodifiable([
    for (var index = 0; index < layers.length; index += 1)
      _decodeLayer(layers[index], index),
  ]);
}

PresentationLayer _decodeLayer(Object? value, int index) {
  final path =
      r'$.layers'
      '[$index]';
  final layer = _object(value, path: path);
  _allowedFields(layer, const {'id', 'label', 'zIndex'}, path: path);
  try {
    return PresentationLayer(
      id: _string(layer['id'], path: '$path.id'),
      label: _string(layer['label'], path: '$path.label'),
      zIndex: _integer(layer['zIndex'], path: '$path.zIndex'),
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: path);
  }
}

List<PresentationTrack> _decodeTracks(Object? value) {
  final tracks = _list(value, path: r'$.tracks');
  return List<PresentationTrack>.unmodifiable([
    for (var index = 0; index < tracks.length; index += 1)
      _decodeTrack(tracks[index], index),
  ]);
}

PresentationTrack _decodeTrack(Object? value, int trackIndex) {
  final path =
      r'$.tracks'
      '[$trackIndex]';
  final track = _object(value, path: path);
  _allowedFields(track, const {'id', 'label', 'kind', 'clips'}, path: path);
  final kind = _enumValue(
    PresentationTrackKind.values,
    track['kind'],
    path: '$path.kind',
  );
  final rawClips = _list(track['clips'], path: '$path.clips');
  final clips = <PresentationClip>[
    for (var clipIndex = 0; clipIndex < rawClips.length; clipIndex += 1)
      _decodeClip(rawClips[clipIndex], trackIndex, clipIndex),
  ];
  for (var clipIndex = 0; clipIndex < clips.length; clipIndex += 1) {
    if (clips[clipIndex].trackKind != kind) {
      throw PresentationCinematicCodecException(
        code: PresentationCinematicCodecErrorCode.incompatibleTrack,
        message: 'Clip ${clips[clipIndex].id} cannot belong to ${kind.name}',
        path: '$path.clips[$clipIndex].kind',
      );
    }
  }
  try {
    return PresentationTrack(
      id: _string(track['id'], path: '$path.id'),
      label: _string(track['label'], path: '$path.label'),
      kind: kind,
      clips: clips,
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: '$path.clips');
  }
}

PresentationClip _decodeClip(Object? value, int trackIndex, int clipIndex) {
  final path =
      r'$.tracks'
      '[$trackIndex].clips[$clipIndex]';
  final clip = _object(value, path: path);
  final kind = _enumValue(
    PresentationTrackKind.values,
    clip['kind'],
    path: '$path.kind',
  );

  return switch (kind) {
    PresentationTrackKind.visual => _decodeVisualClip(clip, path),
    PresentationTrackKind.audio => _decodeAudioClip(clip, path),
    PresentationTrackKind.caption => _decodeCaptionClip(clip, path),
    PresentationTrackKind.marker => _decodeMarkerClip(clip, path),
  };
}

PresentationVisualClip _decodeVisualClip(
  Map<String, Object?> clip,
  String path,
) {
  _allowedFields(clip, const {
    'id',
    'kind',
    'startUs',
    'durationUs',
    'layerId',
    'resourceId',
    'easing',
    'from',
    'to',
    'transitionIn',
    'transitionOut',
  }, path: path);
  try {
    return PresentationVisualClip(
      id: _string(clip['id'], path: '$path.id'),
      startUs: _integer(clip['startUs'], path: '$path.startUs'),
      durationUs: _integer(clip['durationUs'], path: '$path.durationUs'),
      layerId: _string(clip['layerId'], path: '$path.layerId'),
      resourceId: _string(clip['resourceId'], path: '$path.resourceId'),
      easing: _enumValue(
        PresentationEasing.values,
        clip['easing'] ?? PresentationEasing.linear.name,
        path: '$path.easing',
      ),
      from: clip['from'] == null
          ? null
          : _decodeVisualComposition(clip['from'], '$path.from'),
      to: clip['to'] == null
          ? null
          : _decodeVisualComposition(clip['to'], '$path.to'),
      transitionIn: clip['transitionIn'] == null
          ? null
          : _decodeVisualTransition(clip['transitionIn'], '$path.transitionIn'),
      transitionOut: clip['transitionOut'] == null
          ? null
          : _decodeVisualTransition(
              clip['transitionOut'],
              '$path.transitionOut',
            ),
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: path);
  }
}

PresentationVisualComposition _decodeVisualComposition(
  Object? value,
  String path,
) {
  final composition = _object(value, path: path);
  _allowedFields(composition, const {
    'translateX',
    'translateY',
    'scaleX',
    'scaleY',
    'rotationTurns',
    'opacity',
    'cropLeft',
    'cropTop',
    'cropRight',
    'cropBottom',
  }, path: path);
  return PresentationVisualComposition(
    translateX: _number(
      composition['translateX'] ?? 0,
      path: '$path.translateX',
    ),
    translateY: _number(
      composition['translateY'] ?? 0,
      path: '$path.translateY',
    ),
    scaleX: _number(composition['scaleX'] ?? 1, path: '$path.scaleX'),
    scaleY: _number(composition['scaleY'] ?? 1, path: '$path.scaleY'),
    rotationTurns: _number(
      composition['rotationTurns'] ?? 0,
      path: '$path.rotationTurns',
    ),
    opacity: _number(composition['opacity'] ?? 1, path: '$path.opacity'),
    cropLeft: _number(composition['cropLeft'] ?? 0, path: '$path.cropLeft'),
    cropTop: _number(composition['cropTop'] ?? 0, path: '$path.cropTop'),
    cropRight: _number(composition['cropRight'] ?? 0, path: '$path.cropRight'),
    cropBottom: _number(
      composition['cropBottom'] ?? 0,
      path: '$path.cropBottom',
    ),
  );
}

PresentationVisualTransition _decodeVisualTransition(
  Object? value,
  String path,
) {
  final transition = _object(value, path: path);
  _allowedFields(transition, const {'kind', 'durationUs'}, path: path);
  return PresentationVisualTransition(
    kind: _enumValue(
      PresentationVisualTransitionKind.values,
      transition['kind'],
      path: '$path.kind',
    ),
    durationUs: _integer(transition['durationUs'], path: '$path.durationUs'),
  );
}

PresentationAudioClip _decodeAudioClip(Map<String, Object?> clip, String path) {
  _allowedFields(clip, const {
    'id',
    'kind',
    'startUs',
    'durationUs',
    'resourceId',
  }, path: path);
  try {
    return PresentationAudioClip(
      id: _string(clip['id'], path: '$path.id'),
      startUs: _integer(clip['startUs'], path: '$path.startUs'),
      durationUs: _integer(clip['durationUs'], path: '$path.durationUs'),
      resourceId: _string(clip['resourceId'], path: '$path.resourceId'),
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: path);
  }
}

PresentationCaptionClip _decodeCaptionClip(
  Map<String, Object?> clip,
  String path,
) {
  _allowedFields(clip, const {
    'id',
    'kind',
    'startUs',
    'durationUs',
    'captionId',
  }, path: path);
  try {
    return PresentationCaptionClip(
      id: _string(clip['id'], path: '$path.id'),
      startUs: _integer(clip['startUs'], path: '$path.startUs'),
      durationUs: _integer(clip['durationUs'], path: '$path.durationUs'),
      captionId: _string(clip['captionId'], path: '$path.captionId'),
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: path);
  }
}

PresentationMarkerClip _decodeMarkerClip(
  Map<String, Object?> clip,
  String path,
) {
  _allowedFields(clip, const {
    'id',
    'kind',
    'startUs',
    'durationUs',
    'label',
    'markerKind',
  }, path: path);
  final durationUs = _integer(clip['durationUs'], path: '$path.durationUs');
  if (durationUs != 0) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Marker durationUs must be zero',
      path: '$path.durationUs',
    );
  }
  try {
    return PresentationMarkerClip(
      id: _string(clip['id'], path: '$path.id'),
      startUs: _integer(clip['startUs'], path: '$path.startUs'),
      label: _string(clip['label'], path: '$path.label'),
      markerKind: _enumValue(
        PresentationMarkerKind.values,
        clip['markerKind'] ?? PresentationMarkerKind.ordinary.name,
        path: '$path.markerKind',
      ),
    );
  } on PresentationCinematicValidationException catch (error) {
    throw _validationError(error, fallbackPath: path);
  }
}

Map<String, Object?> _encodeLayer(PresentationLayer layer) => {
  'id': layer.id,
  'label': layer.label,
  'zIndex': layer.zIndex,
};

Map<String, Object?> _encodeTrack(PresentationTrack track) => {
  'id': track.id,
  'label': track.label,
  'kind': track.kind.name,
  'clips': [for (final clip in track.clips) _encodeClip(clip)],
};

Map<String, Object?> _encodeClip(PresentationClip clip) {
  return switch (clip) {
    PresentationVisualClip() => {
      'id': clip.id,
      'kind': clip.trackKind.name,
      'startUs': clip.startUs,
      'durationUs': clip.durationUs,
      'layerId': clip.layerId,
      'resourceId': clip.resourceId,
      'easing': clip.easing.name,
      if (clip.from != PresentationVisualComposition.identity)
        'from': _encodeVisualComposition(clip.from),
      if (clip.to != PresentationVisualComposition.identity)
        'to': _encodeVisualComposition(clip.to),
      if (clip.transitionIn != PresentationVisualTransition.none)
        'transitionIn': _encodeVisualTransition(clip.transitionIn),
      if (clip.transitionOut != PresentationVisualTransition.none)
        'transitionOut': _encodeVisualTransition(clip.transitionOut),
    },
    PresentationAudioClip() => {
      'id': clip.id,
      'kind': clip.trackKind.name,
      'startUs': clip.startUs,
      'durationUs': clip.durationUs,
      'resourceId': clip.resourceId,
    },
    PresentationCaptionClip() => {
      'id': clip.id,
      'kind': clip.trackKind.name,
      'startUs': clip.startUs,
      'durationUs': clip.durationUs,
      'captionId': clip.captionId,
    },
    PresentationMarkerClip() => {
      'id': clip.id,
      'kind': clip.trackKind.name,
      'startUs': clip.startUs,
      'durationUs': 0,
      'label': clip.label,
      'markerKind': clip.markerKind.name,
    },
  };
}

Map<String, Object?> _encodeVisualComposition(
  PresentationVisualComposition composition,
) => {
  'translateX': composition.translateX,
  'translateY': composition.translateY,
  'scaleX': composition.scaleX,
  'scaleY': composition.scaleY,
  'rotationTurns': composition.rotationTurns,
  'opacity': composition.opacity,
  'cropLeft': composition.cropLeft,
  'cropTop': composition.cropTop,
  'cropRight': composition.cropRight,
  'cropBottom': composition.cropBottom,
};

Map<String, Object?> _encodeVisualTransition(
  PresentationVisualTransition transition,
) => {'kind': transition.kind.name, 'durationUs': transition.durationUs};

PresentationCinematicCodecException _validationError(
  PresentationCinematicValidationException error, {
  required String fallbackPath,
}) {
  final path = error.path.startsWith(r'$.') ? error.path : fallbackPath;
  return PresentationCinematicCodecException(
    code: switch (error.code) {
      PresentationCinematicValidationErrorCode.invalidValue =>
        PresentationCinematicCodecErrorCode.invalidValue,
      PresentationCinematicValidationErrorCode.duplicateId =>
        PresentationCinematicCodecErrorCode.duplicateId,
      PresentationCinematicValidationErrorCode.danglingLayer =>
        PresentationCinematicCodecErrorCode.danglingReference,
      PresentationCinematicValidationErrorCode.incompatibleTrack =>
        PresentationCinematicCodecErrorCode.incompatibleTrack,
      PresentationCinematicValidationErrorCode.outOfBounds =>
        PresentationCinematicCodecErrorCode.outOfBounds,
    },
    message: error.message,
    path: path,
  );
}

Map<String, Object?> _object(
  Object? value, {
  required String path,
  bool root = false,
}) {
  if (value is! Map) {
    throw PresentationCinematicCodecException(
      code: root
          ? PresentationCinematicCodecErrorCode.invalidRoot
          : PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Expected an object',
      path: path,
    );
  }
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) {
      throw PresentationCinematicCodecException(
        code: PresentationCinematicCodecErrorCode.invalidValue,
        message: 'Object keys must be strings',
        path: path,
      );
    }
    result[entry.key as String] = entry.value;
  }
  return result;
}

List<Object?> _list(Object? value, {required String path}) {
  if (value is! List) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Expected a list',
      path: path,
    );
  }
  return List<Object?>.of(value);
}

String _string(Object? value, {required String path}) {
  if (value is! String || value.trim().isEmpty) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Expected a non-empty string',
      path: path,
    );
  }
  return value.trim();
}

String? _optionalString(Object? value, {required String path}) {
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Expected a string',
      path: path,
    );
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

int _integer(Object? value, {required String path}) {
  if (value is! int) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Expected an integer',
      path: path,
    );
  }
  return value;
}

double _number(Object? value, {required String path}) {
  if (value is! num) {
    throw PresentationCinematicCodecException(
      code: PresentationCinematicCodecErrorCode.invalidValue,
      message: 'Expected a number',
      path: path,
    );
  }
  return value.toDouble();
}

T _enumValue<T extends Enum>(
  List<T> values,
  Object? value, {
  required String path,
}) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  throw PresentationCinematicCodecException(
    code: PresentationCinematicCodecErrorCode.unsupportedKind,
    message: 'Unsupported value: $value',
    path: path,
  );
}

void _allowedFields(
  Map<String, Object?> value,
  Set<String> fields, {
  required String path,
}) {
  for (final key in value.keys) {
    if (!fields.contains(key)) {
      throw PresentationCinematicCodecException(
        code: PresentationCinematicCodecErrorCode.unexpectedField,
        message: 'Unexpected field: $key',
        path: '$path.$key',
      );
    }
  }
}
