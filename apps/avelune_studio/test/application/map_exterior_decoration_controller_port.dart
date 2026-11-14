import 'dart:async';

import 'package:avelune_studio/features/map_workspace/domain/map_exterior_decoration_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:map_core/map_core.dart';

final class ExteriorDecorationPort implements MapExteriorDecorationPort {
  int loads = 0, revision = 0, sectorWrites = 0, batchWrites = 0;
  MapExteriorDecoration? value;
  Completer<void>? pending;
  Object? failure;
  MapExteriorDecoration withSectors(
    MapExteriorDecoration header,
    Iterable<ExteriorDecorationSector> sectors,
  ) => MapExteriorDecoration(
    mapId: header.mapId,
    playableWidth: header.playableWidth,
    playableDepth: header.playableDepth,
    west: header.west,
    east: header.east,
    north: header.north,
    south: header.south,
    sectors: sectors,
  );
  Future<MapExteriorDecorationWrite> result() async {
    if (failure != null) throw failure!;
    await pending?.future;
    revision++;
    return MapExteriorDecorationWrite(
      revision: 'revision_$revision',
      receiptId: 'receipt_$revision',
    );
  }

  @override
  Future<MapExteriorDecorationState> loadExteriorDecoration(
    ProjectSession session,
    String mapId,
  ) async {
    loads++;
    return MapExteriorDecorationState(
      decoration: value,
      revision: 'revision_$revision',
    );
  }

  @override
  Future<MapExteriorDecorationWrite> configureExteriorDecoration(
    ProjectSession session,
    String mapId,
    MapExteriorDecoration? definition,
    String expectedRevision,
  ) async {
    final response = await result();
    value = definition == null
        ? null
        : withSectors(definition, value?.sectors ?? const []);
    return response;
  }

  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    ExteriorDecorationSector sector,
    String expectedRevision,
  ) async {
    final response = await result();
    sectorWrites++;
    value = withSectors(
      value!,
      {
        for (final item in value!.sectors) item.id: item,
        sector.id: sector,
      }.values,
    );
    return response;
  }

  @override
  Future<MapExteriorDecorationWrite> removeExteriorDecorationSector(
    ProjectSession session,
    String mapId,
    String sectorId,
    String expectedRevision,
  ) async {
    final response = await result();
    value = withSectors(value!, value!.sectors.where((v) => v.id != sectorId));
    return response;
  }

  @override
  Future<MapExteriorDecorationWrite> saveExteriorDecorationSectors(
    ProjectSession session,
    String mapId,
    List<ExteriorDecorationSector> sectors,
    List<String> removeSectorIds,
    String expectedRevision,
  ) async {
    final response = await result();
    batchWrites++;
    sectorWrites += sectors.length;
    value = withSectors(
      value!,
      {
        for (final item in value!.sectors)
          if (!removeSectorIds.contains(item.id)) item.id: item,
        for (final item in sectors) item.id: item,
      }.values,
    );
    return response;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
