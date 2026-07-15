import '../models/border_geometry.dart';
import '../models/geometry.dart';
import 'border_stroke_canonicalization.dart';

/// World Maps gesture supported by the V1 linear Border authoring contract.
enum BorderStrokeEditingMode { draw, erase }

/// Immutable line-editing gesture built from the geometry at pointer down.
///
/// Every preview is rebuilt from [baseGeometry]. Sampling a multi-move drag
/// therefore produces one proposed stroke instead of accumulating one stroke
/// per pointer event. The draft itself is editor-transient and is never
/// persisted in a map.
final class BorderStrokeEditingDraft {
  BorderStrokeEditingDraft._({
    required this.baseGeometry,
    required this.mode,
    required List<GridPos> sampledPoints,
    required this.pendingStrokeId,
  }) : _sampledPoints = List<GridPos>.unmodifiable(sampledPoints);

  factory BorderStrokeEditingDraft.begin({
    required BorderStrokeGeometry baseGeometry,
    required BorderStrokeEditingMode mode,
    required GridPos pointerDown,
  }) =>
      BorderStrokeEditingDraft._(
        baseGeometry: baseGeometry,
        mode: mode,
        sampledPoints: <GridPos>[
          GridPos(x: pointerDown.x, y: pointerDown.y),
        ],
        pendingStrokeId: mode == BorderStrokeEditingMode.draw
            ? _firstFreeStrokeId(baseGeometry)
            : null,
      );

  final BorderStrokeGeometry baseGeometry;
  final BorderStrokeEditingMode mode;
  final List<GridPos> _sampledPoints;

  /// ID reserved at pointer down for the one stroke proposed by a draw drag.
  final String? pendingStrokeId;

  List<GridPos> get sampledPoints => _sampledPoints;

  BorderStrokeEditingDraft sample(GridPos point) {
    if (_sampledPoints.last == point) return this;
    return BorderStrokeEditingDraft._(
      baseGeometry: baseGeometry,
      mode: mode,
      sampledPoints: <GridPos>[
        ..._sampledPoints,
        GridPos(x: point.x, y: point.y),
      ],
      pendingStrokeId: pendingStrokeId,
    );
  }

  /// Current immutable proposal, or `null` while a draw has fewer than two
  /// distinct rasterized cells.
  BorderStrokeGeometry? get previewGeometry => switch (mode) {
        BorderStrokeEditingMode.draw => _drawPreview(),
        BorderStrokeEditingMode.erase => _erasePreview(),
      };

  BorderStrokeGeometry? _drawPreview() {
    final rasterized = _rasterizeGesture(_sampledPoints);
    if (rasterized.length < 2) return null;
    final stroke = canonicalizeBorderStrokeV1(
      id: pendingStrokeId!,
      sampledPoints: _sampledPoints,
      closed: false,
    );
    return BorderStrokeGeometry(
      strokes: <BorderStroke>[...baseGeometry.strokes, stroke],
    );
  }

  BorderStrokeGeometry _erasePreview() {
    final erasedCells = _rasterizeGesture(_sampledPoints).toSet();
    final usedIds = <String>{
      for (final stroke in baseGeometry.strokes) stroke.id,
    };
    final output = <BorderStroke>[];
    var changed = false;

    for (final stroke in baseGeometry.strokes) {
      final touched = stroke.points.any(erasedCells.contains);
      if (!touched) {
        output.add(stroke);
        continue;
      }
      changed = true;
      final runs = stroke.closed
          ? _splitTouchedClosedStroke(stroke.points, erasedCells)
          : _splitOpenStroke(stroke.points, erasedCells);
      var retainedFragments = 0;
      for (final run in runs) {
        if (run.length < 2) continue;
        retainedFragments += 1;
        final id = retainedFragments == 1
            ? stroke.id
            : _nextFragmentId(
                stroke.id,
                ordinal: retainedFragments,
                usedIds: usedIds,
              );
        usedIds.add(id);
        output.add(
          canonicalizeBorderStrokeV1(
            id: id,
            sampledPoints: run,
            closed: false,
          ),
        );
      }
    }

    if (!changed) return baseGeometry;
    return BorderStrokeGeometry(strokes: output);
  }
}

String _firstFreeStrokeId(BorderStrokeGeometry geometry) {
  final used = <String>{for (final stroke in geometry.strokes) stroke.id};
  const base = 'stroke';
  if (!used.contains(base)) return base;
  for (var suffix = 2;; suffix += 1) {
    final candidate = '${base}_$suffix';
    if (!used.contains(candidate)) return candidate;
  }
}

String _nextFragmentId(
  String sourceId, {
  required int ordinal,
  required Set<String> usedIds,
}) {
  var suffix = ordinal;
  while (true) {
    final candidate = '${sourceId}__fragment_$suffix';
    if (!usedIds.contains(candidate)) return candidate;
    suffix += 1;
  }
}

List<GridPos> _rasterizeGesture(List<GridPos> samples) {
  final result = <GridPos>[];
  for (var index = 0; index < samples.length; index += 1) {
    if (index == 0) {
      result.add(samples.first);
      continue;
    }
    final pair = rasterizeBorderStrokePairV1(
      samples[index - 1],
      samples[index],
    );
    for (final point in pair) {
      if (result.last != point) result.add(point);
    }
  }
  return result;
}

List<List<GridPos>> _splitOpenStroke(
  List<GridPos> points,
  Set<GridPos> erasedCells,
) {
  final runs = <List<GridPos>>[];
  var current = <GridPos>[];
  for (final point in points) {
    if (erasedCells.contains(point)) {
      if (current.isNotEmpty) runs.add(current);
      current = <GridPos>[];
    } else {
      current.add(point);
    }
  }
  if (current.isNotEmpty) runs.add(current);
  return runs;
}

List<List<GridPos>> _splitTouchedClosedStroke(
  List<GridPos> points,
  Set<GridPos> erasedCells,
) {
  final firstErased = points.indexWhere(erasedCells.contains);
  final runs = <List<GridPos>>[];
  var current = <GridPos>[];
  for (var offset = 1; offset <= points.length; offset += 1) {
    final point = points[(firstErased + offset) % points.length];
    if (erasedCells.contains(point)) {
      if (current.isNotEmpty) runs.add(current);
      current = <GridPos>[];
    } else {
      current.add(point);
    }
  }
  if (current.isNotEmpty) runs.add(current);
  return runs;
}
