import '../domain/map_catalog_port.dart';
import 'map_library_outcome.dart';
import 'map_library_usages.dart';
import 'map_workspace_controller.dart';

final class MapLibraryDeletion {
  const MapLibraryDeletion._(
    this.mapId,
    this._preparation, {
    this.usages = const [],
    this.failure,
  });

  final String mapId;
  final List<MapLibraryUsage> usages;
  final MapLibraryOutcome? failure;
  final MapCatalogPreparation? _preparation;

  bool get allowed => _preparation != null && usages.isEmpty;

  static Future<MapLibraryDeletion> analyze(
    MapWorkspaceController maps,
    String mapId,
  ) async {
    if (!(maps.project?.maps.any((map) => map.id == mapId) ?? false)) {
      return MapLibraryDeletion._(
        mapId,
        null,
        failure: const MapLibraryOutcome.failed(MapLibraryProblem.missing),
      );
    }
    final MapCatalogPreparation preparation;
    try {
      preparation = await maps.prepareCatalog('map.delete_apply', {
        'mapId': mapId,
      });
    } on Object catch (failure) {
      return MapLibraryDeletion._(
        mapId,
        null,
        failure: MapLibraryOutcome.failed(
          MapLibraryProblem.refused,
          mapLibraryFailureText(failure),
        ),
      );
    }
    final usages = mapLibraryUsages(preparation.details, maps.project!);
    if (preparation.canApply || usages.isNotEmpty) {
      return MapLibraryDeletion._(mapId, preparation, usages: usages);
    }
    return MapLibraryDeletion._(
      mapId,
      null,
      failure: MapLibraryOutcome.failed(
        MapLibraryProblem.refused,
        preparation.issues.map((issue) => issue.message).join('\n'),
      ),
    );
  }

  Future<MapLibraryOutcome> confirm(MapWorkspaceController maps) async {
    final preparation = _preparation;
    if (!allowed || preparation == null) {
      return failure ??
          const MapLibraryOutcome.failed(MapLibraryProblem.refused);
    }
    return mapLibraryOutcome(
      await maps.applyPreparedCatalog(preparation, confirmDestructive: true),
    );
  }
}
