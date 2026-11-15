import '../domain/map_catalog_port.dart';

enum MapLibraryProblem {
  nameRequired,
  sizeInvalid,
  folderNameTaken,
  folderNotEmpty,
  missing,
  refused,
  publishedNotIntegrated,
}

final class MapLibraryOutcome {
  const MapLibraryOutcome.done({this.mapId, this.groupId})
    : problem = null,
      detail = null;
  const MapLibraryOutcome.failed(MapLibraryProblem this.problem, [this.detail])
    : mapId = null,
      groupId = null;

  final MapLibraryProblem? problem;
  final String? detail;
  final String? mapId;
  final String? groupId;

  bool get ok => problem == null;
}

MapLibraryOutcome mapLibraryOutcome(
  MapCatalogResult result, {
  String? mapId,
  String? groupId,
}) {
  if (result.integrated) {
    return MapLibraryOutcome.done(mapId: mapId, groupId: groupId);
  }
  return MapLibraryOutcome.failed(
    result.published
        ? MapLibraryProblem.publishedNotIntegrated
        : MapLibraryProblem.refused,
    result.error,
  );
}
