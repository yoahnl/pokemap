/// Payload local transmis par le drag & drop Surface Studio V2.
///
/// Les colonnes sont 1-based pour correspondre à ce que l'utilisateur voit
/// dans l'atlas. Ce modèle reste strictement UI : aucune persistance et aucune
/// mutation du catalogue Surface.
final class SurfaceStudioColumnDragPayload {
  const SurfaceStudioColumnDragPayload({
    required this.columns,
    required this.tileWidth,
    required this.tileHeight,
    required this.frameCount,
  });

  final List<int> columns;
  final int tileWidth;
  final int tileHeight;
  final int frameCount;

  bool get isEmpty => columns.isEmpty;

  bool get isMultiColumn => columns.length > 1;

  String get label {
    if (columns.isEmpty) {
      return 'Aucune colonne';
    }
    if (columns.length == 1) {
      return 'Colonne ${columns.first}';
    }
    return 'Colonnes ${columns.first}-${columns.last}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SurfaceStudioColumnDragPayload &&
          _listEquals(other.columns, columns) &&
          other.tileWidth == tileWidth &&
          other.tileHeight == tileHeight &&
          other.frameCount == frameCount;

  @override
  int get hashCode => Object.hash(
        Object.hashAll(columns),
        tileWidth,
        tileHeight,
        frameCount,
      );
}

bool _listEquals(List<int> a, List<int> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
