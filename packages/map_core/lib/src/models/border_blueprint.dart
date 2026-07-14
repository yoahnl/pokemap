import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_signed_int64.dart';
import 'border_value_objects.dart';
import 'border_visual_snapshot.dart';
import 'surface.dart';

/// Editable primitive referencing a current project element.
@immutable
final class BorderPrimitiveDraft {
  BorderPrimitiveDraft({
    required this.id,
    required this.sourceElementId,
    required this.role,
    required this.weight,
    required this.anchorPx,
    required this.transforms,
    required this.currentMetrics,
  }) {
    _requireNonEmpty(id, 'BorderPrimitiveDraft.id');
    _requireNonEmpty(
      sourceElementId,
      'BorderPrimitiveDraft.sourceElementId',
    );
    if (weight < 0 || weight > 1000) {
      throw const ValidationException(
        'BorderPrimitiveDraft.weight must be between 0 and 1000',
      );
    }
  }

  final String id;
  final String sourceElementId;
  final BorderPrimitiveRole role;
  final int weight;
  final BorderPixelPos anchorPx;
  final BorderTransformPolicy transforms;
  final BorderPrimitiveAssetMetrics currentMetrics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPrimitiveDraft &&
          id == other.id &&
          sourceElementId == other.sourceElementId &&
          role == other.role &&
          weight == other.weight &&
          anchorPx == other.anchorPx &&
          transforms == other.transforms &&
          currentMetrics == other.currentMetrics;

  @override
  int get hashCode => Object.hash(
        id,
        sourceElementId,
        role,
        weight,
        anchorPx,
        transforms,
        currentMetrics,
      );
}

/// Immutable published primitive referencing a content-addressed snapshot.
@immutable
final class BorderPublishedPrimitive {
  BorderPublishedPrimitive({
    required this.id,
    required this.sourceElementId,
    required this.visualSnapshotId,
    required this.role,
    required this.weight,
    required this.anchorPx,
    required this.transforms,
    required this.publishedMetrics,
  }) {
    _requireNonEmpty(id, 'BorderPublishedPrimitive.id');
    _requireNonEmpty(
      sourceElementId,
      'BorderPublishedPrimitive.sourceElementId',
    );
    _requireNonEmpty(
      visualSnapshotId,
      'BorderPublishedPrimitive.visualSnapshotId',
    );
    if (weight < 1 || weight > 1000) {
      throw const ValidationException(
        'BorderPublishedPrimitive.weight must be between 1 and 1000',
      );
    }
  }

  final String id;
  final String sourceElementId;
  final String visualSnapshotId;
  final BorderPrimitiveRole role;
  final int weight;
  final BorderPixelPos anchorPx;
  final BorderTransformPolicy transforms;
  final BorderPrimitiveAssetMetrics publishedMetrics;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublishedPrimitive &&
          id == other.id &&
          sourceElementId == other.sourceElementId &&
          visualSnapshotId == other.visualSnapshotId &&
          role == other.role &&
          weight == other.weight &&
          anchorPx == other.anchorPx &&
          transforms == other.transforms &&
          publishedMetrics == other.publishedMetrics;

  @override
  int get hashCode => Object.hash(
        id,
        sourceElementId,
        visualSnapshotId,
        role,
        weight,
        anchorPx,
        transforms,
        publishedMetrics,
      );
}

/// Optional editable Surface ground band.
@immutable
final class BorderGroundDraft {
  BorderGroundDraft({
    required this.sourceSurfacePresetId,
    required this.edgeBandCells,
  }) {
    _requireNonEmpty(
      sourceSurfacePresetId,
      'BorderGroundDraft.sourceSurfacePresetId',
    );
    _requirePositiveEdgeBand(edgeBandCells, 'BorderGroundDraft');
  }

  final String sourceSurfacePresetId;
  final int edgeBandCells;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderGroundDraft &&
          sourceSurfacePresetId == other.sourceSurfacePresetId &&
          edgeBandCells == other.edgeBandCells;

  @override
  int get hashCode => Object.hash(sourceSurfacePresetId, edgeBandCells);
}

/// Immutable published Surface ground band with resolved visual snapshots.
@immutable
final class BorderPublishedGround {
  BorderPublishedGround({
    required this.sourceSurfacePresetId,
    required this.edgeBandCells,
    required Map<SurfaceVariantRole, String> visualSnapshotIdsByRole,
  }) : _visualSnapshotIdsByRole = _copyPublishedGroundSnapshots(
          visualSnapshotIdsByRole,
        ) {
    _requireNonEmpty(
      sourceSurfacePresetId,
      'BorderPublishedGround.sourceSurfacePresetId',
    );
    _requirePositiveEdgeBand(edgeBandCells, 'BorderPublishedGround');
  }

  final String sourceSurfacePresetId;
  final int edgeBandCells;
  final Map<SurfaceVariantRole, String> _visualSnapshotIdsByRole;

  Map<SurfaceVariantRole, String> get visualSnapshotIdsByRole =>
      _visualSnapshotIdsByRole;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublishedGround &&
          sourceSurfacePresetId == other.sourceSurfacePresetId &&
          edgeBandCells == other.edgeBandCells &&
          _mapsEqual(
            _visualSnapshotIdsByRole,
            other._visualSnapshotIdsByRole,
          );

  @override
  int get hashCode => Object.hash(
        sourceSurfacePresetId,
        edgeBandCells,
        _unorderedMapHash(_visualSnapshotIdsByRole),
      );
}

/// Shared shape of editable and published blueprint definitions.
@immutable
final class BorderBlueprintDefinition<TPrimitive, TGround> {
  BorderBlueprintDefinition({
    required this.name,
    required this.previewSeed,
    required this.template,
    required List<TPrimitive> primitives,
    required this.defaults,
    this.ground,
    this.categoryId,
    required this.sortOrder,
  }) : _primitives = List<TPrimitive>.unmodifiable(primitives) {
    _requireNonEmpty(name, 'BorderBlueprintDefinition.name');
    final category = categoryId;
    if (category != null) {
      _requireNonEmpty(category, 'BorderBlueprintDefinition.categoryId');
    }
  }

  final String name;
  final BorderSignedInt64 previewSeed;
  final BorderBlueprintTemplate template;
  final List<TPrimitive> _primitives;
  final BorderGenerationParams defaults;
  final TGround? ground;
  final String? categoryId;
  final int sortOrder;

  List<TPrimitive> get primitives => _primitives;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderBlueprintDefinition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          previewSeed == other.previewSeed &&
          template == other.template &&
          _listsEqual(_primitives, other._primitives) &&
          defaults == other.defaults &&
          ground == other.ground &&
          categoryId == other.categoryId &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(
        runtimeType,
        name,
        previewSeed,
        template,
        Object.hashAll(_primitives),
        defaults,
        ground,
        categoryId,
        sortOrder,
      );
}

typedef BorderBlueprintDraftDefinition
    = BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>;
typedef BorderBlueprintPublishedDefinition = BorderBlueprintDefinition<
    BorderPublishedPrimitive, BorderPublishedGround>;

/// Editable state retained by every blueprint record.
@immutable
final class BorderBlueprintDraft {
  BorderBlueprintDraft({
    required this.baseRevision,
    required this.definition,
  }) {
    if (baseRevision < 0) {
      throw const ValidationException(
        'BorderBlueprintDraft.baseRevision must be >= 0',
      );
    }
  }

  final int baseRevision;
  final BorderBlueprintDraftDefinition definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderBlueprintDraft &&
          baseRevision == other.baseRevision &&
          definition == other.definition;

  @override
  int get hashCode => Object.hash(baseRevision, definition);
}

/// Latest immutable published revision retained by a blueprint record.
@immutable
final class BorderBlueprintRevision {
  BorderBlueprintRevision({
    required this.revision,
    required this.definition,
  }) {
    if (revision < 1) {
      throw const ValidationException(
        'BorderBlueprintRevision.revision must be >= 1',
      );
    }
  }

  final int revision;
  final BorderBlueprintPublishedDefinition definition;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderBlueprintRevision &&
          revision == other.revision &&
          definition == other.definition;

  @override
  int get hashCode => Object.hash(revision, definition);
}

/// Project-level identity retaining both draft and published state.
@immutable
final class BorderBlueprintRecord {
  BorderBlueprintRecord({
    required this.id,
    required this.draft,
    this.latestPublished,
    this.isDeprecated = false,
  }) {
    if (id.trim().isEmpty || id != id.trim()) {
      throw const ValidationException(
        'BorderBlueprintRecord.id must be nonblank and already trimmed',
      );
    }
  }

  final String id;
  final BorderBlueprintDraft draft;
  final BorderBlueprintRevision? latestPublished;
  final bool isDeprecated;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderBlueprintRecord &&
          id == other.id &&
          draft == other.draft &&
          latestPublished == other.latestPublished &&
          isDeprecated == other.isDeprecated;

  @override
  int get hashCode => Object.hash(id, draft, latestPublished, isDeprecated);
}

Map<SurfaceVariantRole, String> _copyPublishedGroundSnapshots(
  Map<SurfaceVariantRole, String> snapshots,
) {
  final result = Map<SurfaceVariantRole, String>.from(snapshots);
  for (final role in standardSurfaceVariantRoleOrder) {
    final snapshotId = result[role];
    if (snapshotId == null || snapshotId.isEmpty) {
      throw ValidationException(
        'BorderPublishedGround.visualSnapshotIdsByRole must contain '
        '${role.name}',
      );
    }
  }
  return Map<SurfaceVariantRole, String>.unmodifiable(result);
}

void _requireNonEmpty(String value, String field) {
  if (value.isEmpty) {
    throw ValidationException('$field must be non-empty');
  }
}

void _requirePositiveEdgeBand(int value, String owner) {
  if (value < 1) {
    throw ValidationException('$owner.edgeBandCells must be >= 1');
  }
}

bool _listsEqual<T>(List<T> a, List<T> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
  if (identical(a, b)) {
    return true;
  }
  if (a.length != b.length) {
    return false;
  }
  for (final entry in a.entries) {
    if (!b.containsKey(entry.key) || b[entry.key] != entry.value) {
      return false;
    }
  }
  return true;
}

int _unorderedMapHash<K, V>(Map<K, V> map) {
  return Object.hashAllUnordered(
    map.entries.map((entry) => Object.hash(entry.key, entry.value)),
  );
}
