import 'package:map_core/map_core.dart';

final class EditorPlacedElementCellViewport {
  const EditorPlacedElementCellViewport({
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

final class EditorPlacedElementViewportIndexOwner {
  MapData? _map;
  ProjectManifest? _manifest;
  EditorPlacedElementViewportIndex? _index;

  EditorPlacedElementViewportIndex indexFor({
    required ProjectManifest manifest,
    required MapData map,
  }) {
    final cached = _index;
    if (cached != null &&
        identical(_map, map) &&
        identical(_manifest, manifest)) {
      return cached;
    }
    final next = EditorPlacedElementViewportIndex(manifest: manifest, map: map);
    _map = map;
    _manifest = manifest;
    _index = next;
    return next;
  }

  void clear() {
    _map = null;
    _manifest = null;
    _index = null;
  }
}

final class EditorPlacedElementViewportIndex {
  EditorPlacedElementViewportIndex({
    required ProjectManifest manifest,
    required MapData map,
  }) : _elements = List<MapPlacedElement>.unmodifiable(map.placedElements) {
    _elementIndicesByCell = _indexPlacedElements(
      manifest: manifest,
      map: map,
      globalBounds: _globalBounds,
    );
  }

  final List<MapPlacedElement> _elements;
  late final Map<(int, int), List<int>> _elementIndicesByCell;
  final Map<int, EditorPlacedElementCellViewport> _globalBounds = {};

  int get debugIndexedCellCount => _elementIndicesByCell.length;

  int get debugGlobalCandidateCount => _globalBounds.length;

  List<MapPlacedElement> elementsIn(EditorPlacedElementCellViewport viewport) {
    if (viewport.isEmpty || _elements.isEmpty) {
      return const <MapPlacedElement>[];
    }
    final candidateIndices = <int>{
      for (final entry in _globalBounds.entries)
        if (entry.value.left < viewport.right &&
            entry.value.right > viewport.left &&
            entry.value.top < viewport.bottom &&
            entry.value.bottom > viewport.top)
          entry.key,
    };
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

Map<(int, int), List<int>> _indexPlacedElements({
  required ProjectManifest manifest,
  required MapData map,
  required Map<int, EditorPlacedElementCellViewport> globalBounds,
}) {
  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final tilesetSources = {
    for (final tileset in manifest.tilesets) tileset.id: tileset.source,
  };
  final result = <(int, int), List<int>>{};
  for (var index = 0; index < map.placedElements.length; index += 1) {
    final instance = map.placedElements[index];
    final element = elementById[instance.elementId];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final bounds = resolveMapPlacedElementVisualBounds(
      instance: instance,
      element: element,
      manifest: manifest,
      tilesetSources: tilesetSources,
    );
    final startX = (bounds.leftPx / manifest.settings.tileWidth).floor();
    final endX =
        ((bounds.leftPx + bounds.widthPx) / manifest.settings.tileWidth).ceil();
    final startY = (bounds.topPx / manifest.settings.tileHeight).floor();
    final endY =
        ((bounds.topPx + bounds.heightPx) / manifest.settings.tileHeight)
            .ceil();
    if (endX <= startX || endY <= startY) continue;
    if (endX - startX > 256 ~/ (endY - startY)) {
      globalBounds[index] = EditorPlacedElementCellViewport(
        left: startX,
        top: startY,
        right: endX,
        bottom: endY,
      );
      continue;
    }
    for (var y = startY; y < endY; y++) {
      for (var x = startX; x < endX; x++) {
        result.putIfAbsent((x, y), () => <int>[]).add(index);
      }
    }
  }
  return result;
}
