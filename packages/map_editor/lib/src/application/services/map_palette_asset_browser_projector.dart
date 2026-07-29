import 'package:map_core/map_core.dart';

import '../../features/editor/state/models/editor_palette_session.dart';
import '../models/map_palette_asset_browser.dart';
import '../use_cases/project_element_use_cases.dart';
import '../use_cases/project_tileset_use_cases.dart';

class MapPaletteAssetBrowserProjector {
  MapPaletteAssetBrowserProjector(
    this._assignableTilesetsResolver, [
    ResolveVisibleProjectElementsUseCase? visibleElementsResolver,
  ]) : _visibleElementsResolver =
            visibleElementsResolver ?? ResolveVisibleProjectElementsUseCase();

  final ResolveAssignableTilesetsForMapUseCase _assignableTilesetsResolver;
  final ResolveVisibleProjectElementsUseCase _visibleElementsResolver;

  MapPaletteAssetBrowserProjection project({
    required ProjectManifest? project,
    required MapData? map,
    required String? activeLayerId,
    String? selectedTilesetId,
    String query = '',
    String? folderId,
    String? elementCategoryId,
    EditorPaletteAssetCollection collection = EditorPaletteAssetCollection.all,
    bool showIncompatible = false,
    List<String> recentTilesetIds = const <String>[],
    List<String> favoriteTilesetIds = const <String>[],
  }) {
    if (project == null) {
      return const MapPaletteAssetBrowserProjection(
        status: MapPaletteAssetBrowserStatus.noProject,
        activeLayerName: null,
        assignedTilesetId: null,
        selectedTilesetId: null,
        folders: <MapPaletteAssetFolderRow>[],
        categories: <MapPaletteAssetCategoryRow>[],
        items: <MapPaletteAssetBrowserItem>[],
        hiddenIncompatibleCount: 0,
        hasUnclassifiedSources: false,
        diagnostic: 'Ouvrez un projet avant de parcourir ses sources.',
      );
    }
    final folders = _folderRows(project);
    final categories = _categoryRows(project);
    if (map == null) {
      return MapPaletteAssetBrowserProjection(
        status: MapPaletteAssetBrowserStatus.noMap,
        activeLayerName: null,
        assignedTilesetId: null,
        selectedTilesetId: selectedTilesetId,
        folders: List<MapPaletteAssetFolderRow>.unmodifiable(folders),
        categories: List<MapPaletteAssetCategoryRow>.unmodifiable(categories),
        items: const <MapPaletteAssetBrowserItem>[],
        hiddenIncompatibleCount: 0,
        hasUnclassifiedSources: _hasUnclassifiedSources(project),
        diagnostic: 'Ouvrez une carte avant de choisir une source.',
      );
    }
    final folderPathById = <String, String>{
      for (final folder in folders) folder.id: folder.path,
    };
    final categoryPathById = <String, String>{
      for (final category in categories) category.id: category.path,
    };

    MapLayer? activeLayer;
    if (activeLayerId != null) {
      for (final layer in map.layers) {
        if (layer.id == activeLayerId) {
          activeLayer = layer;
          break;
        }
      }
    }

    var status = MapPaletteAssetBrowserStatus.ready;
    String? diagnostic;
    if (activeLayerId == null) {
      status = MapPaletteAssetBrowserStatus.noActiveLayer;
      diagnostic = 'Sélectionnez un calque avant de choisir une source.';
    } else if (activeLayer == null) {
      status = MapPaletteAssetBrowserStatus.activeLayerMissing;
      diagnostic = 'Le calque actif n’existe plus dans cette carte.';
    } else if (activeLayer is! TileLayer) {
      status = MapPaletteAssetBrowserStatus.unsupportedLayer;
      diagnostic = 'Sélectionnez un calque de tuiles pour assigner une source.';
    }

    List<ProjectTilesetEntry> assignableInResolverOrder;
    Set<String> assignableIds;
    try {
      assignableInResolverOrder =
          _assignableTilesetsResolver.execute(project, map.id);
      assignableIds =
          assignableInResolverOrder.map((tileset) => tileset.id).toSet();
    } on Object catch (error) {
      assignableInResolverOrder = const <ProjectTilesetEntry>[];
      assignableIds = const <String>{};
      status = MapPaletteAssetBrowserStatus.invalidMapScope;
      diagnostic = 'La portée de sources de cette carte est invalide : $error';
    }

    List<ProjectElementEntry> visibleElements;
    try {
      visibleElements = _visibleElementsResolver.execute(
        project,
        mapId: map.id,
      );
    } on Object {
      visibleElements = const <ProjectElementEntry>[];
    }
    final elementsByTilesetId = <String, List<ProjectElementEntry>>{};
    for (final element in visibleElements) {
      elementsByTilesetId
          .putIfAbsent(element.tilesetId, () => <ProjectElementEntry>[])
          .add(element);
    }

    final assignedTilesetId =
        activeLayer is TileLayer ? _assignedTilesetId(map, activeLayer) : null;
    final layerIsEmpty = activeLayer is TileLayer &&
        activeLayer.tiles.every((tile) => tile == 0);
    final assignedSourceMissing = assignedTilesetId != null &&
        !project.tilesets.any((tileset) => tileset.id == assignedTilesetId);
    if (status == MapPaletteAssetBrowserStatus.ready && assignedSourceMissing) {
      status = MapPaletteAssetBrowserStatus.assignedSourceMissing;
      diagnostic = layerIsEmpty
          ? 'La source assignée « $assignedTilesetId » n’existe plus dans le '
              'projet. Choisissez puis assignez une source disponible pour '
              'réparer ce calque vide.'
          : 'La source assignée « $assignedTilesetId » n’existe plus dans le '
              'projet. Ce calque contient encore des tuiles : videz-le avant '
              'de changer de source afin de ne pas réinterpréter leurs IDs.';
    }
    final recentIndexById = <String, int>{
      for (var index = 0; index < recentTilesetIds.length; index++)
        recentTilesetIds[index]: index,
    };
    final favoriteIds = favoriteTilesetIds.toSet();
    final selectedCategoryIds = elementCategoryId == null
        ? const <String>{}
        : _categorySubtreeIds(project, elementCategoryId);
    final folderIds =
        folderId == null || folderId == kEditorPaletteUnclassifiedFolderId
            ? const <String>{}
            : tilesetFolderSubtreeIds(project, folderId);
    final queryTokens = _tokens(query);

    final orderedTilesets = <ProjectTilesetEntry>[
      ...assignableInResolverOrder,
      ...project.tilesets.where(
        (tileset) => !assignableIds.contains(tileset.id),
      ),
    ];

    final projected = <MapPaletteAssetBrowserItem>[];
    var hiddenIncompatibleCount = 0;
    for (final tileset in orderedTilesets) {
      final isAssigned = tileset.id == assignedTilesetId;
      final isScopeAssignable = assignableIds.contains(tileset.id);
      final assignment = _assignmentFor(
        activeLayerId: activeLayerId,
        activeLayer: activeLayer,
        isAssigned: isAssigned,
        isScopeAssignable: isScopeAssignable,
        layerIsEmpty: layerIsEmpty,
      );
      final isCompatible =
          assignment == MapPaletteAssetAssignmentState.alreadyAssigned ||
              assignment == MapPaletteAssetAssignmentState.canAssign;
      final disabledReason = _disabledReason(assignment);
      if (!showIncompatible && !isCompatible) {
        hiddenIncompatibleCount += 1;
        continue;
      }

      final isRecent = recentIndexById.containsKey(tileset.id);
      final isFavorite = favoriteIds.contains(tileset.id);
      if (collection == EditorPaletteAssetCollection.recent && !isRecent) {
        continue;
      }
      if (collection == EditorPaletteAssetCollection.favorites && !isFavorite) {
        continue;
      }

      final normalizedFolderId = tileset.folderId?.trim();
      final isUnclassified = normalizedFolderId == null ||
          normalizedFolderId.isEmpty ||
          !folderPathById.containsKey(normalizedFolderId);
      if (folderId == kEditorPaletteUnclassifiedFolderId) {
        if (!isUnclassified) continue;
      } else if (folderId != null &&
          (isUnclassified || !folderIds.contains(normalizedFolderId))) {
        continue;
      }

      final elements =
          elementsByTilesetId[tileset.id] ?? const <ProjectElementEntry>[];
      if (elementCategoryId != null &&
          !elements.any(
            (element) => selectedCategoryIds.contains(element.categoryId),
          )) {
        continue;
      }

      final folderPath =
          isUnclassified ? 'Non classé' : folderPathById[normalizedFolderId]!;
      final categoryLabels = <String>{
        for (final element in elements)
          if (categoryPathById[element.categoryId] case final path?) path,
      }.toList(growable: false)
        ..sort(_compareFolded);
      final scopeLabel = _scopeLabel(project, tileset);
      final searchableLabels = <String>[
        tileset.name,
        folderPath,
        scopeLabel,
        ...tileset.elementGroups.map((group) => group.name),
        ...tileset.paletteEntries.map((entry) => entry.name),
        ...elements.expand(
          (element) => <String>[
            element.name,
            ...element.tags,
            if (categoryPathById[element.categoryId] case final path?) path,
          ],
        ),
      ];
      if (!_matchesTokens(searchableLabels, queryTokens)) {
        continue;
      }

      projected.add(
        MapPaletteAssetBrowserItem(
          tileset: tileset,
          folderPath: folderPath,
          scopeLabel: scopeLabel,
          explicitCategoryLabels: List<String>.unmodifiable(categoryLabels),
          isAssigned: isAssigned,
          isSelected: tileset.id == selectedTilesetId,
          isFavorite: isFavorite,
          isRecent: isRecent,
          isScopeAssignable: isScopeAssignable,
          isCompatible: isCompatible,
          canAssign: assignment == MapPaletteAssetAssignmentState.canAssign,
          assignmentState: assignment,
          disabledReason: disabledReason,
        ),
      );
    }

    if (collection == EditorPaletteAssetCollection.recent) {
      projected.sort((a, b) {
        final aIndex = recentIndexById[a.tileset.id] ?? 1 << 30;
        final bIndex = recentIndexById[b.tileset.id] ?? 1 << 30;
        return aIndex.compareTo(bIndex);
      });
    }

    return MapPaletteAssetBrowserProjection(
      status: status,
      activeLayerName: activeLayer?.name,
      assignedTilesetId: assignedTilesetId,
      selectedTilesetId: selectedTilesetId,
      folders: List<MapPaletteAssetFolderRow>.unmodifiable(folders),
      categories: List<MapPaletteAssetCategoryRow>.unmodifiable(categories),
      items: List<MapPaletteAssetBrowserItem>.unmodifiable(projected),
      hiddenIncompatibleCount: hiddenIncompatibleCount,
      hasUnclassifiedSources: _hasUnclassifiedSources(project),
      diagnostic: diagnostic,
    );
  }

  bool _hasUnclassifiedSources(ProjectManifest project) {
    final declaredFolderIds =
        project.tilesetFolders.map((folder) => folder.id).toSet();
    return project.tilesets.any((tileset) {
      final id = tileset.folderId?.trim();
      return id == null || id.isEmpty || !declaredFolderIds.contains(id);
    });
  }

  MapPaletteAssetAssignmentState _assignmentFor({
    required String? activeLayerId,
    required MapLayer? activeLayer,
    required bool isAssigned,
    required bool isScopeAssignable,
    required bool layerIsEmpty,
  }) {
    if (activeLayerId == null) {
      return MapPaletteAssetAssignmentState.noLayer;
    }
    if (activeLayer == null) {
      return MapPaletteAssetAssignmentState.layerMissing;
    }
    if (activeLayer is! TileLayer) {
      return MapPaletteAssetAssignmentState.layerNotTile;
    }
    if (isAssigned) {
      return MapPaletteAssetAssignmentState.alreadyAssigned;
    }
    if (!isScopeAssignable) {
      return MapPaletteAssetAssignmentState.outsideMapScope;
    }
    if (!layerIsEmpty) {
      return MapPaletteAssetAssignmentState.layerNotEmpty;
    }
    return MapPaletteAssetAssignmentState.canAssign;
  }

  String? _disabledReason(MapPaletteAssetAssignmentState state) {
    return switch (state) {
      MapPaletteAssetAssignmentState.alreadyAssigned ||
      MapPaletteAssetAssignmentState.canAssign =>
        null,
      MapPaletteAssetAssignmentState.noMap =>
        'Aucune carte active ne peut recevoir cette source.',
      MapPaletteAssetAssignmentState.noLayer =>
        'Sélectionnez un calque avant de choisir cette source.',
      MapPaletteAssetAssignmentState.layerMissing =>
        'Le calque actif n’existe plus.',
      MapPaletteAssetAssignmentState.layerNotTile =>
        'Cette source nécessite un calque de tuiles.',
      MapPaletteAssetAssignmentState.outsideMapScope =>
        'Cette source appartient à un autre groupe de cartes.',
      MapPaletteAssetAssignmentState.layerNotEmpty =>
        'Ce calque contient déjà des tuiles d’une autre source.',
    };
  }

  String? _assignedTilesetId(MapData map, TileLayer layer) {
    final layerId = layer.tilesetId?.trim();
    if (layerId != null && layerId.isNotEmpty) return layerId;
    final mapId = map.tilesetId.trim();
    return mapId.isEmpty ? null : mapId;
  }

  List<MapPaletteAssetFolderRow> _folderRows(ProjectManifest project) {
    final rows = flattenTilesetFoldersForPicker(project);
    final nameById = <String, String>{
      for (final folder in project.tilesetFolders) folder.id: folder.name,
    };
    return rows
        .map(
          (row) => MapPaletteAssetFolderRow(
            id: row.id,
            name: nameById[row.id] ?? row.label,
            path: row.label,
            depth: ' / '.allMatches(row.label).length,
          ),
        )
        .toList(growable: false);
  }

  List<MapPaletteAssetCategoryRow> _categoryRows(ProjectManifest project) {
    final categories = project.elementCategories.toList(growable: false);
    final output = <MapPaletteAssetCategoryRow>[];

    void walk(String? parentId, String prefix, int depth) {
      final children = categories
          .where((category) => category.parentCategoryId == parentId)
          .toList(growable: false)
        ..sort((a, b) {
          final order = a.sortOrder.compareTo(b.sortOrder);
          if (order != 0) return order;
          final name = _compareFolded(a.name, b.name);
          if (name != 0) return name;
          return a.id.compareTo(b.id);
        });
      for (final category in children) {
        final path =
            prefix.isEmpty ? category.name : '$prefix / ${category.name}';
        output.add(
          MapPaletteAssetCategoryRow(
            id: category.id,
            name: category.name,
            path: path,
            depth: depth,
          ),
        );
        walk(category.id, path, depth + 1);
      }
    }

    walk(null, '', 0);
    return output;
  }

  Set<String> _categorySubtreeIds(
    ProjectManifest project,
    String rootId,
  ) {
    final byParent = <String?, List<ProjectElementCategory>>{};
    for (final category in project.elementCategories) {
      byParent
          .putIfAbsent(
            category.parentCategoryId,
            () => <ProjectElementCategory>[],
          )
          .add(category);
    }
    final ids = <String>{};
    void walk(String id) {
      if (!ids.add(id)) return;
      for (final child in byParent[id] ?? const <ProjectElementCategory>[]) {
        walk(child.id);
      }
    }

    walk(rootId);
    return ids;
  }

  String _scopeLabel(ProjectManifest project, ProjectTilesetEntry tileset) {
    if (tileset.scope == TilesetScope.global) return 'Toutes les cartes';
    final groupId = tileset.groupId;
    if (groupId == null) return 'Groupe non défini';
    for (final group in project.groups) {
      if (group.id == groupId) return 'Groupe : ${group.name}';
    }
    return 'Groupe inconnu';
  }

  List<String> _tokens(String query) {
    return _fold(query)
        .split(RegExp(r'\s+'))
        .where((token) => token.isNotEmpty)
        .toList(growable: false);
  }

  bool _matchesTokens(List<String> labels, List<String> tokens) {
    if (tokens.isEmpty) return true;
    final haystack = _fold(labels.join(' '));
    return tokens.every(haystack.contains);
  }

  int _compareFolded(String a, String b) => _fold(a).compareTo(_fold(b));

  String _fold(String value) {
    var folded = value.trim().toLowerCase();
    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'â': 'a',
      'ä': 'a',
      'ã': 'a',
      'å': 'a',
      'ç': 'c',
      'è': 'e',
      'é': 'e',
      'ê': 'e',
      'ë': 'e',
      'ì': 'i',
      'í': 'i',
      'î': 'i',
      'ï': 'i',
      'ñ': 'n',
      'ò': 'o',
      'ó': 'o',
      'ô': 'o',
      'ö': 'o',
      'õ': 'o',
      'ù': 'u',
      'ú': 'u',
      'û': 'u',
      'ü': 'u',
      'ý': 'y',
      'ÿ': 'y',
      'œ': 'oe',
      'æ': 'ae',
    };
    for (final entry in replacements.entries) {
      folded = folded.replaceAll(entry.key, entry.value);
    }
    return folded;
  }
}
