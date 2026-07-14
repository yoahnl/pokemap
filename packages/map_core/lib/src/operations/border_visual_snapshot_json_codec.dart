import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/geometry.dart';
import 'border_json_codec_helpers.dart';
import 'border_rle_codec.dart';

/// Effective duration used when a legacy/imported frame omits its duration.
const int defaultBorderVisualFrameDurationMs = 100;

final RegExp _lowercaseSha256Pattern = RegExp(r'^[0-9a-f]{64}$');

const Set<String> _metricsKeys = <String>{
  'assetFingerprint',
  'pixelSize',
  'opaqueBounds',
  'defaultAnchorPx',
  'occupancyMaskRle',
};
const Set<String> _sizeKeys = <String>{'width', 'height'};
const Set<String> _rectKeys = <String>{'x', 'y', 'width', 'height'};
const Set<String> _posKeys = <String>{'x', 'y'};
const Set<String> _snapshotKeys = <String>{
  'id',
  'contentFingerprint',
  'frames',
};
const Set<String> _frameRequiredKeys = <String>{
  'relativeAssetPath',
  'sourceRectPx',
};
const Set<String> _frameOptionalKeys = <String>{
  'durationMs',
  'transparentColorArgb',
};

/// Encodes [metrics] using the strict Border V1 primitive-metrics shape.
///
/// The occupancy RLE is validated without allocating its decoded mask.
Map<String, Object?> encodeBorderPrimitiveAssetMetricsJson(
  BorderPrimitiveAssetMetrics metrics, {
  String path = r'$',
}) {
  final assetFingerprintPath = borderJsonPropertyPath(path, 'assetFingerprint');
  _requireNonEmpty(metrics.assetFingerprint, assetFingerprintPath);

  final pixelSizePath = borderJsonPropertyPath(path, 'pixelSize');
  final expectedLength = checkedBorderRleCellCount(
    width: metrics.pixelSize.width,
    height: metrics.pixelSize.height,
    path: pixelSizePath,
  );

  final opaqueBoundsPath = borderJsonPropertyPath(path, 'opaqueBounds');
  _validateRect(
    metrics.opaqueBounds,
    path: opaqueBoundsPath,
    allowNegativeOrigin: false,
  );
  _validateOpaqueBoundsFit(
    metrics.opaqueBounds,
    metrics.pixelSize,
    opaqueBoundsPath,
  );

  final occupancyPath = borderJsonPropertyPath(path, 'occupancyMaskRle');
  validateBorderRleMask(
    metrics.occupancyMaskRle,
    expectedLength: expectedLength,
    path: occupancyPath,
  );

  return <String, Object?>{
    'assetFingerprint': metrics.assetFingerprint,
    'pixelSize': _encodeSize(metrics.pixelSize),
    'opaqueBounds': _encodeRect(metrics.opaqueBounds),
    'defaultAnchorPx': _encodePos(metrics.defaultAnchorPx),
    'occupancyMaskRle': metrics.occupancyMaskRle,
  };
}

/// Decodes the strict Border V1 primitive-metrics shape.
BorderPrimitiveAssetMetrics decodeBorderPrimitiveAssetMetricsJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _metricsKeys,
  );

  final assetFingerprintPath = borderJsonPropertyPath(path, 'assetFingerprint');
  final assetFingerprint = borderJsonRequireString(
    borderJsonRequireField(value, 'assetFingerprint', path),
    assetFingerprintPath,
  );
  _requireNonEmpty(assetFingerprint, assetFingerprintPath);

  final pixelSizePath = borderJsonPropertyPath(path, 'pixelSize');
  final pixelSize = _decodeSize(
    borderJsonRequireField(value, 'pixelSize', path),
    pixelSizePath,
  );
  final expectedLength = checkedBorderRleCellCount(
    width: pixelSize.width,
    height: pixelSize.height,
    path: pixelSizePath,
  );

  final opaqueBoundsPath = borderJsonPropertyPath(path, 'opaqueBounds');
  final opaqueBounds = _decodeRect(
    borderJsonRequireField(value, 'opaqueBounds', path),
    opaqueBoundsPath,
    allowNegativeOrigin: false,
  );
  _validateOpaqueBoundsFit(opaqueBounds, pixelSize, opaqueBoundsPath);

  final anchorPath = borderJsonPropertyPath(path, 'defaultAnchorPx');
  final defaultAnchorPx = _decodePos(
    borderJsonRequireField(value, 'defaultAnchorPx', path),
    anchorPath,
  );

  final occupancyPath = borderJsonPropertyPath(path, 'occupancyMaskRle');
  final occupancyMaskRle = borderJsonRequireString(
    borderJsonRequireField(value, 'occupancyMaskRle', path),
    occupancyPath,
  );
  validateBorderRleMask(
    occupancyMaskRle,
    expectedLength: expectedLength,
    path: occupancyPath,
  );

  return borderJsonConstructAtPath(
    path,
    () => BorderPrimitiveAssetMetrics(
      assetFingerprint: assetFingerprint,
      pixelSize: pixelSize,
      opaqueBounds: opaqueBounds,
      defaultAnchorPx: defaultAnchorPx,
      occupancyMaskRle: occupancyMaskRle,
    ),
  );
}

/// Encodes [snapshot] while preserving frame order and duplicate frames.
Map<String, Object?> encodeBorderVisualSnapshotJson(
  BorderVisualSnapshot snapshot, {
  String path = r'$',
}) {
  final contentFingerprintPath =
      borderJsonPropertyPath(path, 'contentFingerprint');
  _validateContentFingerprint(
    snapshot.contentFingerprint,
    contentFingerprintPath,
  );
  _validateSnapshotId(
    snapshot.id,
    snapshot.contentFingerprint,
    borderJsonPropertyPath(path, 'id'),
  );

  final framesPath = borderJsonPropertyPath(path, 'frames');
  if (snapshot.frames.isEmpty) {
    throw FormatException('$framesPath: must be non-empty');
  }

  final encodedFrames = <Object?>[];
  final expectedWidth = snapshot.frames.first.sourceRectPx.width;
  final expectedHeight = snapshot.frames.first.sourceRectPx.height;
  for (var index = 0; index < snapshot.frames.length; index += 1) {
    final frame = snapshot.frames[index];
    final framePath = borderJsonIndexPath(framesPath, index);
    if (frame.sourceRectPx.width != expectedWidth ||
        frame.sourceRectPx.height != expectedHeight) {
      throw FormatException(
        '${borderJsonPropertyPath(framePath, 'sourceRectPx')}: '
        'all frames must share source dimensions',
      );
    }
    encodedFrames.add(_encodeFrame(frame, framePath));
  }

  return <String, Object?>{
    'id': snapshot.id,
    'contentFingerprint': snapshot.contentFingerprint,
    'frames': encodedFrames,
  };
}

/// Decodes the strict Border V1 visual-snapshot shape.
///
/// An absent frame duration is normalized to
/// [defaultBorderVisualFrameDurationMs]. A present duration remains strict:
/// `null`, non-integers, and non-positive integers are rejected.
BorderVisualSnapshot decodeBorderVisualSnapshotJson(
  Object? json, {
  String path = r'$',
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _snapshotKeys,
  );

  final idPath = borderJsonPropertyPath(path, 'id');
  final id = borderJsonRequireString(
    borderJsonRequireField(value, 'id', path),
    idPath,
  );
  final contentFingerprintPath =
      borderJsonPropertyPath(path, 'contentFingerprint');
  final contentFingerprint = borderJsonRequireString(
    borderJsonRequireField(value, 'contentFingerprint', path),
    contentFingerprintPath,
  );
  _validateContentFingerprint(contentFingerprint, contentFingerprintPath);
  _validateSnapshotId(id, contentFingerprint, idPath);

  final framesPath = borderJsonPropertyPath(path, 'frames');
  final frameValues = borderJsonRequireList(
    borderJsonRequireField(value, 'frames', path),
    framesPath,
  );
  if (frameValues.isEmpty) {
    throw FormatException('$framesPath: must be non-empty');
  }

  final frames = <BorderVisualFrameSnapshot>[];
  int? expectedWidth;
  int? expectedHeight;
  for (var index = 0; index < frameValues.length; index += 1) {
    final framePath = borderJsonIndexPath(framesPath, index);
    final frame = _decodeFrame(frameValues[index], framePath);
    expectedWidth ??= frame.sourceRectPx.width;
    expectedHeight ??= frame.sourceRectPx.height;
    if (frame.sourceRectPx.width != expectedWidth ||
        frame.sourceRectPx.height != expectedHeight) {
      throw FormatException(
        '${borderJsonPropertyPath(framePath, 'sourceRectPx')}: '
        'all frames must share source dimensions',
      );
    }
    frames.add(frame);
  }

  return borderJsonConstructAtPath(
    path,
    () => BorderVisualSnapshot(
      id: id,
      contentFingerprint: contentFingerprint,
      frames: frames,
    ),
  );
}

Map<String, Object?> _encodeFrame(
  BorderVisualFrameSnapshot frame,
  String path,
) {
  final relativeAssetPathPath =
      borderJsonPropertyPath(path, 'relativeAssetPath');
  _validateSnapshotPath(frame.relativeAssetPath, relativeAssetPathPath);

  final sourceRectPath = borderJsonPropertyPath(path, 'sourceRectPx');
  _validateRect(
    frame.sourceRectPx,
    path: sourceRectPath,
    allowNegativeOrigin: false,
  );

  final durationPath = borderJsonPropertyPath(path, 'durationMs');
  if (frame.durationMs <= 0) {
    throw FormatException('$durationPath: must be > 0');
  }

  final transparentColor = frame.transparentColorArgb;
  if (transparentColor != null) {
    _validateArgb(
      transparentColor,
      borderJsonPropertyPath(path, 'transparentColorArgb'),
    );
  }

  return <String, Object?>{
    'relativeAssetPath': frame.relativeAssetPath,
    'sourceRectPx': _encodeRect(frame.sourceRectPx),
    'durationMs': frame.durationMs,
    if (transparentColor != null) 'transparentColorArgb': transparentColor,
  };
}

BorderVisualFrameSnapshot _decodeFrame(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _frameRequiredKeys,
    optionalKeys: _frameOptionalKeys,
  );

  final relativeAssetPathPath =
      borderJsonPropertyPath(path, 'relativeAssetPath');
  final relativeAssetPath = borderJsonRequireString(
    borderJsonRequireField(value, 'relativeAssetPath', path),
    relativeAssetPathPath,
  );
  _validateSnapshotPath(relativeAssetPath, relativeAssetPathPath);

  final sourceRectPath = borderJsonPropertyPath(path, 'sourceRectPx');
  final sourceRectPx = _decodeRect(
    borderJsonRequireField(value, 'sourceRectPx', path),
    sourceRectPath,
    allowNegativeOrigin: false,
  );

  final durationPath = borderJsonPropertyPath(path, 'durationMs');
  final durationMs = value.containsKey('durationMs')
      ? borderJsonRequireInt(value['durationMs'], durationPath)
      : defaultBorderVisualFrameDurationMs;
  if (durationMs <= 0) {
    throw FormatException('$durationPath: must be > 0');
  }

  int? transparentColorArgb;
  if (value.containsKey('transparentColorArgb')) {
    final transparentColorPath =
        borderJsonPropertyPath(path, 'transparentColorArgb');
    transparentColorArgb = borderJsonRequireInt(
      value['transparentColorArgb'],
      transparentColorPath,
    );
    _validateArgb(transparentColorArgb, transparentColorPath);
  }

  return borderJsonConstructAtPath(
    path,
    () => BorderVisualFrameSnapshot(
      relativeAssetPath: relativeAssetPath,
      sourceRectPx: sourceRectPx,
      durationMs: durationMs,
      transparentColorArgb: transparentColorArgb,
    ),
  );
}

GridSize _decodeSize(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _sizeKeys,
  );
  final width = borderJsonRequireInt(
    borderJsonRequireField(value, 'width', path),
    borderJsonPropertyPath(path, 'width'),
  );
  final height = borderJsonRequireInt(
    borderJsonRequireField(value, 'height', path),
    borderJsonPropertyPath(path, 'height'),
  );
  checkedBorderRleCellCount(width: width, height: height, path: path);
  return GridSize(width: width, height: height);
}

BorderPixelPos _decodePos(Object? json, String path) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _posKeys,
  );
  return BorderPixelPos(
    x: borderJsonRequireInt(
      borderJsonRequireField(value, 'x', path),
      borderJsonPropertyPath(path, 'x'),
    ),
    y: borderJsonRequireInt(
      borderJsonRequireField(value, 'y', path),
      borderJsonPropertyPath(path, 'y'),
    ),
  );
}

BorderPixelRect _decodeRect(
  Object? json,
  String path, {
  required bool allowNegativeOrigin,
}) {
  final value = borderJsonRequireObject(json, path);
  borderJsonRequireExactKeys(
    value,
    path: path,
    requiredKeys: _rectKeys,
  );
  final xPath = borderJsonPropertyPath(path, 'x');
  final yPath = borderJsonPropertyPath(path, 'y');
  final widthPath = borderJsonPropertyPath(path, 'width');
  final heightPath = borderJsonPropertyPath(path, 'height');
  final x = borderJsonRequireInt(
    borderJsonRequireField(value, 'x', path),
    xPath,
  );
  final y = borderJsonRequireInt(
    borderJsonRequireField(value, 'y', path),
    yPath,
  );
  final width = borderJsonRequireInt(
    borderJsonRequireField(value, 'width', path),
    widthPath,
  );
  final height = borderJsonRequireInt(
    borderJsonRequireField(value, 'height', path),
    heightPath,
  );
  if (!allowNegativeOrigin && x < 0) {
    throw FormatException('$xPath: must be >= 0');
  }
  if (!allowNegativeOrigin && y < 0) {
    throw FormatException('$yPath: must be >= 0');
  }
  if (width <= 0) {
    throw FormatException('$widthPath: must be > 0');
  }
  if (height <= 0) {
    throw FormatException('$heightPath: must be > 0');
  }
  return borderJsonConstructAtPath(
    path,
    () => BorderPixelRect(x: x, y: y, width: width, height: height),
  );
}

void _validateRect(
  BorderPixelRect rect, {
  required String path,
  required bool allowNegativeOrigin,
}) {
  if (!allowNegativeOrigin && rect.x < 0) {
    throw FormatException('${borderJsonPropertyPath(path, 'x')}: must be >= 0');
  }
  if (!allowNegativeOrigin && rect.y < 0) {
    throw FormatException('${borderJsonPropertyPath(path, 'y')}: must be >= 0');
  }
  if (rect.width <= 0) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'width')}: must be > 0',
    );
  }
  if (rect.height <= 0) {
    throw FormatException(
      '${borderJsonPropertyPath(path, 'height')}: must be > 0',
    );
  }
}

void _validateOpaqueBoundsFit(
  BorderPixelRect bounds,
  GridSize pixelSize,
  String path,
) {
  if (bounds.right > pixelSize.width || bounds.bottom > pixelSize.height) {
    throw FormatException('$path: must fit pixelSize');
  }
}

void _validateContentFingerprint(String value, String path) {
  if (!_lowercaseSha256Pattern.hasMatch(value)) {
    throw FormatException(
      '$path: must contain exactly 64 lowercase hexadecimal characters',
    );
  }
}

void _validateSnapshotId(String id, String contentFingerprint, String path) {
  if (id != 'border-snapshot-sha256:$contentFingerprint') {
    throw FormatException('$path: must match contentFingerprint');
  }
}

void _validateArgb(int value, String path) {
  if (value < 0 || value > 0xffffffff) {
    throw FormatException('$path: must be a 32-bit ARGB integer');
  }
}

void _requireNonEmpty(String value, String path) {
  if (value.isEmpty) {
    throw FormatException('$path: must be non-empty');
  }
}

void _validateSnapshotPath(String value, String path) {
  if (value.isEmpty ||
      !value.startsWith('assets/borders/snapshots/') ||
      value.startsWith('/') ||
      value.contains(r'\') ||
      value.contains(':')) {
    throw FormatException('$path: must be a safe project-relative path');
  }
  for (final codeUnit in value.codeUnits) {
    if (codeUnit < 0x20) {
      throw FormatException('$path: must be a safe project-relative path');
    }
  }
  final segments = value.split('/');
  if (segments.any(
    (segment) => segment.isEmpty || segment == '.' || segment == '..',
  )) {
    throw FormatException('$path: must be a safe project-relative path');
  }
}

Map<String, Object?> _encodeSize(GridSize size) => <String, Object?>{
      'width': size.width,
      'height': size.height,
    };

Map<String, Object?> _encodePos(BorderPixelPos pos) => <String, Object?>{
      'x': pos.x,
      'y': pos.y,
    };

Map<String, Object?> _encodeRect(BorderPixelRect rect) => <String, Object?>{
      'x': rect.x,
      'y': rect.y,
      'width': rect.width,
      'height': rect.height,
    };
