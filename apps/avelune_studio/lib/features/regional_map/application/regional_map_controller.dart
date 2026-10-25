import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

import '../domain/regional_map_port.dart';

final class RegionalMapController {
  RegionalMapController(
    this.port, {
    required this.changed,
    this.mapDraftProblem,
    this.projectChanged,
  });
  final RegionalMapPort port;
  final VoidCallback changed;
  final String? Function(Set<String> mapIds)? mapDraftProblem;
  final void Function(ProjectManifest before, ProjectManifest after)?
  projectChanged;
  RegionalMapSource? source;
  final _mapReads = <String, Future<bool>>{};
  final _mapsLoading = <String>{};
  bool get loadingMap => _mapsLoading.isNotEmpty;
  ProjectRegionalMapCatalog catalog = ProjectRegionalMapCatalog();
  final _history = <ProjectRegionalMapCatalog>[];
  final _invalidRegionLabels = <String, String>{};
  final _invalidPointLabels = <String, String>{};
  String get regionLabel =>
      _invalidRegionLabels[regionId] ?? region?.label ?? '';
  String get pointLabel => _invalidPointLabels[pointId] ?? point?.label ?? '';
  String? regionId, pointId, error;
  bool busy = false, _disposed = false;
  bool get dirty =>
      source != null &&
      (catalog !=
              (source!.project.regionalMap ?? ProjectRegionalMapCatalog()) ||
          _invalidRegionLabels.isNotEmpty ||
          _invalidPointLabels.isNotEmpty);
  ProjectRegionDefinition? get region =>
      catalog.regions.where((value) => value.id == regionId).firstOrNull;
  ProjectRegionPointOfInterest? get point => catalog.pointsOfInterest
      .where((value) => value.id == pointId)
      .firstOrNull;
  List<ProjectRegionPointOfInterest> get points => catalog.pointsOfInterest
      .where((point) => point.regionId == regionId)
      .toList();
  bool get canUndo => !busy && _history.isNotEmpty;

  Future<void> load() async {
    if (busy || _disposed) return;
    final wasDirty = dirty;
    final previous = source;
    busy = true;
    _notify();
    try {
      final loaded = await port.load();
      if (_disposed) return;
      if (wasDirty &&
          previous?.project.regionalMap != loaded.project.regionalMap) {
        error = 'La carte régionale a changé sur le disque. Conservez ou abandonnez votre brouillon avant de recharger.';
        return;
      }
      source = loaded;
      if (!wasDirty) {
        catalog = loaded.project.regionalMap ?? ProjectRegionalMapCatalog();
      }
      regionId = region?.id ?? catalog.regions.firstOrNull?.id;
      pointId = point?.id;
      error = null;
    } on Object catch (failure) {
      error = 'La carte régionale ne peut pas être chargée : $failure';
    } finally {
      busy = false;
      _notify();
    }
  }

  void selectRegion(String id) {
    if (busy || !catalog.regions.any((region) => region.id == id)) return;
    regionId = id;
    pointId = null;
    _notify();
  }

  void selectPoint(String id) {
    if (busy || !points.any((point) => point.id == id)) return;
    pointId = id;
    _notify();
    final destination = point?.destination;
    if (destination != null) loadMap(destination.mapId);
  }

  Future<bool> loadMap(String id) {
    if (source?.maps.containsKey(id) == true) return Future.value(true);
    return _mapReads[id] ??= _loadMap(id)
        .whenComplete(() {
          _mapReads.remove(id);
        });
  }

  Future<bool> _loadMap(String id) async {
    final port = this.port;
    final before = source;
    if (before == null || _disposed || port is! RegionalMapDetailsPort) {
      return false;
    }
    _mapsLoading.add(id);
    _notify();
    try {
      final map = await (port as RegionalMapDetailsPort).readMap(
        source: before,
        mapId: id,
      );
      if (_disposed || source?.revision != before.revision) return false;
      final current = source!;
      source = RegionalMapSource(
        project: current.project,
        revision: current.revision,
        maps: {...current.maps, id: map},
        images: current.images,
      );
      return true;
    } on Object catch (failure) {
      error = 'La carte d’arrivée ne peut pas être chargée : $failure';
      return false;
    } finally {
      _mapsLoading.remove(id);
      _notify();
    }
  }

  bool _change(ProjectRegionalMapCatalog next) {
    if (busy || _disposed || source == null) return false;
    next = ProjectRegionalMapCatalog(
      regions: [...next.regions]..sort((a, b) => a.id.compareTo(b.id)),
      pointsOfInterest: [...next.pointsOfInterest]
        ..sort((a, b) => a.id.compareTo(b.id)),
    );
    if (catalog == next) {
      error = null;
      _notify();
      return true;
    }
    _history.add(catalog);
    catalog = next;
    error = null;
    _notify();
    return true;
  }

  void undo() {
    if (!canUndo) return;
    catalog = _history.removeLast();
    _invalidRegionLabels.clear();
    _invalidPointLabels.clear();
    regionId = region?.id ?? catalog.regions.firstOrNull?.id;
    pointId = point?.id;
    error = null;
    _notify();
  }

  void discard() {
    if (busy || source == null) return;
    catalog = source!.project.regionalMap ?? ProjectRegionalMapCatalog();
    _history.clear();
    _invalidRegionLabels.clear();
    _invalidPointLabels.clear();
    regionId = region?.id ?? catalog.regions.firstOrNull?.id;
    pointId = point?.id;
    error = null;
    _notify();
  }

  void createRegion(String label) {
    if (label.trim().isEmpty) return;
    final created = ProjectRegionDefinition(
      id: 'region_${DateTime.now().microsecondsSinceEpoch}',
      label: label.trim(),
    );
    if (_change(
      ProjectRegionalMapCatalog(
        regions: [...catalog.regions, created],
        pointsOfInterest: catalog.pointsOfInterest,
      ),
    )) {
      regionId = created.id;
      pointId = null;
      _notify();
    }
  }

  void editRegion({String? label, String? imagePath, bool clearImage = false}) {
    final selected = region;
    if (selected == null || busy || _disposed) return;
    if (label?.trim().isEmpty == true) {
      _invalidRegionLabels[selected.id] = label!;
      error = 'Le nom de la région est obligatoire.';
      _notify();
      return;
    }
    if (label != null) _invalidRegionLabels.remove(selected.id);
    final next = ProjectRegionDefinition(
      id: selected.id,
      label: label?.trim() ?? selected.label,
      labels: selected.labels,
      imagePath: clearImage ? null : imagePath ?? selected.imagePath,
      sampling: selected.sampling,
      sortOrder: selected.sortOrder,
    );
    _change(
      ProjectRegionalMapCatalog(
        regions: [
          for (final region in catalog.regions)
            region.id == next.id ? next : region,
        ],
        pointsOfInterest: catalog.pointsOfInterest,
      ),
    );
  }

  void deleteRegion() {
    if (region == null) return;
    if (points.isNotEmpty) {
      error = 'Retirez les lieux de la région avant de la supprimer.';
      _notify();
      return;
    }
    if (_change(
      ProjectRegionalMapCatalog(
        regions: catalog.regions
            .where((region) => region.id != regionId)
            .toList(),
        pointsOfInterest: catalog.pointsOfInterest,
      ),
    )) {
      _invalidRegionLabels.remove(regionId);
      regionId = catalog.regions.firstOrNull?.id;
      _notify();
    }
  }

  void createPoint(String label, String discoveryMapId) {
    if (region == null ||
        label.trim().isEmpty ||
        !source!.project.maps.any((map) => map.id == discoveryMapId)) {
      return;
    }
    final created = ProjectRegionPointOfInterest(
      id: 'place_${DateTime.now().microsecondsSinceEpoch}',
      regionId: regionId!,
      label: label.trim(),
      u: .5,
      v: .5,
      mapIds: [discoveryMapId],
    );
    if (_change(
      ProjectRegionalMapCatalog(
        regions: catalog.regions,
        pointsOfInterest: [...catalog.pointsOfInterest, created],
      ),
    )) {
      pointId = created.id;
      _notify();
    }
  }

  void editPoint({
    String? label,
    double? u,
    double? v,
    List<String>? mapIds,
    ProjectRegionPointVisibility? visibility,
    ProjectRegionPointDiscovery? discovery,
    ProjectRegionDestination? destination,
    bool clearDestination = false,
  }) {
    final selected = point;
    if (selected == null || busy || _disposed) return;
    if (label?.trim().isEmpty == true) {
      _invalidPointLabels[selected.id] = label!;
      error = 'Le nom du lieu est obligatoire.';
      _notify();
      return;
    }
    if (label != null) _invalidPointLabels.remove(selected.id);
    if ((discovery ?? selected.discovery) ==
            ProjectRegionPointDiscovery.onMapVisit &&
        (mapIds ?? selected.mapIds).isEmpty) {
      error = 'Choisissez au moins une carte de découverte avant d’activer la découverte par visite.';
      _notify();
      return;
    }
    final next = ProjectRegionPointOfInterest(
      id: selected.id,
      regionId: selected.regionId,
      label: label?.trim() ?? selected.label,
      labels: selected.labels,
      u: (u ?? selected.u).clamp(0, 1),
      v: (v ?? selected.v).clamp(0, 1),
      visibility: visibility ?? selected.visibility,
      discovery: discovery ?? selected.discovery,
      mapIds: mapIds ?? selected.mapIds,
      description: selected.description,
      descriptions: selected.descriptions,
      thumbnailPath: selected.thumbnailPath,
      destination: clearDestination
          ? null
          : destination ?? selected.destination,
      sortOrder: selected.sortOrder,
    );
    _change(
      ProjectRegionalMapCatalog(
        regions: catalog.regions,
        pointsOfInterest: [
          for (final point in catalog.pointsOfInterest)
            point.id == next.id ? next : point,
        ],
      ),
    );
    if (destination != null) loadMap(destination.mapId);
  }

  void deletePoint() {
    if (point == null) return;
    if (_change(
      ProjectRegionalMapCatalog(
        regions: catalog.regions,
        pointsOfInterest: catalog.pointsOfInterest
            .where((point) => point.id != pointId)
            .toList(),
      ),
    )) {
      _invalidPointLabels.remove(pointId);
      pointId = null;
      _notify();
    }
  }

  String? validate({Map<String, MapData>? maps, bool checkMapDrafts = true}) {
    if (_invalidRegionLabels.isNotEmpty || _invalidPointLabels.isNotEmpty) {
      return 'Renseignez les noms des régions et des lieux avant de publier.';
    }
    final loaded = source;
    if (loaded == null) {
      return 'Chargez le projet avant de modifier sa carte régionale.';
    }
    final resolvedMaps = maps ?? loaded.maps;
    for (final region in catalog.regions) {
      if (region.imagePath == null ||
          !loaded.images.containsKey(region.imagePath)) {
        return 'Choisissez une image de la bibliothèque pour ${region.label}.';
      }
    }
    final diagnostics = validateProjectRegionalMap(
      catalog: catalog,
      projectMapIds: loaded.project.maps.map((map) => map.id),
      maps: resolvedMaps.values,
    );
    if (diagnostics.isNotEmpty) {
      return 'Un lieu référence une carte ou une arrivée indisponible : ${diagnostics.first.message}';
    }
    final usedMaps = <String>{};
    for (final point in catalog.pointsOfInterest) {
      usedMaps.addAll(point.mapIds);
      final target = point.destination;
      if (target == null) continue;
      usedMaps.add(target.mapId);
      final map = resolvedMaps[target.mapId];
      final spawn =
          map?.entities
              .where(
                (entity) =>
                    entity.kind == MapEntityKind.spawn &&
                    entity.spawn != null &&
                    (entity.id == target.spawnId ||
                        entity.spawn!.spawnKey == target.spawnId),
              )
              .toList() ??
          [];
      if (map == null ||
          map.version != ProjectVersion.v8 ||
          map.spatialScene != null ||
          target.spawnId == null ||
          spawn.length != 1 ||
          point.mapIds.isEmpty ||
          spawn.single.pos.x < 0 ||
          spawn.single.pos.y < 0 ||
          spawn.single.pos.x >= map.size.width ||
          spawn.single.pos.y >= map.size.height) {
        return 'Choisissez une arrivée unique sur une carte 2D et au moins une carte de découverte.';
      }
    }
    return checkMapDrafts ? mapDraftProblem?.call(usedMaps) : null;
  }

  Future<bool> saveAll() async {
    if (busy || _disposed) return false;
    if (!dirty) return true;
    busy = true;
    _notify();
    for (final point in catalog.pointsOfInterest) {
      final destination = point.destination;
      if (destination != null && !await loadMap(destination.mapId)) {
        error ??= 'Choisissez une carte d’arrivée disponible.';
        busy = false;
        _notify();
        return false;
      }
    }
    error = validate();
    if (error != null) {
      busy = false;
      _notify();
      return false;
    }
    final desired = catalog;
    try {
      Future<void> publish(
        String actionId,
        Map<String, Object?> parameters,
      ) async {
        final before = source!;
        final after = await port.publish(
          base: before,
          actionId: actionId,
          parameters: parameters,
        );
        if (_disposed) return;
        source = after;
        projectChanged?.call(before.project, after.project);
      }

      final initial =
          source!.project.regionalMap ?? ProjectRegionalMapCatalog();
      for (final point in initial.pointsOfInterest) {
        if (!desired.pointsOfInterest.any((value) => value.id == point.id)) {
          await publish('regionalMap.poi.delete', {'poiId': point.id});
        }
      }
      for (final region in desired.regions) {
        if (!initial.regions.contains(region)) {
          await publish('regionalMap.region.upsert', {
            'region': region.toJson(),
          });
        }
      }
      for (final point in desired.pointsOfInterest) {
        if (!initial.pointsOfInterest.contains(point)) {
          await publish('regionalMap.poi.upsert', {'poi': point.toJson()});
        }
      }
      for (final region in initial.regions) {
        if (!desired.regions.any((value) => value.id == region.id)) {
          await publish('regionalMap.region.delete', {'regionId': region.id});
        }
      }
      _history.clear();
      error = null;
      return !dirty;
    } on Object catch (failure) {
      error =
          'La publication a échoué. Votre brouillon est conservé : $failure';
      return false;
    } finally {
      busy = false;
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) changed();
  }

  void dispose() {
    _disposed = true;
  }
}
