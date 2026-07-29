part of 'package:map_editor/src/ui/canvas/map_canvas.dart';

/// Helpers I/O et cache déplacés hors du shell principal du canvas pour garder
/// le fichier centré sur le widget et le flux d'interaction.
class _ResolvedTerrainFrame {
  const _ResolvedTerrainFrame({
    required this.tilesetId,
    required this.source,
  });

  final String tilesetId;
  final TilesetSourceRect source;
}
