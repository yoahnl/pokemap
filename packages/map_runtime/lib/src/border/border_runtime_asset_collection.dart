import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';

/// One immutable snapshot frame required by persisted Border materialization.
@immutable
final class BorderRuntimeFrameRequest {
  const BorderRuntimeFrameRequest({
    required this.snapshotId,
    required this.frameIndex,
    required this.relativeAssetPath,
    required this.sourceRectPx,
    required this.durationMs,
    required this.transparentColorArgb,
  });

  final String snapshotId;
  final int frameIndex;
  final String relativeAssetPath;
  final BorderPixelRect sourceRectPx;
  final int durationMs;
  final int? transparentColorArgb;

  /// The effective transparency cache component, independent of ARGB alpha.
  int? get effectiveTransparentRgb =>
      transparentColorArgb == null ? null : transparentColorArgb! & 0x00ffffff;
}

/// Ordered frames for one immutable visual snapshot.
@immutable
final class BorderRuntimeSnapshotRequest {
  BorderRuntimeSnapshotRequest({
    required this.snapshotId,
    required List<BorderRuntimeFrameRequest> frames,
  }) : frames = List<BorderRuntimeFrameRequest>.unmodifiable(frames) {
    if (this.frames.isEmpty) {
      throw ArgumentError.value(frames, 'frames', 'must not be empty');
    }
    for (var index = 0; index < this.frames.length; index += 1) {
      final frame = this.frames[index];
      if (frame.snapshotId != snapshotId || frame.frameIndex != index) {
        throw ArgumentError.value(
          frames,
          'frames',
          'must belong to the snapshot and use contiguous authored order',
        );
      }
    }
  }

  final String snapshotId;
  final List<BorderRuntimeFrameRequest> frames;
}

/// Stable, deduplicated snapshot requests needed to assess and render a map.
@immutable
final class BorderRuntimeAssetCollection {
  BorderRuntimeAssetCollection({
    required List<BorderRuntimeSnapshotRequest> snapshots,
  }) : snapshots = List<BorderRuntimeSnapshotRequest>.unmodifiable(snapshots) {
    final ids = <String>{};
    for (final snapshot in this.snapshots) {
      if (!ids.add(snapshot.snapshotId)) {
        throw ArgumentError.value(
          snapshots,
          'snapshots',
          'must not contain duplicate snapshot ids',
        );
      }
    }
  }

  final List<BorderRuntimeSnapshotRequest> snapshots;
}

/// Collects only immutable snapshots referenced by saved materialization.
///
/// Visibility is intentionally ignored: readiness must assess hidden layers
/// too. No blueprint, source element, historical ground preset, or Border solver is
/// consulted. First-reference order is retained and repeated ids are stable-
/// deduplicated.
BorderRuntimeAssetCollection collectBorderRuntimeAssetRequests({
  required MapData map,
  required ProjectBorderCatalog catalog,
}) {
  final referencedSnapshotIds = <String>[];
  final seenSnapshotIds = <String>{};

  void addReference(String snapshotId) {
    if (seenSnapshotIds.add(snapshotId)) {
      referencedSnapshotIds.add(snapshotId);
    }
  }

  for (final layer in map.layers) {
    if (layer is! BorderLayer) {
      continue;
    }

    // The persisted draw contract is all grounds across authored features,
    // followed by all placements across the same feature order.
    for (final feature in layer.content.features) {
      final materialization = feature.materialization;
      if (materialization == null) {
        continue;
      }
      for (final cell in materialization.ground) {
        addReference(cell.visualSnapshotId);
      }
    }
    for (final feature in layer.content.features) {
      final materialization = feature.materialization;
      if (materialization == null) {
        continue;
      }
      for (final placement in materialization.placements) {
        addReference(placement.visualSnapshotId);
      }
    }
  }

  return BorderRuntimeAssetCollection(
    snapshots: <BorderRuntimeSnapshotRequest>[
      for (final snapshotId in referencedSnapshotIds)
        _snapshotRequest(
          snapshotId: snapshotId,
          catalog: catalog,
        ),
    ],
  );
}

BorderRuntimeSnapshotRequest _snapshotRequest({
  required String snapshotId,
  required ProjectBorderCatalog catalog,
}) {
  final snapshot = catalog.visualSnapshotById(snapshotId);
  if (snapshot == null) {
    throw AssetNotFoundException(
      'Border visual snapshot not found in project catalog: $snapshotId',
    );
  }
  return BorderRuntimeSnapshotRequest(
    snapshotId: snapshot.id,
    frames: <BorderRuntimeFrameRequest>[
      for (var index = 0; index < snapshot.frames.length; index += 1)
        BorderRuntimeFrameRequest(
          snapshotId: snapshot.id,
          frameIndex: index,
          relativeAssetPath: snapshot.frames[index].relativeAssetPath,
          sourceRectPx: snapshot.frames[index].sourceRectPx,
          durationMs: snapshot.frames[index].durationMs,
          transparentColorArgb: snapshot.frames[index].transparentColorArgb,
        ),
    ],
  );
}
