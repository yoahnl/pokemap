import 'package:map_core/map_core.dart';

import 'editor_projected_building_shadow_preview.dart';
import 'editor_shadow_light_preview.dart';
import 'editor_static_shadow_preview.dart';

final class EditorShadowPreviewCellViewport {
  const EditorShadowPreviewCellViewport({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  final int left;
  final int top;
  final int right;
  final int bottom;

  bool get isEmpty => right <= left || bottom <= top;
}

/// Cached shadow projection for one immutable map/project revision.
///
/// Geometry is resolved once, then exact instruction bounds are indexed in
/// tile-sized buckets. Repaints caused by pan, zoom, overlays, or animation
/// only enumerate buckets intersecting the visible world rectangle.
final class EditorShadowPreviewProjection {
  EditorShadowPreviewProjection._({
    required ProjectManifest manifest,
    required MapData map,
    required List<EditorStaticShadowPreviewInstruction> staticInstructions,
    required List<EditorStaticShadowPreviewInstruction>
        projectedBuildingInstructions,
    required double bucketWidth,
    required double bucketHeight,
  })  : _placedElementIndex = _EditorPlacedElementViewportIndex(
          manifest: manifest,
          map: map,
        ),
        _staticIndex = _EditorShadowPreviewInstructionIndex(
          instructions: staticInstructions,
          bucketWidth: bucketWidth,
          bucketHeight: bucketHeight,
        ),
        _projectedBuildingIndex = _EditorShadowPreviewInstructionIndex(
          instructions: projectedBuildingInstructions,
          bucketWidth: bucketWidth,
          bucketHeight: bucketHeight,
        );

  final _EditorPlacedElementViewportIndex _placedElementIndex;
  final _EditorShadowPreviewInstructionIndex _staticIndex;
  final _EditorShadowPreviewInstructionIndex _projectedBuildingIndex;

  int get staticInstructionCount => _staticIndex.length;

  int get projectedBuildingInstructionCount => _projectedBuildingIndex.length;

  List<MapPlacedElement> placedElementsIn(
    EditorShadowPreviewCellViewport viewport,
  ) =>
      _placedElementIndex.elementsIn(viewport);

  List<EditorStaticShadowPreviewInstruction> staticInstructionsIn(
    EditorShadowPreviewViewport viewport,
  ) =>
      _staticIndex.instructionsIn(viewport);

  List<EditorStaticShadowPreviewInstruction> projectedBuildingInstructionsIn(
    EditorShadowPreviewViewport viewport,
  ) =>
      _projectedBuildingIndex.instructionsIn(viewport);
}

/// Retains the projection index while map and project value identities stay
/// unchanged. PokeMap editor state replaces immutable values on semantic edits,
/// so identity is the narrow invalidation boundary needed here.
final class EditorShadowPreviewProjectionOwner {
  MapData? _map;
  ProjectManifest? _manifest;
  double? _tileWidth;
  double? _tileHeight;
  EditorShadowLightPreviewPreset? _lightPreviewPreset;
  EditorShadowPreviewProjection? _projection;

  EditorShadowPreviewProjection projectionFor({
    required ProjectManifest manifest,
    required MapData map,
    required double tileWidth,
    required double tileHeight,
    EditorShadowLightPreviewPreset? lightPreviewPreset,
  }) {
    final resolvedLightPreviewPreset =
        lightPreviewPreset ?? neutralEditorShadowLightPreviewPreset;
    final cached = _projection;
    if (cached != null &&
        identical(_map, map) &&
        identical(_manifest, manifest) &&
        _tileWidth == tileWidth &&
        _tileHeight == tileHeight &&
        _lightPreviewPreset == resolvedLightPreviewPreset) {
      return cached;
    }

    final next = EditorShadowPreviewProjection._(
      manifest: manifest,
      map: map,
      staticInstructions: buildEditorStaticShadowPreviewInstructions(
        manifest: manifest,
        map: map,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
        lightPreviewPreset: resolvedLightPreviewPreset,
      ),
      projectedBuildingInstructions:
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: manifest,
        map: map,
        tileWidth: tileWidth,
        tileHeight: tileHeight,
      ),
      bucketWidth: tileWidth,
      bucketHeight: tileHeight,
    );
    _map = map;
    _manifest = manifest;
    _tileWidth = tileWidth;
    _tileHeight = tileHeight;
    _lightPreviewPreset = resolvedLightPreviewPreset;
    _projection = next;
    return next;
  }

  void clear() {
    _map = null;
    _manifest = null;
    _tileWidth = null;
    _tileHeight = null;
    _lightPreviewPreset = null;
    _projection = null;
  }
}

final class _EditorPlacedElementViewportIndex {
  _EditorPlacedElementViewportIndex({
    required ProjectManifest manifest,
    required MapData map,
  })  : _elements = List<MapPlacedElement>.unmodifiable(map.placedElements),
        _elementIndicesByCell = _indexPlacedElements(
          manifest: manifest,
          map: map,
        );

  final List<MapPlacedElement> _elements;
  final Map<(int, int), List<int>> _elementIndicesByCell;

  List<MapPlacedElement> elementsIn(
    EditorShadowPreviewCellViewport viewport,
  ) {
    if (viewport.isEmpty || _elements.isEmpty) {
      return const <MapPlacedElement>[];
    }
    final candidateIndices = <int>{};
    for (var y = viewport.top; y < viewport.bottom; y += 1) {
      for (var x = viewport.left; x < viewport.right; x += 1) {
        final cell = _elementIndicesByCell[(x, y)];
        if (cell != null) {
          candidateIndices.addAll(cell);
        }
      }
    }
    if (candidateIndices.isEmpty) {
      return const <MapPlacedElement>[];
    }
    final orderedIndices = candidateIndices.toList()..sort();
    return List<MapPlacedElement>.unmodifiable(
      orderedIndices.map((index) => _elements[index]),
    );
  }
}

final class _EditorShadowPreviewInstructionIndex {
  _EditorShadowPreviewInstructionIndex({
    required List<EditorStaticShadowPreviewInstruction> instructions,
    required this.bucketWidth,
    required this.bucketHeight,
  })  : assert(bucketWidth.isFinite && bucketWidth > 0),
        assert(bucketHeight.isFinite && bucketHeight > 0),
        _instructions = List<EditorStaticShadowPreviewInstruction>.unmodifiable(
          instructions,
        ),
        _instructionIndicesByBucket = _indexInstructions(
          instructions: instructions,
          bucketWidth: bucketWidth,
          bucketHeight: bucketHeight,
        );

  final double bucketWidth;
  final double bucketHeight;
  final List<EditorStaticShadowPreviewInstruction> _instructions;
  final Map<(int, int), List<int>> _instructionIndicesByBucket;

  int get length => _instructions.length;

  List<EditorStaticShadowPreviewInstruction> instructionsIn(
    EditorShadowPreviewViewport viewport,
  ) {
    if (viewport.isEmpty || _instructions.isEmpty) {
      return const <EditorStaticShadowPreviewInstruction>[];
    }
    final startX = (viewport.left / bucketWidth).floor();
    final endX = (viewport.right / bucketWidth).ceil();
    final startY = (viewport.top / bucketHeight).floor();
    final endY = (viewport.bottom / bucketHeight).ceil();
    final candidateIndices = <int>{};
    for (var y = startY; y < endY; y += 1) {
      for (var x = startX; x < endX; x += 1) {
        final bucket = _instructionIndicesByBucket[(x, y)];
        if (bucket != null) {
          candidateIndices.addAll(bucket);
        }
      }
    }
    if (candidateIndices.isEmpty) {
      return const <EditorStaticShadowPreviewInstruction>[];
    }
    final orderedIndices = candidateIndices.toList()..sort();
    return List<EditorStaticShadowPreviewInstruction>.unmodifiable(
      orderedIndices
          .map((index) => _instructions[index])
          .where(viewport.intersectsInstruction),
    );
  }
}

Map<(int, int), List<int>> _indexInstructions({
  required List<EditorStaticShadowPreviewInstruction> instructions,
  required double bucketWidth,
  required double bucketHeight,
}) {
  final result = <(int, int), List<int>>{};
  for (var index = 0; index < instructions.length; index += 1) {
    final instruction = instructions[index];
    final startX = (instruction.left / bucketWidth).floor();
    final endX = ((instruction.left + instruction.width) / bucketWidth).ceil();
    final startY = (instruction.top / bucketHeight).floor();
    final endY = ((instruction.top + instruction.height) / bucketHeight).ceil();
    for (var y = startY; y < endY; y += 1) {
      for (var x = startX; x < endX; x += 1) {
        result.putIfAbsent((x, y), () => <int>[]).add(index);
      }
    }
  }
  return result;
}

Map<(int, int), List<int>> _indexPlacedElements({
  required ProjectManifest manifest,
  required MapData map,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final result = <(int, int), List<int>>{};
  for (var index = 0; index < map.placedElements.length; index += 1) {
    final instance = map.placedElements[index];
    final element = elementById[instance.elementId];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final footprint = resolveMapPlacedElementFootprint(
      instance: instance,
      element: element,
    ).destinationSize;
    for (var y = instance.pos.y;
        y < instance.pos.y + footprint.height;
        y += 1) {
      for (var x = instance.pos.x;
          x < instance.pos.x + footprint.width;
          x += 1) {
        result.putIfAbsent((x, y), () => <int>[]).add(index);
      }
    }
  }
  return result;
}
