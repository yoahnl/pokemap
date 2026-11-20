import 'dart:collection';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:map_core/map_core_domain.dart';

import '../../../features/resources/application/project_resource_library.dart';
import 'library/resource_library_view_data.dart';

class ProjectLibraryCatalogView {
  ProjectLibraryCatalogView(
    ProjectResourceLibrary library, {
    Map<String, Set<String>>? mapUsages,
    Iterable<ProjectLibraryItem>? items,
  }) : hasMapUsages = mapUsages != null,
       _catalog = library.catalog,
       _mapUsages = mapUsages {
    _indexFamilies();
    for (final item in items ?? library.items) {
      upsert(item);
    }
  }

  void _indexFamilies() {
    final families = {
      for (final family in _catalog.effectiveFamilies) family.id: family,
    };
    List<String> ancestors(String? id) {
      final path = <String>[];
      while (id != null && families.containsKey(id)) {
        final family = families[id]!;
        path.add(id);
        id = family.parentId;
      }
      return path.reversed.toList(growable: false);
    }

    final labels = [
      for (final id in families.keys)
        MapEntry(
          id,
          ancestors(id).map((part) => families[part]!.name).join(' › '),
        ),
    ]..sort((a, b) => a.value.compareTo(b.value));
    _familyLabels = Map.unmodifiable(Map.fromEntries(labels));
    _familyPaths = {for (final id in families.keys) id: ancestors(id)};
  }

  void updateFamily(String id, ResourceFamily? family) {
    final previousCatalog = _catalog;
    final previousLabels = _familyLabels;
    final previousPaths = _familyPaths;
    _catalog = ResourceLibraryCatalog(
      families: [
        for (final current in _catalog.families)
          if (current.id != id) current,
        ?family,
      ],
    );
    _indexFamilies();
    for (final MapEntry(key: familyId, value: members) in _members.entries) {
      if (previousLabels[familyId] == _familyLabels[familyId] &&
          listEquals(previousPaths[familyId], _familyPaths[familyId]) &&
          previousCatalog.familyCategory(familyId) ==
              _catalog.familyCategory(familyId)) {
        continue;
      }
      for (final identity in members) {
        _items[_positions[identity]!] = _project(_entries[identity]!);
      }
    }
  }

  ResourceLibraryItemView upsert(ProjectLibraryItem item) {
    final position = _positions[item.identity];
    if (position != null && identical(_entries[item.identity], item)) {
      return _items[position];
    }
    final previousFamily = _entries[item.identity]?.familyId;
    final family = item.familyId;
    if (previousFamily != family) {
      if (previousFamily != null) {
        _members[previousFamily]?.remove(item.identity);
      }
      if (family != null) {
        _members.putIfAbsent(family, () => {}).add(item.identity);
      }
    }
    final view = _project(item);
    _entries[item.identity] = item;
    if (position == null) {
      _positions[item.identity] = _items.length;
      _items.add(view);
    } else {
      _items[position] = view;
    }
    return view;
  }

  ResourceLibraryItemView _project(ProjectLibraryItem item) {
    final dimensions = {
      for (final dimension in item.compatibleDimensions)
        switch (dimension) {
          ProjectDimension.twoD => ResourceLibraryDimension.twoDimensional,
          ProjectDimension.threeD => ResourceLibraryDimension.threeDimensional,
        },
    };
    return ResourceLibraryItemView(
      id: item.identity,
      name: item.name,
      category: _category(item, _catalog),
      type: _type(item),
      dimension: dimensions.length == 1 ? dimensions.single : null,
      compatibleDimensions: dimensions,
      usedOn: _mapUsages == null ? null : _mapUsages[item.identity] ?? const {},
      role: item.role,
      familyIds: _familyPaths[item.familyId] ?? const [],
      familyPath: familyLabels[item.familyId],
      mapId: item.mapId,
      description: item.description,
      searchText: item.searchText,
      placement: switch (item.placementContext) {
        ResourcePlacementContext.interior => 'Intérieur',
        ResourcePlacementContext.exterior => 'Extérieur',
        ResourcePlacementContext.both => 'Intérieur et extérieur',
        null => null,
      },
      canDuplicate: item.kind != 'borderBlueprint',
    );
  }

  void remove(String identity) {
    final position = _positions.remove(identity);
    if (position == null) return;
    if (_entries.remove(identity)?.familyId case final family?) {
      _members[family]?.remove(identity);
    }
    _items.removeAt(position);
    for (var index = position; index < _items.length; index++) {
      _positions[_items[index].id] = index;
    }
  }

  void applyDimensions(Map<String, Set<ProjectDimension>> dimensions) {
    for (final entry in dimensions.entries) {
      final item = _entries[entry.key];
      if (item == null || item.compatibleDimensions.isNotEmpty) continue;
      upsert(item.withDimensions(entry.value));
    }
  }

  Map<String, String> get familyLabels => _familyLabels;
  ResourceLibraryCatalog get metadata => _catalog;
  ResourceLibraryItemView? item(String id) => switch (_positions[id]) {
    final position? => _items[position],
    null => null,
  };

  late Map<String, String> _familyLabels;
  late Map<String, List<String>> _familyPaths;
  ResourceLibraryCatalog _catalog;
  final Map<String, Set<String>>? _mapUsages;
  final _entries = <String, ProjectLibraryItem>{};
  final _members = <String, Set<String>>{};
  final _items = <ResourceLibraryItemView>[];
  final _positions = <String, int>{};
  late final Map<String, ProjectLibraryItem> entries = UnmodifiableMapView(
    _entries,
  );
  late final List<ResourceLibraryItemView> items = UnmodifiableListView(_items);
  final bool hasMapUsages;
}

ResourceLibraryCategory _category(
  ProjectLibraryItem item,
  ResourceLibraryCatalog catalog,
) {
  if (item.kind == 'tileset') return ResourceLibraryCategory.images;
  if (item.kind == 'character') return ResourceLibraryCategory.characters;
  if (item.kind == 'model3d' && item.role == ResourceLibraryRole.component) {
    return ResourceLibraryCategory.models;
  }
  return switch (item.category ?? catalog.familyCategory(item.familyId)) {
    ResourceUsageCategory.vegetation => ResourceLibraryCategory.vegetation,
    ResourceUsageCategory.ground => ResourceLibraryCategory.ground,
    ResourceUsageCategory.path => ResourceLibraryCategory.paths,
    ResourceUsageCategory.water => ResourceLibraryCategory.water,
    ResourceUsageCategory.relief => ResourceLibraryCategory.relief,
    ResourceUsageCategory.building => ResourceLibraryCategory.buildings,
    ResourceUsageCategory.structure => ResourceLibraryCategory.structures,
    ResourceUsageCategory.furniture => ResourceLibraryCategory.furniture,
    ResourceUsageCategory.object => ResourceLibraryCategory.objects,
    null => switch (item.kind) {
      'smartTilePreset' => ResourceLibraryCategory.ground,
      'borderBlueprint' => ResourceLibraryCategory.relief,
      'environmentPreset' => ResourceLibraryCategory.environments,
      _ => ResourceLibraryCategory.objects,
    },
  };
}

String _type(ProjectLibraryItem item) => switch (item.kind) {
  'model3d' =>
    item.role == ResourceLibraryRole.component
        ? 'Modèle 3D source'
        : 'Modèle 3D',
  'element' => 'Décor 2D',
  'tileset' => 'Image et tuiles',
  'character' => 'Personnage',
  'borderBlueprint' => 'Bordure',
  'environmentPreset' => 'Ensemble de décors',
  'smartTilePreset' => 'Terrain à peindre',
  _ => 'Ressource',
};
