import 'dart:convert';

import '../catalog_storage/catalog_storage.dart';

import '../models/environment.dart';
import '../models/project_tileset_source.dart';
import '../models/resource_pack.dart';
import '../models/resource_pack_catalog.dart';
import '../models/resource_pack_installation_catalog.dart';
import '../models/smart_tile.dart';

final class ResourcePackSupportRef {
  ResourcePackSupportRef({required this.kind, required this.id, this.owner}) {
    ResourcePackRef(kind: ResourcePackKind.element, id: id);
    if ((kind == ResourcePackSupportKind.tilesetElementGroup) !=
            (owner != null) ||
        (owner != null && owner!.kind != ResourcePackKind.tileset)) {
      throw const FormatException('pack.support: invalid owner');
    }
  }
  final ResourcePackSupportKind kind;
  final String id;
  final ResourcePackRef? owner;
  String get identity => jsonEncode([kind.name, owner?.identity, id]);
  @override
  bool operator ==(Object other) =>
      other is ResourcePackSupportRef && identity == other.identity;
  @override
  int get hashCode => identity.hashCode;
}

final class ResourcePackNodeRef {
  ResourcePackNodeRef.resource(ResourcePackRef value)
    : resource = value,
      support = null,
      fileId = null;
  ResourcePackNodeRef.support(ResourcePackSupportRef value)
    : resource = null,
      support = value,
      fileId = null;
  ResourcePackNodeRef.file(String value)
    : resource = null,
      support = null,
      fileId = value {
    ResourcePackRef(kind: ResourcePackKind.element, id: value);
  }
  final ResourcePackRef? resource;
  final ResourcePackSupportRef? support;
  final String? fileId;
  String get identity =>
      jsonEncode([resource?.identity, support?.identity, fileId]);
  @override
  bool operator ==(Object other) =>
      other is ResourcePackNodeRef && identity == other.identity;
  @override
  int get hashCode => identity.hashCode;
  @override
  String toString() => identity;
}

final class ResourcePackDependencyNode {
  ResourcePackDependencyNode({
    required this.reference,
    Iterable<ResourcePackNodeRef> dependencies = const [],
  }) : dependencies = List.unmodifiable(
         dependencies.toSet().toList()
           ..sort((a, b) => a.identity.compareTo(b.identity)),
       );
  final ResourcePackNodeRef reference;
  final List<ResourcePackNodeRef> dependencies;
}

final class ResourcePackDependencyException implements Exception {
  const ResourcePackDependencyException(
    this.code,
    this.reference, {
    this.owner,
  });
  final String code;
  final ResourcePackNodeRef reference;
  final ResourcePackNodeRef? owner;
  @override
  String toString() => '$code: $reference (from $owner)';
}

final class ResourcePackClosure {
  ResourcePackClosure._(
    Iterable<ResourcePackNodeRef> references,
    Map<ResourcePackNodeRef, ResourcePackNodeRef> representatives,
  ) : nodes = List.unmodifiable(
        references.toList()..sort((a, b) => a.identity.compareTo(b.identity)),
      ),
      representativeRoots = Map.unmodifiable(representatives);
  final List<ResourcePackNodeRef> nodes;
  final Map<ResourcePackNodeRef, ResourcePackNodeRef> representativeRoots;
  List<ResourcePackRef> get resources => List.unmodifiable(
    nodes.map((e) => e.resource).whereType<ResourcePackRef>().toList()
      ..sort((a, b) => a.identity.compareTo(b.identity)),
  );
  List<ResourcePackSupportRef> get supports => List.unmodifiable(
    nodes.map((e) => e.support).whereType<ResourcePackSupportRef>().toList()
      ..sort((a, b) => a.identity.compareTo(b.identity)),
  );
  List<String> get files => List.unmodifiable(
    nodes.map((e) => e.fileId).whereType<String>().toList()..sort(),
  );
}

final class ResourcePackDependencyGraph {
  ResourcePackDependencyGraph({
    required Iterable<ResourcePackDependencyNode> nodes,
  }) : _nodes = {} {
    for (final node in nodes) {
      if (_nodes.containsKey(node.reference)) {
        throw FormatException('pack.graph: duplicate ${node.reference}');
      }
      _nodes[node.reference] = node;
    }
  }
  factory ResourcePackDependencyGraph.fromCatalog(ResourcePackCatalog catalog) {
    final nodes = ResourcePackReferenceVisitor(catalog).nodes();
    final byReference = {for (final node in nodes) node.reference: node};
    final declarations = <ResourcePackNodeRef, Set<ResourcePackNodeRef>>{};
    for (final declaration in catalog.dynamicDependencies) {
      final owner = resourcePackNodeForCatalogKey(declaration.owner);
      final targets = declaration.targets
          .map(resourcePackNodeForCatalogKey)
          .toSet();
      if (declarations.containsKey(owner) ||
          !byReference.containsKey(owner) ||
          targets.any((target) => !byReference.containsKey(target))) {
        throw const FormatException(
          'catalog.dynamic: duplicate declaration, missing owner or target',
        );
      }
      declarations[owner] = targets;
    }
    return ResourcePackDependencyGraph(
      nodes: [
        for (final node in nodes)
          ResourcePackDependencyNode(
            reference: node.reference,
            dependencies: [
              ...node.dependencies,
              ...?declarations[node.reference],
            ],
          ),
      ],
    );
  }
  final Map<ResourcePackNodeRef, ResourcePackDependencyNode> _nodes;
  List<ResourcePackDependencyNode> get nodes =>
      List.unmodifiable(_nodes.values);

  ResourcePackClosure closure({
    required Iterable<ResourcePackRef> roots,
    Iterable<String> smartTilePatternIds = const [],
  }) {
    final selected = <ResourcePackNodeRef>{
      for (final root in roots) ResourcePackNodeRef.resource(root),
      for (final id in smartTilePatternIds)
        ResourcePackNodeRef.support(
          ResourcePackSupportRef(
            kind: ResourcePackSupportKind.smartTilePattern,
            id: id,
          ),
        ),
    };
    return _traverse(selected);
  }

  ResourcePackClosure validateAll() => _traverse(_nodes.keys);

  ResourcePackClosure _traverse(Iterable<ResourcePackNodeRef> references) {
    final selected = references.toSet().toList()
      ..sort((a, b) => a.identity.compareTo(b.identity));
    final done = <ResourcePackNodeRef>{};
    final active = <ResourcePackNodeRef>{};
    final representatives = <ResourcePackNodeRef, ResourcePackNodeRef>{};
    for (final root in selected) {
      if (done.contains(root)) continue;
      final stack = <_TraversalFrame>[_TraversalFrame(root)];
      while (stack.isNotEmpty) {
        final frame = stack.last;
        representatives.putIfAbsent(frame.reference, () => root);
        final node = _nodes[frame.reference];
        if (node == null) {
          throw ResourcePackDependencyException(
            'pack.reference_missing',
            frame.reference,
            owner: stack.length > 1 ? stack[stack.length - 2].reference : null,
          );
        }
        active.add(frame.reference);
        if (frame.index == node.dependencies.length) {
          stack.removeLast();
          active.remove(frame.reference);
          done.add(frame.reference);
          continue;
        }
        final child = node.dependencies[frame.index++];
        if (done.contains(child)) continue;
        if (active.contains(child)) {
          throw ResourcePackDependencyException(
            'pack.dependency_cycle',
            child,
            owner: frame.reference,
          );
        }
        stack.add(_TraversalFrame(child));
      }
    }
    return ResourcePackClosure._(done, representatives);
  }
}

final class _TraversalFrame {
  _TraversalFrame(this.reference);
  final ResourcePackNodeRef reference;
  int index = 0;
}

final class ResourcePackReferenceVisitor {
  const ResourcePackReferenceVisitor(this.catalog);
  final ResourcePackCatalog catalog;

  List<ResourcePackDependencyNode> nodes() {
    final nodes = <ResourcePackDependencyNode>[];
    final classifications = {
      for (final entry in catalog.resourceLibraryCatalog.entries)
        entry.identity: entry,
    };
    final filesByPath = {
      for (final file in catalog.files) file.logicalPath: file.id,
    };
    final snapshotsById = {
      for (final snapshot in catalog.borderCatalog.visualSnapshots)
        snapshot.id: snapshot,
    };
    String fileForPath(String path) =>
        filesByPath[path] ??
        (throw FormatException('pack.reference_missing: file path $path'));
    void add(
      ResourcePackNodeRef ref,
      Iterable<ResourcePackNodeRef> dependencies,
    ) => nodes.add(
      ResourcePackDependencyNode(reference: ref, dependencies: dependencies),
    );
    ResourcePackNodeRef resource(ResourcePackKind kind, String id) =>
        ResourcePackNodeRef.resource(ResourcePackRef(kind: kind, id: id));
    ResourcePackNodeRef support(
      ResourcePackSupportKind kind,
      String id, [
      ResourcePackRef? owner,
    ]) => ResourcePackNodeRef.support(
      ResourcePackSupportRef(kind: kind, id: id, owner: owner),
    );
    Iterable<ResourcePackNodeRef> classification(
      ResourcePackKind kind,
      String id,
    ) sync* {
      final family = classifications['${kind.name}:$id']?.familyId;
      if (family != null) {
        yield support(ResourcePackSupportKind.resourceFamily, family);
      }
    }

    for (final file in catalog.files) {
      add(ResourcePackNodeRef.file(file.id), []);
    }
    for (final family in catalog.resourceLibraryCatalog.effectiveFamilies) {
      add(support(ResourcePackSupportKind.resourceFamily, family.id), [
        if (family.parentId != null)
          support(ResourcePackSupportKind.resourceFamily, family.parentId!),
      ]);
    }
    for (final category in catalog.elementCategories) {
      add(support(ResourcePackSupportKind.elementCategory, category.id), [
        if (category.parentCategoryId != null)
          support(
            ResourcePackSupportKind.elementCategory,
            category.parentCategoryId!,
          ),
      ]);
    }
    for (final folder in catalog.tilesetFolders) {
      add(support(ResourcePackSupportKind.tilesetFolder, folder.id), [
        if (folder.parentFolderId != null)
          support(
            ResourcePackSupportKind.tilesetFolder,
            folder.parentFolderId!,
          ),
      ]);
    }
    for (final tileset in catalog.tilesets) {
      final owner = ResourcePackRef(
        kind: ResourcePackKind.tileset,
        id: tileset.id,
      );
      final dependencies = <ResourcePackNodeRef>[
        ...classification(ResourcePackKind.tileset, tileset.id),
        if (tileset.folderId != null)
          support(ResourcePackSupportKind.tilesetFolder, tileset.folderId!),
        for (final group in tileset.elementGroups)
          support(ResourcePackSupportKind.tilesetElementGroup, group.id, owner),
        for (final entry in tileset.paletteEntries)
          for (final frame in entry.frames)
            if (frame.tilesetId.isNotEmpty && frame.tilesetId != tileset.id)
              resource(ResourcePackKind.tileset, frame.tilesetId),
      ];
      switch (tileset.source) {
        case ProjectRegularAtlasTilesetSource(:final assetId):
          dependencies.add(ResourcePackNodeRef.file(assetId));
        case ProjectImageCollectionTilesetSource(
          :final pages,
          :final properties,
          :final tileDefinitions,
        ):
          dependencies.addAll(
            pages.map((p) => ResourcePackNodeRef.file(p.assetId)),
          );
          final objectIdCounts = <int, int>{};
          for (final tile in tileDefinitions) {
            for (final collision in tile.collisionObjects) {
              objectIdCounts.update(
                collision.id,
                (count) => count + 1,
                ifAbsent: () => 1,
              );
            }
          }
          final uniqueSourceObjectIds = {
            for (final entry in objectIdCounts.entries)
              if (entry.value == 1) entry.key,
          };
          dependencies.addAll(
            _properties(properties, objectIds: uniqueSourceObjectIds),
          );
          final pageIds = pages.map((page) => page.id).toSet();
          for (final tile in tileDefinitions) {
            if (!pageIds.contains(tile.pageId)) {
              throw FormatException(
                'pack.reference_missing: tileset page ${tile.pageId}',
              );
            }
            final objectIds = tile.collisionObjects
                .map((object) => object.id)
                .toSet();
            if (objectIds.length != tile.collisionObjects.length) {
              throw const FormatException(
                'pack.property: duplicate collision object identity in tile',
              );
            }
            dependencies.addAll(
              _properties(tile.properties, objectIds: objectIds),
            );
            for (final collision in tile.collisionObjects) {
              dependencies.addAll(
                _properties(collision.properties, objectIds: objectIds),
              );
            }
          }
        case null:
          throw const FormatException('pack.tileset_source_missing');
      }
      add(resource(ResourcePackKind.tileset, tileset.id), dependencies);
      for (final group in tileset.elementGroups) {
        add(
          support(ResourcePackSupportKind.tilesetElementGroup, group.id, owner),
          [
            if (group.parentGroupId != null)
              support(
                ResourcePackSupportKind.tilesetElementGroup,
                group.parentGroupId!,
                owner,
              ),
          ],
        );
      }
    }
    for (final element in catalog.elements) {
      add(resource(ResourcePackKind.element, element.id), [
        ...classification(ResourcePackKind.element, element.id),
        resource(ResourcePackKind.tileset, element.tilesetId),
        if (element.categoryId.isNotEmpty)
          support(ResourcePackSupportKind.elementCategory, element.categoryId),
        if (element.tilesetGroupId != null)
          support(
            ResourcePackSupportKind.tilesetElementGroup,
            element.tilesetGroupId!,
            ResourcePackRef(
              kind: ResourcePackKind.tileset,
              id: element.tilesetId,
            ),
          ),
        for (final frame in element.frames)
          if (frame.tilesetId.isNotEmpty)
            resource(ResourcePackKind.tileset, frame.tilesetId),
      ]);
    }
    for (final model in catalog.models3d) {
      add(resource(ResourcePackKind.model3d, model.id), [
        ...classification(ResourcePackKind.model3d, model.id),
        ResourcePackNodeRef.file(model.sourceAssetId),
      ]);
    }
    for (final preset in catalog.environmentPresets) {
      add(resource(ResourcePackKind.environmentPreset, preset.id), [
        ...classification(ResourcePackKind.environmentPreset, preset.id),
        if (preset.categoryId != null)
          support(ResourcePackSupportKind.elementCategory, preset.categoryId!),
        for (final item in preset.palette)
          if (item.visualKind == EnvironmentVisualKind.element)
            resource(ResourcePackKind.element, item.elementId!)
          else
            resource(ResourcePackKind.model3d, item.modelId!),
      ]);
    }
    for (final state in catalog.characterStudioCatalog.portraitStates) {
      add(
        support(ResourcePackSupportKind.characterPortraitState, state.id),
        [],
      );
    }
    for (final animation
        in catalog.characterStudioCatalog.customAnimationDefinitions) {
      add(
        support(
          ResourcePackSupportKind.characterAnimationDefinition,
          animation.id,
        ),
        [],
      );
    }
    for (final character in catalog.characters) {
      add(resource(ResourcePackKind.character, character.id), [
        ...classification(ResourcePackKind.character, character.id),
        resource(ResourcePackKind.tileset, character.tilesetId),
        for (final portrait in character.portraits) ...[
          ResourcePackNodeRef.file(portrait.assetId),
          support(
            ResourcePackSupportKind.characterPortraitState,
            portrait.portraitStateId,
          ),
        ],
        for (final animation in character.animations)
          if (animation.sourceAssetId != null)
            ResourcePackNodeRef.file(animation.sourceAssetId!),
        for (final animation in character.customAnimations) ...[
          ResourcePackNodeRef.file(animation.sourceAssetId),
          support(
            ResourcePackSupportKind.characterAnimationDefinition,
            animation.definitionId,
          ),
        ],
      ]);
    }
    for (final category in catalog.smartTileCatalog.categories) {
      add(support(ResourcePackSupportKind.smartTileCategory, category.id), []);
    }
    for (final group
        in catalog.smartTileCatalog.materials
            .map((m) => m.connectionGroupId)
            .toSet()) {
      add(support(ResourcePackSupportKind.smartTileConnectionGroup, group), []);
    }
    for (final material in catalog.smartTileCatalog.materials) {
      add(support(ResourcePackSupportKind.smartTileMaterial, material.id), [
        support(
          ResourcePackSupportKind.smartTileConnectionGroup,
          material.connectionGroupId,
        ),
        if (material.categoryId.isNotEmpty)
          support(
            ResourcePackSupportKind.smartTileCategory,
            material.categoryId,
          ),
      ]);
    }
    for (final atlas in catalog.smartTileCatalog.atlases) {
      add(support(ResourcePackSupportKind.smartTileAtlas, atlas.id), [
        resource(ResourcePackKind.tileset, atlas.tilesetId),
      ]);
    }
    for (final animation in catalog.smartTileCatalog.animations) {
      add(support(ResourcePackSupportKind.smartTileAnimation, animation.id), [
        for (final frame in animation.frames)
          support(ResourcePackSupportKind.smartTileAtlas, frame.frame.atlasId),
      ]);
    }
    for (final preset in catalog.smartTileCatalog.presets) {
      add(resource(ResourcePackKind.smartTilePreset, preset.id), [
        ...classification(ResourcePackKind.smartTilePreset, preset.id),
        if (preset.categoryId.isNotEmpty)
          support(ResourcePackSupportKind.smartTileCategory, preset.categoryId),
        for (final id in smartTilePresetMaterialIds(preset))
          support(ResourcePackSupportKind.smartTileMaterial, id),
        for (final rule in preset.rules)
          for (final candidate in rule.candidates) ..._parts(candidate.parts),
      ]);
    }
    for (final pattern in catalog.smartTileCatalog.patterns) {
      add(support(ResourcePackSupportKind.smartTilePattern, pattern.id), [
        if (pattern.categoryId.isNotEmpty)
          support(
            ResourcePackSupportKind.smartTileCategory,
            pattern.categoryId,
          ),
        for (final cell in pattern.cells) ..._parts(cell.parts),
      ]);
    }
    for (final snapshot in catalog.borderCatalog.visualSnapshots) {
      add(
        support(
          ResourcePackSupportKind.borderSnapshot,
          resourcePackBorderSnapshotAlias(snapshot.contentFingerprint),
        ),
        [
          for (final frame in snapshot.frames)
            ResourcePackNodeRef.file(fileForPath(frame.relativeAssetPath)),
        ],
      );
    }
    for (final record in catalog.borderCatalog.records) {
      final definition = record.latestPublished!.definition;
      ResourcePackNodeRef snapshot(String id) {
        final match = snapshotsById[id];
        if (match == null) {
          throw FormatException('pack.reference_missing: border snapshot $id');
        }
        return support(
          ResourcePackSupportKind.borderSnapshot,
          resourcePackBorderSnapshotAlias(match.contentFingerprint),
        );
      }

      final ground = definition.ground;
      add(resource(ResourcePackKind.borderBlueprint, record.id), [
        ...classification(ResourcePackKind.borderBlueprint, record.id),
        if (definition.categoryId != null)
          support(
            ResourcePackSupportKind.elementCategory,
            definition.categoryId!,
          ),
        for (final primitive in definition.primitives) ...[
          if (primitive.isSpatial)
            resource(ResourcePackKind.model3d, primitive.sourceModelId!)
          else ...[
            resource(ResourcePackKind.element, primitive.sourceElementId!),
            snapshot(primitive.visualSnapshotId),
          ],
          for (final surface in primitive.groundSurfaces) ...[
            resource(
              ResourcePackKind.smartTilePreset,
              surface.sourceSmartTilePresetId,
            ),
            support(
              ResourcePackSupportKind.smartTileMaterial,
              surface.materialId,
            ),
          ],
        ],
        if (ground != null) ...[
          resource(
            ResourcePackKind.smartTilePreset,
            ground.sourceSmartTilePresetId,
          ),
          for (final id in ground.visualSnapshotIdsByRole.values) snapshot(id),
        ],
      ]);
    }
    return List.unmodifiable(nodes);
  }

  Iterable<ResourcePackNodeRef> _properties(
    List<ProjectTilesetProperty> properties, {
    required Set<int> objectIds,
  }) sync* {
    for (final property in properties) {
      switch (property.type) {
        case ProjectTilesetPropertyType.assetReference:
          if (property.value is! String) {
            throw const FormatException(
              'pack.property: asset reference must be file id',
            );
          }
          yield ResourcePackNodeRef.file(property.value! as String);
        case ProjectTilesetPropertyType.objectReference:
          if (property.value is! int || !objectIds.contains(property.value)) {
            throw const FormatException(
              'pack.property_reference_outside_closure',
            );
          }
        case ProjectTilesetPropertyType.structured:
          throw const FormatException('pack.property_reference_unsupported');
        default:
          break;
      }
    }
  }
}

String resourcePackBorderSnapshotAlias(String contentFingerprint) =>
    'snapshot_$contentFingerprint';

Iterable<ResourcePackNodeRef> _parts(List<SmartTileVisualPart> parts) sync* {
  for (final part in parts) {
    yield switch (part.source) {
      SmartTileFrameSource(:final frame) => ResourcePackNodeRef.support(
        ResourcePackSupportRef(
          kind: ResourcePackSupportKind.smartTileAtlas,
          id: frame.atlasId,
        ),
      ),
      SmartTileAnimationSource(:final animationId) =>
        ResourcePackNodeRef.support(
          ResourcePackSupportRef(
            kind: ResourcePackSupportKind.smartTileAnimation,
            id: animationId,
          ),
        ),
      SmartTileModel3dSource(:final modelId) => ResourcePackNodeRef.resource(
        ResourcePackRef(kind: ResourcePackKind.model3d, id: modelId),
      ),
    };
  }
}

Set<String> smartTilePresetMaterialIds(ProjectSmartTilePreset preset) {
  final ids = <String>{preset.defaultMaterialId, ...preset.allowedMaterialIds};
  void signature(SmartTileSignature value) {
    for (final slot in [
      value.northEdge,
      value.northEastCorner,
      value.eastEdge,
      value.southEastCorner,
      value.southEdge,
      value.southWestCorner,
      value.westEdge,
      value.northWestCorner,
    ]) {
      if (slot.materialId != null) ids.add(slot.materialId!);
    }
  }

  for (final rule in preset.rules) {
    if (rule.centerMatch.materialId != null) {
      ids.add(rule.centerMatch.materialId!);
    }
    signature(rule.signature);
  }
  for (final scenario in preset.coverageProfile.requiredScenarios) {
    if (scenario.centerMaterialId != null) ids.add(scenario.centerMaterialId!);
    final value = scenario.signature;
    ids.addAll(
      [
        value.northEdge,
        value.northEastCorner,
        value.eastEdge,
        value.southEastCorner,
        value.southEdge,
        value.southWestCorner,
        value.westEdge,
        value.northWestCorner,
      ].whereType<String>(),
    );
  }
  return ids;
}

ResourcePackNodeRef resourcePackNodeForCatalogKey(CatalogDefinitionKey key) {
  if (key.kind == CatalogDefinitionKind.fileBinding) {
    return ResourcePackNodeRef.file(key.id);
  }
  final resourceKind = switch (key.kind) {
    CatalogDefinitionKind.tileset => ResourcePackKind.tileset,
    CatalogDefinitionKind.element => ResourcePackKind.element,
    CatalogDefinitionKind.model3d => ResourcePackKind.model3d,
    CatalogDefinitionKind.character => ResourcePackKind.character,
    CatalogDefinitionKind.environmentPreset =>
      ResourcePackKind.environmentPreset,
    CatalogDefinitionKind.smartTilePreset => ResourcePackKind.smartTilePreset,
    CatalogDefinitionKind.borderRecord => ResourcePackKind.borderBlueprint,
    _ => null,
  };
  if (resourceKind != null) {
    return ResourcePackNodeRef.resource(
      ResourcePackRef(kind: resourceKind, id: key.id),
    );
  }
  final supportKind = switch (key.kind) {
    CatalogDefinitionKind.resourceFamily =>
      ResourcePackSupportKind.resourceFamily,
    CatalogDefinitionKind.elementCategory =>
      ResourcePackSupportKind.elementCategory,
    CatalogDefinitionKind.tilesetFolder =>
      ResourcePackSupportKind.tilesetFolder,
    CatalogDefinitionKind.smartTileMaterial =>
      ResourcePackSupportKind.smartTileMaterial,
    CatalogDefinitionKind.smartTileAtlas =>
      ResourcePackSupportKind.smartTileAtlas,
    CatalogDefinitionKind.smartTileAnimation =>
      ResourcePackSupportKind.smartTileAnimation,
    CatalogDefinitionKind.smartTileCategory =>
      ResourcePackSupportKind.smartTileCategory,
    CatalogDefinitionKind.smartTilePattern =>
      ResourcePackSupportKind.smartTilePattern,
    CatalogDefinitionKind.borderVisualSnapshot =>
      ResourcePackSupportKind.borderSnapshot,
    _ => null,
  };
  if (supportKind != null) {
    return ResourcePackNodeRef.support(
      ResourcePackSupportRef(kind: supportKind, id: key.id),
    );
  }
  if (key.kind == CatalogDefinitionKind.characterStudioDefinition) {
    final value = jsonDecode(key.id);
    if (value is! List ||
        value.length != 2 ||
        value[1] is! String ||
        !{
          ResourcePackSupportKind.characterPortraitState.name,
          ResourcePackSupportKind.characterAnimationDefinition.name,
        }.contains(value[0]) ||
        jsonEncode(value) != key.id) {
      throw const FormatException(
        'catalog.dynamic: invalid studio definition key',
      );
    }
    return ResourcePackNodeRef.support(
      ResourcePackSupportRef(
        kind: ResourcePackSupportKind.values.byName(value[0] as String),
        id: value[1] as String,
      ),
    );
  }
  throw const FormatException('catalog.dynamic: unsupported dependency kind');
}
