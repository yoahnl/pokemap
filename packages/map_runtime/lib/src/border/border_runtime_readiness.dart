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
  for (final layer in bundle.map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      final record = catalog.recordById(feature.blueprintId);
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
        // Runtime is deliberately passive: it validates the persisted
        // materialization against the exact resolver contract recorded in
        // its receipt, without importing or invoking the current solver.
        resolverVersion: feature.materialization?.receipt.resolverVersion ?? 1,
      );
      final result = assessBorderMaterializationFreshness(
        request,
        materialization: feature.materialization,
        snapshotIntegrity: integrity,
      );
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
