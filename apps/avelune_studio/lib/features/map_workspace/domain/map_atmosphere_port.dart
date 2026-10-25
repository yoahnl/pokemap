import 'package:map_core/map_core.dart';

import '../../project_session/domain/project_session.dart';

final class MapAtmosphereState {
  const MapAtmosphereState({required this.settings, required this.revision});
  final SpatialAtmosphereSettings settings;
  final String revision;
}

abstract interface class MapAtmospherePort {
  Future<MapAtmosphereState> loadAtmosphere(
    ProjectSession session,
    String mapId,
  );
  Future<MapAtmosphereState> saveAtmosphere(
    ProjectSession session,
    String mapId,
    SpatialAtmosphereSettings settings,
    String expectedRevision,
  );
}
