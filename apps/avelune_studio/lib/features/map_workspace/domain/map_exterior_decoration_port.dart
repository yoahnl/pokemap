import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';

final class MapExteriorDecorationState {
  const MapExteriorDecorationState({
    required this.decoration,
    required this.revision,
    this.supported = true,
  });
  final bool supported;
  final MapExteriorDecoration? decoration;
  final String revision;
}

final class MapExteriorDecorationWrite {
  const MapExteriorDecorationWrite({
    required this.revision,
    required this.receiptId,
  });
  final String revision, receiptId;
}

abstract interface class MapExteriorDecorationPort {
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  );
  Future<MapExteriorDecorationWrite> configureExteriorDecoration(
    ProjectSession session,
    String mapId,
    MapExteriorDecoration? definition,
    String expectedRevision,
  );
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    ExteriorDecorationSector sector,
    String expectedRevision,
  );
  Future<MapExteriorDecorationWrite> removeExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    String sectorId,
    String expectedRevision,
  );
  Future<MapExteriorDecorationWrite> saveExteriorDecorationBorder(
    ProjectSession session,
    String mapId,
    ExteriorDecorationBorder border,
    String expectedRevision,
  );
  Future<MapExteriorDecorationWrite> removeExteriorDecorationBorder(
    ProjectSession session,
    String mapId,
    String borderId,
    String expectedRevision,
  );
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSectors(
    ProjectSession session,
    String mapId,
    List<ExteriorDecorationSector> sectors,
    List<String> removeSectorIds,
    String expectedRevision,
  );
}
