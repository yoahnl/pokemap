import '../models/border_blueprint.dart';
import '../models/border_catalog.dart';
import '../models/border_ground_variant_role.dart';
import '../models/border_visual_snapshot.dart';
import '../models/smart_tile.dart';
import 'border_blueprint_json_codec.dart';
import 'border_snapshot_content_fingerprint.dart';
import 'project_border_catalog_json_codec.dart';
import 'resource_pack_dependency_graph.dart';

BorderBlueprintDraft reconstructResourcePackBorderDraft(
  BorderBlueprintRevision published,
) {
  final definition = published.definition;
  final ground = definition.ground;
  return BorderBlueprintDraft(
    baseRevision: published.revision,
    definition: BorderBlueprintDraftDefinition(
      name: definition.name,
      previewSeed: definition.previewSeed,
      template: definition.template,
      straightOnly: definition.straightOnly,
      followContourDirection: definition.followContourDirection,
      replacesGround: definition.replacesGround,
      masksGroundCells: definition.masksGroundCells,
      groundBaseOffset: definition.groundBaseOffset,
      primitives: [
        for (final primitive in definition.primitives)
          BorderPrimitiveDraft(
            id: primitive.id,
            sourceElementId: primitive.sourceElementId,
            sourceModelId: primitive.sourceModelId,
            role: primitive.role,
            authoredOrientation: primitive.authoredOrientation,
            cornerTurn: primitive.cornerTurn,
            weight: primitive.weight,
            anchorPx: primitive.isSpatial ? null : primitive.anchorPx,
            anchorWorld: primitive.anchorWorld,
            animationIndex: primitive.animationIndex,
            animationLoop: primitive.animationLoop,
            animationSpeed: primitive.animationSpeed,
            blocksMovement: primitive.blocksMovement,
            groundFootprints: primitive.groundFootprints,
            groundSurfaces: primitive.groundSurfaces,
            transforms: primitive.transforms,
            currentMetrics: primitive.isSpatial
                ? null
                : primitive.publishedMetrics,
          ),
      ],
      defaults: definition.defaults,
      ground: ground == null
          ? null
          : BorderGroundDraft(
              sourceSmartTilePresetId: ground.sourceSmartTilePresetId,
              edgeBandCells: ground.edgeBandCells,
            ),
      categoryId: definition.categoryId,
      sortOrder: definition.sortOrder,
      jumpBehavior: definition.jumpBehavior,
    ),
  );
}

BorderBlueprintRecord projectResourcePackPublishedBorder({
  required BorderBlueprintRecord record,
  required List<BorderVisualSnapshot> snapshots,
  required Map<String, List<BorderSnapshotContentFrame>> primitiveSourceFrames,
  Map<BorderGroundVariantRole, List<BorderSnapshotContentFrame>>
      groundSourceFrames =
      const {},
}) {
  final published = record.latestPublished;
  if (published == null) {
    throw const FormatException('border.publication_missing');
  }
  final snapshotsById = {
    for (final snapshot in snapshots) snapshot.id: snapshot,
  };
  void requireSnapshot(
    String snapshotId,
    List<BorderSnapshotContentFrame>? sourceFrames,
  ) {
    final snapshot = snapshotsById[snapshotId];
    if (snapshot == null ||
        sourceFrames == null ||
        sourceFrames.isEmpty ||
        computeBorderSnapshotContentFingerprint(frames: sourceFrames) !=
            snapshot.contentFingerprint) {
      throw FormatException(
        'border.source_publication_mismatch: ${record.id}: $snapshotId',
      );
    }
  }

  for (final primitive in published.definition.primitives) {
    if (!primitive.isSpatial) {
      requireSnapshot(
        primitive.visualSnapshotId,
        primitiveSourceFrames[primitive.id],
      );
    }
  }
  final ground = published.definition.ground;
  if (ground != null) {
    for (final entry in ground.visualSnapshotIdsByRole.entries) {
      requireSnapshot(entry.value, groundSourceFrames[entry.key]);
    }
  }
  return BorderBlueprintRecord(
    id: record.id,
    draft: reconstructResourcePackBorderDraft(published),
    latestPublished: published,
    isDeprecated: record.isDeprecated,
  );
}

Map<String, Object?> encodeResourcePackBorderCatalog(
  ProjectBorderCatalog catalog,
) {
  final json = encodeProjectBorderCatalogJson(catalog);
  json['records'] = [
    for (final record in catalog.records)
      {
        'id': record.id,
        'latestPublished': encodeBorderBlueprintRevisionJson(
          record.latestPublished!,
          formatVersion: catalog.formatVersion,
        ),
        if (record.isDeprecated) 'isDeprecated': true,
      },
  ];
  return json;
}

ProjectBorderCatalog decodeResourcePackBorderCatalog(
  Map<String, dynamic> json,
) {
  if (json['records'] is! List) {
    throw const FormatException('pack.borderCatalog.records: expected list');
  }
  final records = <Map<String, Object?>>[];
  for (final raw in json['records'] as List) {
    if (raw is! Map ||
        raw.keys.any(
          (k) => !{'id', 'latestPublished', 'isDeprecated'}.contains(k),
        )) {
      throw const FormatException(
        'pack.borderCatalog: unsupported record field',
      );
    }
    final record = Map<String, Object?>.from(raw);
    final published = record['latestPublished'];
    if (published is! Map || published['definition'] is! Map) {
      throw const FormatException('pack.borderCatalog: publication required');
    }
    final definition = Map<String, Object?>.from(
      published['definition'] as Map,
    );
    if (definition['primitives'] is! List) {
      throw const FormatException('pack.borderCatalog: primitives required');
    }
    definition['primitives'] = [
      for (final primitive in definition['primitives'] as List)
        _draftPrimitiveJson(primitive),
    ];
    final ground = definition['ground'];
    if (ground != null) {
      if (ground is! Map) {
        throw const FormatException('pack.borderCatalog: invalid ground');
      }
      definition['ground'] = Map<String, Object?>.from(ground)
        ..remove('visualSnapshotIdsByRole');
    }
    record['draft'] = {
      'baseRevision': published['revision'],
      'definition': definition,
    };
    records.add(record);
  }
  return decodeProjectBorderCatalogJson({...json, 'records': records});
}

Map<String, Object?> _draftPrimitiveJson(Object? value) {
  if (value is! Map) {
    throw const FormatException('pack.borderCatalog: invalid primitive');
  }
  final json = Map<String, Object?>.from(value)..remove('visualSnapshotId');
  if (json.containsKey('publishedMetrics')) {
    json['currentMetrics'] = json.remove('publishedMetrics');
  }
  return json;
}

ProjectSmartTileAuthoringDraft reconstructResourcePackSmartTileDraft({
  required ProjectSmartTilePreset preset,
  required ProjectSmartTileCatalog catalog,
}) {
  if (preset.status != SmartTilePresetStatus.published) {
    throw const FormatException('smart_tile.publication_missing');
  }
  final animationIds = <String>{};
  final atlasIds = <String>{};
  for (final rule in preset.rules) {
    for (final candidate in rule.candidates) {
      for (final part in candidate.parts) {
        switch (part.source) {
          case SmartTileFrameSource(:final frame):
            atlasIds.add(frame.atlasId);
          case SmartTileAnimationSource(:final animationId):
            animationIds.add(animationId);
          case SmartTileModel3dSource():
            break;
        }
      }
    }
  }
  final animations = catalog.animations
      .where((a) => animationIds.contains(a.id))
      .toList();
  for (final animation in animations) {
    atlasIds.addAll(animation.frames.map((f) => f.frame.atlasId));
  }
  final atlases = catalog.atlases
      .where((a) => atlasIds.contains(a.id))
      .toList();
  final materialIds = smartTilePresetMaterialIds(preset);
  return ProjectSmartTileAuthoringDraft(
    id: 'source-${preset.id}',
    targetPresetId: preset.id,
    sourcePresetId: preset.id,
    name: preset.name,
    categoryId: preset.categoryId,
    usage: preset.usage,
    lastStage: SmartTileAuthoringStage.connections,
    sourceTilesetIds: atlases.map((a) => a.tilesetId).toSet().toList(),
    atlases: atlases,
    primaryAtlasId: atlases.firstOrNull?.id,
    materials: catalog.materials
        .where((m) => materialIds.contains(m.id))
        .toList(),
    animations: animations,
    defaultMaterialId: preset.defaultMaterialId,
    allowedMaterialIds: preset.allowedMaterialIds,
    topology: preset.topology,
    templateHint: preset.templateHint,
    boundaryPolicy: preset.boundaryPolicy,
    coveragePolicy: preset.coveragePolicy,
    coverageProfile: preset.coverageProfile,
    transformPolicy: preset.transformPolicy,
    rules: preset.rules,
    fallbackRuleId: preset.fallbackRuleId,
    tags: preset.tags,
    sortOrder: preset.sortOrder,
    seedSalt: preset.seedSalt,
  );
}

ProjectSmartTileCatalog remapResourcePackConnectionGroups(
  ProjectSmartTileCatalog catalog,
  Map<String, String> mapping,
) {
  return ProjectSmartTileCatalog(
    categories: catalog.categories,
    atlases: catalog.atlases,
    materials: [
      for (final material in catalog.materials)
        material.copyWith(
          connectionGroupId:
              mapping[material.connectionGroupId] ??
              (throw FormatException(
                'pack.mapping_missing: ${material.connectionGroupId}',
              )),
        ),
    ],
    animations: catalog.animations,
    presets: catalog.presets,
    patterns: catalog.patterns,
    drafts: catalog.drafts,
  );
}
