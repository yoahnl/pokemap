import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../application/runtime_map_bundle.dart';
import 'border_runtime_asset_collection.dart';
import 'border_runtime_preparation.dart';

/// Mémo process-level des inspections d'intégrité.
///
/// La clé encode le fingerprint attendu et, pour chaque frame, le chemin,
/// le mtime et la taille du fichier : toute modification sur disque change la
/// clé et force une ré-inspection. L'invariant « ne jamais faire confiance à
/// une préparation antérieure » porte sur les octets des fichiers, pas sur le
/// droit de mémoïser un résultat dont les entrées n'ont pas bougé — avant ce
/// mémo, chaque mount/warp re-décodait tous les PNG de bordure et refaisait
/// le fingerprint pixel par pixel sur l'isolate UI.
final Map<String, BorderVisualSnapshotIntegrity> _integrityByStatKey =
    <String, BorderVisualSnapshotIntegrity>{};
const int _integrityCacheCapacity = 256;

/// Controlled failure raised by the Border play gate before a map is mounted.
final class BorderRuntimeReadinessException implements Exception {
  const BorderRuntimeReadinessException({
    required this.mapId,
    required this.layerId,
    required this.featureId,
    required this.state,
    required this.reasons,
  });

  final String mapId;
  final String layerId;
  final String featureId;
  final BorderMaterializationState state;
  final Set<BorderStalenessReason> reasons;

  @override
  String toString() {
    final details = reasons.isEmpty
        ? state.name
        : '$state (${reasons.map((reason) => reason.name).join(', ')})';
    return 'Border runtime readiness failed for map=$mapId layer=$layerId '
        'feature=$featureId: $details';
  }
}

/// Rebuilds and verifies the complete passive Border runtime contract.
///
/// This function is intentionally idempotent but never trusts a prior
/// preparation: transformed bundles and files are checked again before a host
/// caches or mounts the map. No Border solver is invoked.
Future<RuntimeMapBundle> prepareBorderRuntimeBundle(
  RuntimeMapBundle bundle,
) async {
  final catalog = bundle.manifest.borderCatalog;
  final usedSnapshotIds = _materializedSnapshotIds(bundle.map);
  final integrity = <String, BorderVisualSnapshotIntegrity>{};
  for (final snapshotId in usedSnapshotIds) {
    final snapshot = catalog.visualSnapshotById(snapshotId);
    integrity[snapshotId] = snapshot == null
        ? BorderVisualSnapshotIntegrity(
            snapshotId: snapshotId,
            metadataValid: false,
            filesPresent: false,
            contentFingerprintMatches: false,
          )
        : await _inspectSnapshotCached(
            snapshot,
            projectRoot: bundle.projectRootDirectory,
          );
  }

  final freshness = <BorderMaterializationFreshness>[];
  final spatial = bundle.map.spatialScene == null
      ? null
      : _SpatialBorderReadiness(bundle);
  for (final layer in bundle.map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      final record = catalog.recordById(feature.blueprintId);
      final BorderMaterializationFreshness result;
      if (spatial != null) {
        result = spatial.assess(layer.id, feature);
      } else if (record?.latestPublished?.definition.isSpatial == true ||
          feature.materialization?.targetsSpatialScene == true) {
        result = BorderMaterializationFreshness(
          state: BorderMaterializationState.invalid,
          reasons: const {BorderStalenessReason.mapContextChanged},
          isRenderable: false,
          canRegenerate: false,
        );
      } else {
        final request = BorderResolutionRequest(
          mapSize: bundle.map.size,
          tileSizePx: GridSize(
            width: bundle.manifest.settings.tileWidth,
            height: bundle.manifest.settings.tileHeight,
          ),
          blueprintId: feature.blueprintId,
          blueprintRevision: record?.latestPublished,
          feature: feature,
          visualSnapshots: catalog.visualSnapshots,
          resolverVersion:
              feature.materialization?.receipt.resolverVersion ?? 1,
        );
        result = assessBorderMaterializationFreshness(
          request,
          materialization: feature.materialization,
          snapshotIntegrity: integrity,
        );
      }
      freshness.add(result);
      if (!result.isRenderable) {
        throw BorderRuntimeReadinessException(
          mapId: bundle.map.id,
          layerId: layer.id,
          featureId: feature.id,
          state: result.state,
          reasons: result.reasons,
        );
      }
    }
  }

  final collection = collectBorderRuntimeAssetRequests(
    map: bundle.map,
    catalog: catalog,
  );
  return bundle.copyWith(
    borderRuntimePreparation: BorderRuntimePreparation(
      assetCollection: collection,
      snapshotIntegrity: integrity,
      featureFreshness: freshness,
    ),
  );
}

final class _SpatialBorderReadiness {
  _SpatialBorderReadiness(RuntimeMapBundle bundle)
    : manifest = bundle.manifest,
      map = bundle.map,
      instances = {
        for (final instance in bundle.map.spatialScene!.instances)
          instance.id: instance,
      },
      models = {for (final model in bundle.manifest.models3d) model.id: model} {
    final scene = map.spatialScene!;
    mapContext = _spatialFingerprint({
      'mapId': map.id,
      'mapVersion': map.version.name,
      'mapSize': map.size.toJson(),
      'width': scene.width,
      'depth': scene.depth,
      'heightLevels': scene.heightLevels,
      'levelHeight': scene.levelHeight,
      'ramps': scene.navigation.ramps.map((ramp) => ramp.toJson()).toList(),
      'tileWidth': manifest.settings.tileWidth,
      'tileHeight': manifest.settings.tileHeight,
    });
    try {
      validateSpatialMapStructure(map);
      structureValid =
          instances.length == scene.instances.length &&
          models.length == manifest.models3d.length;
    } on FormatException {
      structureValid = false;
    }
  }

  final ProjectManifest manifest;
  final MapData map;
  final Map<String, SpatialModelInstance> instances;
  final Map<String, ProjectModel3dEntry> models;
  final blueprints =
      <String, ({bool valid, String blueprint, String visual})>{};
  late final String mapContext;
  late final bool structureValid;

  BorderMaterializationFreshness assess(String layerId, BorderFeature feature) {
    final materialization = feature.materialization;
    final revision = manifest.borderCatalog
        .recordById(feature.blueprintId)
        ?.latestPublished;
    BorderMaterializationFreshness invalid(BorderStalenessReason reason) =>
        BorderMaterializationFreshness(
          state: BorderMaterializationState.invalid,
          reasons: {reason},
          isRenderable: false,
          canRegenerate: false,
        );
    if (!structureValid) {
      return invalid(BorderStalenessReason.outputAltered);
    }
    if (revision == null) {
      return invalid(BorderStalenessReason.blueprintMissing);
    }
    final definition = revision.definition;
    if (!definition.isSpatial ||
        !manifest.resourceLibraryCatalog.availableForMap(
          'borderBlueprint',
          feature.blueprintId,
          map.id,
        )) {
      return invalid(BorderStalenessReason.visualSnapshotMissingOrCorrupt);
    }
    final blueprint = blueprints.putIfAbsent(feature.blueprintId, () {
      final ids = definition.primitives
          .map((primitive) => primitive.sourceModelId)
          .toSet();
      final sources = [
        for (final id in ids)
          if (models[id] != null) models[id]!,
      ]..sort((left, right) => left.id.compareTo(right.id));
      return (
        valid:
            !validateSpatialBorderBlueprint(
              blueprintId: feature.blueprintId,
              definition: definition,
              manifest: manifest,
            ).hasErrors &&
            sources.every(
              (model) => manifest.resourceLibraryCatalog.availableForMap(
                'model3d',
                model.id,
                map.id,
              ),
            ),
        blueprint: _spatialFingerprint(
          encodeBorderBlueprintRevisionJson(
            revision,
            formatVersion: manifest.borderCatalog.formatVersion,
          ),
        ),
        visual: _spatialFingerprint({
          'models': sources.map((model) => model.toJson()).toList(),
        }),
      );
    });
    if (!blueprint.valid ||
        validateSpatialBorderFeatureGeometry(
          blueprintId: feature.blueprintId,
          featureId: feature.id,
          definition: definition,
          geometry: feature.geometry,
        ).hasErrors) {
      return invalid(BorderStalenessReason.visualSnapshotMissingOrCorrupt);
    }
    if (materialization == null) {
      return BorderMaterializationFreshness(
        state: BorderMaterializationState.unmaterialized,
        reasons: const {},
        isRenderable: false,
        canRegenerate: true,
      );
    }
    final receipt = materialization.receipt;
    if (!materialization.targetsSpatialScene ||
        receipt.resolverVersion != borderResolverVersion ||
        receipt.blueprintRevision > revision.revision ||
        receipt.inputFingerprint !=
            computeBorderAggregateInputFingerprint(
              resolverVersion: receipt.resolverVersion,
              blueprintRevision: receipt.blueprintRevision,
              components: receipt.components,
            )) {
      return invalid(BorderStalenessReason.outputAltered);
    }
    final primitives = {
      for (final primitive in definition.primitives) primitive.id: primitive,
    };
    final placements = materialization.spatialPlacements;
    final placedInstances = <SpatialModelInstance>[];
    for (final placement in placements) {
      final instance = instances[placement.instanceId];
      final primitive = primitives[placement.primitiveId];
      final expectedId =
          'border3d_${_spatialFingerprint([map.id, layerId, feature.id, placement.slotKey]).substring(7, 39)}';
      if (instance == null ||
          primitive == null ||
          instance.modelId != primitive.sourceModelId ||
          instance.id != expectedId ||
          instance.position.x < 0 ||
          instance.position.z < 0 ||
          instance.position.x >= map.spatialScene!.width ||
          instance.position.z >= map.spatialScene!.depth) {
        return invalid(BorderStalenessReason.outputAltered);
      }
      final model = models[instance.modelId]!;
      if (instance.animationIndex != null &&
          !model.inspection.animations.any(
            (animation) => animation.index == instance.animationIndex,
          )) {
        return invalid(BorderStalenessReason.visualSnapshotMissingOrCorrupt);
      }
      placedInstances.add(instance);
    }
    if (receipt.outputFingerprint !=
        _spatialFingerprint({
          'placements': [
            for (final placement in placements)
              {
                'slotKey': placement.slotKey,
                'primitiveId': placement.primitiveId,
                'instanceId': placement.instanceId,
              },
          ],
          'instances': placedInstances
              .map((instance) => instance.toJson())
              .toList(),
        })) {
      return invalid(BorderStalenessReason.outputAltered);
    }
    final featureJson = encodeBorderFeatureJson(feature, formatVersion: 4)
      ..remove('materialization');
    final current = BorderInputFingerprints(
      blueprint: blueprint.blueprint,
      geometryAndSeed: _spatialFingerprint({
        'geometry': featureJson['geometry'],
        'seed': feature.seed.toString(),
      }),
      parameters: _spatialFingerprint({
        'defaults': encodeBorderGenerationParamsJson(
          feature.paramsOverride ?? definition.defaults,
          formatVersion: 5,
        ),
        'lineSide': feature.lineSide.name,
        'spatialOffsetWorld': feature.spatialOffsetWorld?.toJson(),
      }),
      overrides: _spatialFingerprint({
        'overrides': featureJson['overrides'],
        'lockedInstances': [
          if (feature.overrides.any(
            (override) => override.lockedInstanceId != null,
          ))
            for (final instance in map.spatialScene!.instances)
              if (feature.overrides.any(
                (override) => override.lockedInstanceId == instance.id,
              ))
                instance.toJson(),
        ],
      }),
      keepOutRegions: _spatialFingerprint(featureJson['keepOutRegions']),
      mapContext: mapContext,
      visualSnapshots: blueprint.visual,
    );
    final previous = receipt.components;
    final reasons = <BorderStalenessReason>{};
    if (receipt.blueprintRevision != revision.revision) {
      reasons.add(BorderStalenessReason.blueprintNewer);
    } else if (current.blueprint != previous.blueprint) {
      return invalid(BorderStalenessReason.outputAltered);
    }
    if (current.geometryAndSeed != previous.geometryAndSeed) {
      reasons.add(BorderStalenessReason.geometryOrSeedChanged);
    }
    if (current.parameters != previous.parameters) {
      reasons.add(BorderStalenessReason.parametersChanged);
    }
    if (current.overrides != previous.overrides) {
      reasons.add(BorderStalenessReason.overridesChanged);
    }
    if (current.keepOutRegions != previous.keepOutRegions) {
      reasons.add(BorderStalenessReason.keepOutRegionsChanged);
    }
    if (current.mapContext != previous.mapContext) {
      reasons.add(BorderStalenessReason.mapContextChanged);
    }
    if (current.visualSnapshots != previous.visualSnapshots) {
      reasons.add(BorderStalenessReason.visualSnapshotMissingOrCorrupt);
    }
    return BorderMaterializationFreshness(
      state: reasons.isEmpty
          ? BorderMaterializationState.fresh
          : BorderMaterializationState.stale,
      reasons: {
        for (final reason in borderStalenessReasonV1Order)
          if (reasons.contains(reason)) reason,
      },
      isRenderable: true,
      canRegenerate: !reasons.contains(
        BorderStalenessReason.visualSnapshotMissingOrCorrupt,
      ),
    );
  }
}

String _spatialFingerprint(Object? value) =>
    'sha256:${narrativeEventCanonicalSha256(value)}';

Set<String> _materializedSnapshotIds(MapData map) {
  final ids = <String>{};
  for (final layer in map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      final materialization = feature.materialization;
      if (materialization == null) continue;
      for (final ground in materialization.ground) {
        ids.add(ground.visualSnapshotId);
      }
      for (final placement in materialization.placements) {
        ids.add(placement.visualSnapshotId);
      }
    }
  }
  return ids;
}

Future<BorderVisualSnapshotIntegrity> _inspectSnapshotCached(
  BorderVisualSnapshot snapshot, {
  required String projectRoot,
}) async {
  final key = await _snapshotStatKey(snapshot, projectRoot: projectRoot);
  final cached = _integrityByStatKey.remove(key);
  if (cached != null) {
    _integrityByStatKey[key] = cached;
    return cached;
  }
  final result = await _inspectSnapshotOffThread(snapshot, projectRoot);
  _integrityByStatKey[key] = result;
  while (_integrityByStatKey.length > _integrityCacheCapacity) {
    _integrityByStatKey.remove(_integrityByStatKey.keys.first);
  }
  return result;
}

Future<String> _snapshotStatKey(
  BorderVisualSnapshot snapshot, {
  required String projectRoot,
}) async {
  final buffer = StringBuffer()
    ..write(snapshot.id)
    ..write('|')
    ..write(snapshot.contentFingerprint)
    ..write('|')
    ..write(projectRoot);
  for (final frame in snapshot.frames) {
    final absolutePath = p.normalize(
      p.absolute(p.join(projectRoot, frame.relativeAssetPath)),
    );
    final stat = await FileStat.stat(absolutePath);
    final rect = frame.sourceRectPx;
    buffer
      ..write('|')
      ..write(absolutePath)
      ..write('#')
      ..write(stat.type == FileSystemEntityType.notFound
          ? 'missing'
          : '${stat.modified.microsecondsSinceEpoch},${stat.size}')
      ..write('#')
      ..write('${rect.x},${rect.y},${rect.width},${rect.height}')
      ..write('#')
      ..write(frame.transparentColorArgb)
      ..write('#')
      ..write(frame.durationMs);
  }
  return buffer.toString();
}

/// Portée top-level : le closure envoyé à l'isolate ne doit capturer que le
/// snapshot (modèle pur) et le chemin racine.
Future<BorderVisualSnapshotIntegrity> _inspectSnapshotOffThread(
  BorderVisualSnapshot snapshot,
  String projectRoot,
) {
  return Isolate.run(
    () => _inspectSnapshot(snapshot, projectRoot: projectRoot),
  );
}

Future<BorderVisualSnapshotIntegrity> _inspectSnapshot(
  BorderVisualSnapshot snapshot, {
  required String projectRoot,
}) async {
  var metadataValid = true;
  var filesPresent = true;
  final contentFrames = <BorderSnapshotContentFrame>[];
  for (final frame in snapshot.frames) {
    final absolutePath = p.normalize(
      p.absolute(p.join(projectRoot, frame.relativeAssetPath)),
    );
    final file = File(absolutePath);
    if (!await file.exists()) {
      filesPresent = false;
      continue;
    }
    try {
      final decoded = img.decodeImage(await file.readAsBytes());
      final rect = frame.sourceRectPx;
      if (decoded == null || !_rectFits(rect, decoded.width, decoded.height)) {
        metadataValid = false;
        continue;
      }
      final rgba = Uint8List(rect.width * rect.height * 4);
      final transparentRgb = frame.transparentColorArgb == null
          ? null
          : frame.transparentColorArgb! & 0x00ffffff;
      for (var y = 0; y < rect.height; y += 1) {
        for (var x = 0; x < rect.width; x += 1) {
          final pixel = decoded.getPixel(rect.x + x, rect.y + y);
          final red = pixel.r.toInt();
          final green = pixel.g.toInt();
          final blue = pixel.b.toInt();
          var alpha = pixel.a.toInt();
          if (transparentRgb != null &&
              ((red << 16) | (green << 8) | blue) == transparentRgb) {
            alpha = 0;
          }
          final offset = (y * rect.width + x) * 4;
          rgba[offset] = red;
          rgba[offset + 1] = green;
          rgba[offset + 2] = blue;
          rgba[offset + 3] = alpha;
        }
      }
      contentFrames.add(
        BorderSnapshotContentFrame(
          sourceRectPx: rect,
          durationMs: frame.durationMs,
          transparentColorArgb: frame.transparentColorArgb,
          rgbaBytes: rgba,
        ),
      );
    } catch (_) {
      metadataValid = false;
    }
  }

  var contentFingerprintMatches = false;
  if (metadataValid &&
      filesPresent &&
      contentFrames.length == snapshot.frames.length) {
    try {
      contentFingerprintMatches = computeBorderSnapshotContentFingerprint(
            frames: contentFrames,
          ) ==
          snapshot.contentFingerprint;
    } catch (_) {
      metadataValid = false;
    }
  }
  return BorderVisualSnapshotIntegrity(
    snapshotId: snapshot.id,
    metadataValid: metadataValid,
    filesPresent: filesPresent,
    contentFingerprintMatches: contentFingerprintMatches,
  );
}

bool _rectFits(BorderPixelRect rect, int width, int height) =>
    rect.x >= 0 &&
    rect.y >= 0 &&
    rect.x <= width - rect.width &&
    rect.y <= height - rect.height;
