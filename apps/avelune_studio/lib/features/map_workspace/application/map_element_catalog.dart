import 'package:map_core/map_core.dart';

final class MapElementListEntry {
  const MapElementListEntry({
    required this.kind,
    required this.id,
    required this.label,
    required this.family,
    required this.detail,
    this.layerId,
    this.isCharacter = false,
  });
  final String kind, id, label, family, detail;
  final String? layerId;
  final bool isCharacter;
  String get key => '$kind:$id';
}

final class MapElementResourceIndex {
  MapElementResourceIndex(ProjectManifest project) {
    elements = {for (final value in project.elements) value.id: value};
    categories = {
      for (final value in project.elementCategories) value.id: value.name,
    };
    models = {for (final value in project.models3d) value.id: value};
    characters = {for (final value in project.characters) value.id: value.name};
    mapNames = {for (final value in project.maps) value.id: value.name};
    resourceFamilies = {
      for (final value in project.resourceLibraryCatalog.effectiveFamilies)
        value.id: value.name,
    };
    resourceMetadata = {
      for (final value in project.resourceLibraryCatalog.entries)
        '${value.resourceKind}:${value.resourceId}': value,
    };
  }

  late final Map<String, ProjectElementEntry> elements;
  late final Map<String, String> categories,
      characters,
      mapNames,
      resourceFamilies;
  late final Map<String, ProjectModel3dEntry> models;
  late final Map<String, ResourceLibraryEntry> resourceMetadata;

  String? familyOf(String kind, String id) =>
      resourceFamilies[resourceMetadata['$kind:$id']?.familyId];
}

final class MapElementCatalog {
  MapElementCatalog(
    MapData map,
    ProjectManifest project, {
    MapElementResourceIndex? resources,
  }) {
    final index = resources ?? MapElementResourceIndex(project);
    final byLayer = <String, List<MapPlacedElement>>{};
    for (final item in map.placedElements) {
      byLayer.putIfAbsent(item.layerId, () => []).add(item);
    }
    final layerIds = map.layers.map((layer) => layer.id).toSet();
    final layerNames = <String, int>{};
    for (final layer in map.layers) {
      layerNames[layer.name] = (layerNames[layer.name] ?? 0) + 1;
    }
    final layers = mapPaintsFirstLayerInFront(map)
        ? map.layers
        : map.layers.reversed;
    for (final layer in layers) {
      final type = switch (layer) {
        TileLayer() => 'Tuiles',
        SmartTileLayer() => 'Terrain',
        ObjectLayer() => 'Objets importés',
        EnvironmentLayer() => 'Environnement',
        BorderLayer() => 'Bordure',
        CollisionLayer() => 'Collisions',
      };
      final entry = MapElementListEntry(
        kind: 'layer',
        id: layer.id,
        label: layer.name,
        family: 'Calques',
        detail: '$type${layer.isVisible ? '' : ' · masqué'}',
      );
      entries.add(entry);
      stacking.putIfAbsent('Calques', () => []).add(entry);
      final placed = sortMapPlacedElementsForPainting(
        byLayer[layer.id] ?? const [],
      ).reversed;
      for (final item in placed) {
        final definition = index.elements[item.elementId];
        final entry = MapElementListEntry(
          kind: 'decor',
          id: item.id,
          label: definition?.name ?? item.elementId,
          family:
              'Décors · ${index.familyOf('element', item.elementId) ?? index.categories[definition?.categoryId] ?? 'Autres'}',
          detail: '${layer.name} · Z ${item.visualOrder}',
          layerId: layer.id,
        );
        entries.add(entry);
        final group =
            'Décors · ${layer.name}${layerNames[layer.name]! > 1 ? ' (calque ${map.layers.indexOf(layer) + 1})' : ''}';
        stacking.putIfAbsent(group, () => []).add(entry);
      }
    }
    for (final item in map.placedElements.where(
      (item) => !layerIds.contains(item.layerId),
    )) {
      entries.add(
        MapElementListEntry(
          kind: 'decor',
          id: item.id,
          label: index.elements[item.elementId]?.name ?? item.elementId,
          family: 'Décors · Sans calque',
          detail: 'Calque manquant',
          layerId: item.layerId,
        ),
      );
    }
    for (final item
        in map.spatialScene?.instances ?? <SpatialModelInstance>[]) {
      final model = index.models[item.modelId];
      entries.add(
        MapElementListEntry(
          kind: 'model',
          id: item.id,
          label: model?.name ?? item.modelId,
          family:
              'Décors · ${index.familyOf('model3d', item.modelId) ?? (model?.light != null ? 'Lumières 3D' : 'Modèles 3D')}',
          detail:
              'Profondeur spatiale · ${item.position.x.toStringAsFixed(1)}, ${item.position.z.toStringAsFixed(1)}',
        ),
      );
    }
    for (final entity in map.entities) {
      final npc = entity.kind == MapEntityKind.npc;
      entries.add(
        MapElementListEntry(
          kind: 'entity',
          id: entity.id,
          label: entity.name.isNotEmpty
              ? entity.name
              : index.characters[entity.npc?.characterId] ?? entity.id,
          family: npc ? 'Personnages' : 'Repères et objets de jeu',
          detail: '${entity.pos.x}, ${entity.pos.y}',
          isCharacter: npc,
        ),
      );
    }
    for (final warp in map.warps) {
      final destination = index.mapNames[warp.targetMapId];
      entries.add(
        MapElementListEntry(
          kind: 'warp',
          id: warp.id,
          label: destination == null
              ? 'Point d’arrivée ${warp.id}'
              : 'Passage vers $destination',
          family: 'Passages',
          detail: '${warp.pos.x}, ${warp.pos.y}',
        ),
      );
    }
    for (final zone in map.gameplayZones) {
      entries.add(
        MapElementListEntry(
          kind: 'zone',
          id: zone.id,
          label: zone.name.isEmpty ? zone.id : zone.name,
          family: 'Zones de jeu',
          detail: zone.kind.name,
        ),
      );
    }
    for (final trigger in map.triggers) {
      entries.add(
        MapElementListEntry(
          kind: 'trigger',
          id: trigger.id,
          label: trigger.name.isEmpty ? trigger.id : trigger.name,
          family: 'Zones d’histoire',
          detail: trigger.type.name,
        ),
      );
    }
    for (final entry in entries) {
      families.putIfAbsent(entry.family, () => []).add(entry);
    }
  }

  final entries = <MapElementListEntry>[];
  final families = <String, List<MapElementListEntry>>{};
  final stacking = <String, List<MapElementListEntry>>{};
}
