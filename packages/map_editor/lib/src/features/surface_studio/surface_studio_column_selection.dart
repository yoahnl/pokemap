final class SurfaceStudioColumnSelection {
  const SurfaceStudioColumnSelection(this.columns);

  const SurfaceStudioColumnSelection.empty() : columns = const <int>[];

  final List<int> columns;

  bool get isEmpty => columns.isEmpty;

  bool get isNotEmpty => columns.isNotEmpty;

  int? get firstOrNull => columns.isEmpty ? null : columns.first;

  SurfaceStudioColumnSelection selectSingle(int column) =>
      SurfaceStudioColumnSelection(<int>[column]);

  SurfaceStudioColumnSelection selectContiguousTo(int column) {
    final anchor = firstOrNull ?? column;
    final start = anchor < column ? anchor : column;
    final end = anchor < column ? column : anchor;
    return SurfaceStudioColumnSelection(<int>[
      for (var value = start; value <= end; value++) value,
    ]);
  }

  String get microcopy {
    if (columns.isEmpty) {
      return 'Sélectionnez une ou plusieurs colonnes contiguës avec Maj + glisser';
    }
    if (columns.length == 1) {
      return 'Colonne ${columns.first} sélectionnée — glissez vers un rôle du schéma.';
    }
    return 'Colonnes ${columns.first}–${columns.last} sélectionnées — glissez vers un rôle du schéma.';
  }
}
