import 'package:map_core/map_core.dart';
import '../workspace/workspace_policy.dart';

final class MapAtmosphereSnapshot {
  const MapAtmosphereSnapshot({required this.revision, required this.settings});
  final String revision;
  final SpatialAtmosphereSettings settings;
}

final class MapAtmosphereMutation {
  const MapAtmosphereMutation(
      {required this.afterRevision, required this.afterSettings});
  final String afterRevision;
  final SpatialAtmosphereSettings afterSettings;
}

final class LocalMapAtmosphereAuthoring {
  LocalMapAtmosphereAuthoring({required WorkspacePolicy policy});
  Future<MapAtmosphereSnapshot> inspect(
          {required String projectRoot, required String mapId}) async =>
      throw UnimplementedError();
  Future<MapAtmosphereMutation> set(
          {required String projectRoot,
          required String mapId,
          required String expectedRevision,
          required SpatialAtmosphereSettings settings,
          required String operationId}) async =>
      throw UnimplementedError();
}
