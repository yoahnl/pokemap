import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_feature.dart';
import '../models/border_geometry.dart';
import '../models/border_materialization.dart';
import '../models/border_resolution.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/surface.dart';
import 'border_rle_codec.dart';
import 'narrative_event_canonical_json.dart';

final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');

/// The six input hashes whose projections do not require snapshot models.
typedef BorderNonVisualInputFingerprints = ({
  String blueprint,
  String geometryAndSeed,
  String parameters,
  String overrides,
  String keepOutRegions,
  String mapContext,
});

/// Computes the seven independently assessable Border V1 input hashes.
BorderInputFingerprints computeBorderInputFingerprints(
  BorderResolutionRequest request,
) {
  final nonVisual = computeBorderNonVisualInputFingerprints(request);
  final visualSnapshots = computeBorderVisualSnapshotsInputFingerprint(request);
  return BorderInputFingerprints(
    blueprint: nonVisual.blueprint,
    geometryAndSeed: nonVisual.geometryAndSeed,
    parameters: nonVisual.parameters,
    overrides: nonVisual.overrides,
    keepOutRegions: nonVisual.keepOutRegions,
    mapContext: nonVisual.mapContext,
    visualSnapshots: visualSnapshots,
  );
}

/// Computes only the snapshot-dependent Border V1 input component.
///
/// This split lets freshness retain already-computed non-visual hashes when a
/// newly referenced snapshot is unavailable, without encoding large region or
/// keep-out masks a second time.
String computeBorderVisualSnapshotsInputFingerprint(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border input fingerprints require a published blueprint revision',
    );
  }
  final definition = revision.definition;
  final referencedSnapshots = _referencedSnapshotIds(
    definition,
    request.feature.overrides,
  );
  final snapshotsById = <String, BorderVisualSnapshot>{
    for (final snapshot in request.visualSnapshots) snapshot.id: snapshot,
  };
  final missingSnapshots = referencedSnapshots
      .where((id) => !snapshotsById.containsKey(id))
      .toList(growable: false)
    ..sort(compareNarrativeEventUtf16);
  if (missingSnapshots.isNotEmpty) {
    throw ValidationException(
      'Missing referenced Border visual snapshot(s): '
      '${missingSnapshots.join(', ')}',
    );
  }

  final referencedSnapshotModels = <BorderVisualSnapshot>[
    for (final id in referencedSnapshots) snapshotsById[id]!,
  ]..sort((left, right) => compareNarrativeEventUtf16(left.id, right.id));
  return _fingerprint(_visualSnapshotsProjection(referencedSnapshotModels));
}

/// Computes the independently comparable hashes that do not need snapshot
/// models to be present.
///
/// Freshness assessment uses this when a newly authored locked override
/// references a missing snapshot: changes to geometry, parameters, overrides,
/// keep-outs, and map context remain detectable while an older materialized
/// output can stay renderable.
BorderNonVisualInputFingerprints computeBorderNonVisualInputFingerprints(
  BorderResolutionRequest request,
) {
  final revision = request.blueprintRevision;
  if (revision == null) {
    throw const ValidationException(
      'Border input fingerprints require a published blueprint revision',
    );
  }
  final definition = revision.definition;
  final effectiveParams = request.feature.paramsOverride ?? definition.defaults;
  return (
    blueprint: _fingerprint(_blueprintProjection(
      blueprintId: request.blueprintId,
      revision: revision,
    )),
    geometryAndSeed: _fingerprint(
      _geometryAndSeedProjection(
        request.feature,
        template: definition.template,
      ),
    ),
    parameters: _fingerprint(_parametersProjection(effectiveParams)),
    overrides: _fingerprint(_overridesProjection(request.feature.overrides)),
    keepOutRegions:
        _fingerprint(_keepOutProjection(request.feature.keepOutRegions)),
    mapContext: _fingerprint(<String, Object?>{
      'mapWidth': _jsonInteger(request.mapSize.width),
      'mapHeight': _jsonInteger(request.mapSize.height),
      'tileWidthPx': _jsonInteger(request.tileSizePx.width),
      'tileHeightPx': _jsonInteger(request.tileSizePx.height),
    }),
  );
}

/// Hashes resolver identity together with the exact seven component hashes.
String computeBorderAggregateInputFingerprint({
  required int resolverVersion,
  required int blueprintRevision,
  required BorderInputFingerprints components,
}) {
  if (resolverVersion < 1) {
    throw const ValidationException('resolverVersion must be >= 1');
  }
  if (blueprintRevision < 1) {
    throw const ValidationException('blueprintRevision must be >= 1');
  }
  return _fingerprint(<String, Object?>{
    'resolverVersion': _jsonInteger(resolverVersion),
    'blueprintRevision': _jsonInteger(blueprintRevision),
    'components': <String, Object?>{
      'blueprint': components.blueprint,
      'geometryAndSeed': components.geometryAndSeed,
      'parameters': components.parameters,
      'overrides': components.overrides,
      'keepOutRegions': components.keepOutRegions,
      'mapContext': components.mapContext,
      'visualSnapshots': components.visualSnapshots,
    },
  });
}

/// Hashes only persisted visual output, preserving both list orders exactly.
String computeBorderOutputFingerprint({
  required List<BorderResolvedGroundCell> ground,
  required List<BorderResolvedPlacement> placements,
}) =>
    _fingerprint(<String, Object?>{
      'ground': <Object?>[
        for (final cell in ground) _groundCellProjection(cell),
      ],
      'placements': <Object?>[
        for (final placement in placements) _placementProjection(placement),
      ],
    });

Object _blueprintProjection({
  required String blueprintId,
  required BorderBlueprintRevision revision,
}) {
  final definition = revision.definition;
  final primitives = definition.primitives.toList(growable: false)
    ..sort((left, right) => compareNarrativeEventUtf16(left.id, right.id));
  for (var index = 1; index < primitives.length; index += 1) {
    if (primitives[index - 1].id == primitives[index].id) {
      throw ValidationException(
        'Published Border primitives must have unique ids: '
        '${primitives[index].id}',
      );
    }
  }

  return <String, Object?>{
    'blueprintId': blueprintId,
    'revision': _jsonInteger(revision.revision),
    'template': _templateV1WireName(definition.template),
    'defaults': _parametersProjection(definition.defaults),
    'primitives': <Object?>[
      for (final primitive in primitives)
        <String, Object?>{
          'id': primitive.id,
          'visualSnapshotId': primitive.visualSnapshotId,
          'role': borderPrimitiveRoleV1WireName(primitive.role),
          'weight': primitive.weight,
          'anchorPx': _pixelPosProjection(primitive.anchorPx),
          'transforms': _transformPolicyProjection(primitive.transforms),
          'publishedMetrics': _metricsProjection(primitive.publishedMetrics),
        },
    ],
    'ground': switch (definition.ground) {
      final ground? => <String, Object?>{
          'edgeBandCells': _jsonInteger(ground.edgeBandCells),
          'visualSnapshotIdsByRole': <String, Object?>{
            for (final role in standardSurfaceVariantRoleOrder)
              _surfaceRoleV1WireName(role):
                  ground.visualSnapshotIdsByRole[role]!,
          },
        },
      null => null,
    },
  };
}

Object _geometryAndSeedProjection(
  BorderFeature feature, {
  required BorderBlueprintTemplate template,
}) =>
    <String, Object?>{
      'featureId': feature.id,
      'seed': feature.seed.toString(),
      'geometry': _geometryProjection(feature.geometry),
      if (template == BorderBlueprintTemplate.connectedLine)
        'lineSide': switch (feature.lineSide) {
          BorderLineSide.primary => 'primary',
          BorderLineSide.inverted => 'inverted',
        },
    };

Object _geometryProjection(BorderFeatureGeometry geometry) =>
    switch (geometry) {
      BorderRegionGeometry(:final width, :final height, :final cells) =>
        <String, Object?>{
          'kind': 'region',
          'width': _jsonInteger(width),
          'height': _jsonInteger(height),
          'cellsRle': encodeBorderRleMask(cells),
        },
      BorderStrokeGeometry(:final strokes) => <String, Object?>{
          'kind': 'stroke',
          'strokes': <Object?>[
            for (final stroke in strokes)
              <String, Object?>{
                'id': stroke.id,
                'closed': stroke.closed,
                'points': <Object?>[
                  for (final point in stroke.points)
                    <String, Object?>{
                      'x': _jsonInteger(point.x),
                      'y': _jsonInteger(point.y),
                    },
                ],
              },
          ],
        },
    };

Object _parametersProjection(BorderGenerationParams parameters) =>
    <String, Object?>{
      'irregularityPermille': parameters.irregularityPermille,
      'detailDensityPermille': parameters.detailDensityPermille,
      'variationPermille': parameters.variationPermille,
      'maxOverlapPx': _jsonInteger(parameters.maxOverlapPx),
      'gapTolerancePx': _jsonInteger(parameters.gapTolerancePx),
      'depthRows': _jsonInteger(parameters.depthRows),
      if (!parameters.allowAutoRotation) 'allowAutoRotation': false,
    };

Object _overridesProjection(List<BorderSlotOverride> source) {
  final overrides = source.toList(growable: false)
    ..sort(
      (left, right) => compareNarrativeEventUtf16(left.slotKey, right.slotKey),
    );
  return <String, Object?>{
    'overrides': <Object?>[
      for (final override in overrides)
        <String, Object?>{
          'slotKey': override.slotKey,
          'variationSalt': override.variationSalt.toString(),
          'suppressed': override.suppressed,
          'locked': override.locked,
          'lockedPlacement': switch (override.lockedPlacement) {
            final placement? => _placementProjection(placement),
            null => null,
          },
          'replacementPrimitiveId': override.replacementPrimitiveId,
          'offsetDeltaPx': switch (override.offsetDeltaPx) {
            final offset? => <String, Object?>{
                'x': _jsonInteger(offset.x),
                'y': _jsonInteger(offset.y),
              },
            null => null,
          },
          'transformOverride': switch (override.transformOverride) {
            final transform? => _spriteTransformProjection(transform),
            null => null,
          },
        },
    ],
  };
}

Object _keepOutProjection(List<BorderKeepOutRegion> source) {
  final regions = source.toList(growable: false)
    ..sort((left, right) => compareNarrativeEventUtf16(left.id, right.id));
  return <String, Object?>{
    'keepOutRegions': <Object?>[
      for (final keepOut in regions)
        <String, Object?>{
          'id': keepOut.id,
          'region': _geometryProjection(keepOut.region),
        },
    ],
  };
}

Object _visualSnapshotsProjection(List<BorderVisualSnapshot> snapshots) =>
    <String, Object?>{
      'visualSnapshots': <Object?>[
        for (final snapshot in snapshots)
          <String, Object?>{
            'id': snapshot.id,
            'contentFingerprint': snapshot.contentFingerprint,
            'frames': <Object?>[
              for (final frame in snapshot.frames)
                <String, Object?>{
                  'relativeAssetPath': frame.relativeAssetPath,
                  'sourceRectPx': _pixelRectProjection(frame.sourceRectPx),
                  'durationMs': _jsonInteger(frame.durationMs),
                  'transparentColorArgb': frame.transparentColorArgb,
                },
            ],
          },
      ],
    };

Set<String> _referencedSnapshotIds(
  BorderBlueprintPublishedDefinition definition,
  List<BorderSlotOverride> overrides,
) {
  final result = <String>{
    for (final primitive in definition.primitives) primitive.visualSnapshotId,
  };
  final ground = definition.ground;
  if (ground != null) {
    result.addAll(ground.visualSnapshotIdsByRole.values);
  }
  for (final override in overrides) {
    final lockedPlacement = override.lockedPlacement;
    if (lockedPlacement != null) {
      result.add(lockedPlacement.visualSnapshotId);
    }
  }
  return result;
}

Object _metricsProjection(BorderPrimitiveAssetMetrics metrics) =>
    <String, Object?>{
      'assetFingerprint': metrics.assetFingerprint,
      'pixelSize': <String, Object?>{
        'width': _jsonInteger(metrics.pixelSize.width),
        'height': _jsonInteger(metrics.pixelSize.height),
      },
      'opaqueBounds': _pixelRectProjection(metrics.opaqueBounds),
      'defaultAnchorPx': _pixelPosProjection(metrics.defaultAnchorPx),
      'occupancyMaskRle': metrics.occupancyMaskRle,
    };

Object _transformPolicyProjection(BorderTransformPolicy transforms) =>
    <String, Object?>{
      'allowFlipX': transforms.allowFlipX,
      'allowedQuarterTurns': transforms.allowedQuarterTurns,
    };

Object _groundCellProjection(BorderResolvedGroundCell cell) =>
    <String, Object?>{
      'x': _jsonInteger(cell.x),
      'y': _jsonInteger(cell.y),
      'visualSnapshotId': cell.visualSnapshotId,
      'resolvedRole': _surfaceRoleV1WireName(cell.resolvedRole),
    };

Object _placementProjection(BorderResolvedPlacement placement) =>
    <String, Object?>{
      'id': placement.id,
      'slotKey': placement.slotKey,
      'primitiveId': placement.primitiveId,
      'visualSnapshotId': placement.visualSnapshotId,
      'anchorCell': <String, Object?>{
        'x': _jsonInteger(placement.anchorCell.x),
        'y': _jsonInteger(placement.anchorCell.y),
      },
      'topLeftWorldPx': _pixelPosProjection(placement.topLeftWorldPx),
      'opaqueWorldBoundsPx':
          _pixelRectProjection(placement.opaqueWorldBoundsPx),
      'transform': _spriteTransformProjection(placement.transform),
      'drawBand': _drawBandV1WireName(placement.drawBand),
      'stableOrderKey': <String, Object?>{
        'drawBandIndex': _jsonInteger(placement.stableOrderKey.drawBandIndex),
        'anchorRowMajor': _jsonInteger(placement.stableOrderKey.anchorRowMajor),
        'passIndex': _jsonInteger(placement.stableOrderKey.passIndex),
        'rank': _jsonInteger(placement.stableOrderKey.rank),
        'ordinalLocal': _jsonInteger(placement.stableOrderKey.ordinalLocal),
        'slotKey': placement.stableOrderKey.slotKey,
      },
    };

Object _pixelPosProjection(BorderPixelPos position) => <String, Object?>{
      'x': _jsonInteger(position.x),
      'y': _jsonInteger(position.y),
    };

Object _pixelRectProjection(BorderPixelRect rectangle) => <String, Object?>{
      'x': _jsonInteger(rectangle.x),
      'y': _jsonInteger(rectangle.y),
      'width': _jsonInteger(rectangle.width),
      'height': _jsonInteger(rectangle.height),
    };

Object _spriteTransformProjection(BorderSpriteTransform transform) =>
    <String, Object?>{
      'quarterTurns': transform.quarterTurns,
      'flipX': transform.flipX,
    };

String _fingerprint(Object projection) =>
    'sha256:${narrativeEventCanonicalSha256(projection)}';

// Dart `int` is a JavaScript number on web targets. Restrict ordinary numeric
// projection fields to the contiguous exact I-JSON integer domain before JCS.
int _jsonInteger(int value) {
  final exact = BigInt.from(value);
  if (exact.abs() > _maximumPortableJsonInteger) {
    throw ValidationException(
      'Border fingerprint integer must be within the portable I-JSON range',
    );
  }
  return value;
}

String _templateV1WireName(BorderBlueprintTemplate template) =>
    borderBlueprintTemplateV1WireName(template);

String _drawBandV1WireName(BorderDrawBand band) => switch (band) {
      BorderDrawBand.outerAccent => 'outerAccent',
      BorderDrawBand.structure => 'structure',
      BorderDrawBand.innerFinish => 'innerFinish',
      BorderDrawBand.accent => 'accent',
    };

String _surfaceRoleV1WireName(SurfaceVariantRole role) => switch (role) {
      SurfaceVariantRole.isolated => 'isolated',
      SurfaceVariantRole.endNorth => 'endNorth',
      SurfaceVariantRole.endEast => 'endEast',
      SurfaceVariantRole.endSouth => 'endSouth',
      SurfaceVariantRole.endWest => 'endWest',
      SurfaceVariantRole.horizontal => 'horizontal',
      SurfaceVariantRole.vertical => 'vertical',
      SurfaceVariantRole.cornerNE => 'cornerNE',
      SurfaceVariantRole.cornerSE => 'cornerSE',
      SurfaceVariantRole.cornerSW => 'cornerSW',
      SurfaceVariantRole.cornerNW => 'cornerNW',
      SurfaceVariantRole.innerCornerNE => 'innerCornerNE',
      SurfaceVariantRole.innerCornerSE => 'innerCornerSE',
      SurfaceVariantRole.innerCornerSW => 'innerCornerSW',
      SurfaceVariantRole.innerCornerNW => 'innerCornerNW',
      SurfaceVariantRole.teeNorth => 'teeNorth',
      SurfaceVariantRole.teeEast => 'teeEast',
      SurfaceVariantRole.teeSouth => 'teeSouth',
      SurfaceVariantRole.teeWest => 'teeWest',
      SurfaceVariantRole.cross => 'cross',
    };
