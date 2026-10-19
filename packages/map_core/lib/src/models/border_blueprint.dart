import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_signed_int64.dart';
import 'border_ground_footprint.dart';
import 'border_ground_surface.dart';
import 'border_value_objects.dart';
import 'border_jump_behavior.dart';
import 'border_visual_snapshot.dart';
import 'border_ground_variant_role.dart';
import 'project_model3d.dart';

enum BorderVisualKind { element, model3d }

void _validateSpatialBehavior({
  required String? modelId,
  required int? animationIndex,
  required bool animationLoop,
  required double animationSpeed,
  required bool blocksMovement,
  required int sequenceIndex,
}) {
  if (sequenceIndex < 0 || sequenceIndex > 9007199254740991) {
    throw const ValidationException('Invalid Border sequence index');
  }
  if ((animationIndex != null && animationIndex < 0) ||
      !animationSpeed.isFinite ||
      animationSpeed <= 0 ||
      animationSpeed > 16) {
    throw const ValidationException('Invalid spatial Border playback settings');
  }
  if (modelId == null &&
      (animationIndex != null ||
          !animationLoop ||
          animationSpeed != 1 ||
          !blocksMovement ||
          sequenceIndex != 0)) {
    throw const ValidationException(
      'Spatial Border behavior requires a model source',
    );
  }
}

void _validateVisualSource(
  String? elementId,
  String? modelId,
  BorderPixelPos? anchorPx,
  Model3dVector3? anchorWorld,
  BorderPrimitiveAssetMetrics? metrics,
  String? snapshotId,
  bool published,
) {
  if ((elementId == null) == (modelId == null)) {
    throw const ValidationException(
      'A Border primitive requires exactly one element or model source',
    );
  }
  _requireNonEmpty(elementId ?? modelId!, 'BorderPrimitive.source');
  if (modelId != null) {
    if (anchorPx != null || metrics != null || snapshotId != null) {
      throw const ValidationException(
        'A spatial Border primitive cannot contain sprite metadata',
      );
    }
  } else if (anchorWorld != null ||
      anchorPx == null ||
      metrics == null ||
      (published && (snapshotId == null || snapshotId.trim().isEmpty))) {
    throw const ValidationException(
      'An element Border primitive requires sprite metadata only',
    );
  }
}

/// Editable primitive referencing a current project element.
@immutable
final class BorderPrimitiveDraft {
  BorderPrimitiveDraft({
    required this.id,
    this.sourceElementId,
    this.sourceModelId,
    required this.role,
    this.authoredOrientation = BorderPrimitiveOrientation.legacyAxis,
    this.sequenceIndex = 0,
    this.cornerTurn,
    required this.weight,
    BorderPixelPos? anchorPx,
    this.anchorWorld,
    this.animationIndex,
    this.animationLoop = true,
    this.animationSpeed = 1,
    this.blocksMovement = true,
    List<BorderGroundFootprint> groundFootprints = const [],
    List<BorderGroundSurface> groundSurfaces = const [],
    required this.transforms,
    BorderPrimitiveAssetMetrics? currentMetrics,
  }) : groundFootprints = validatedBorderGroundFootprints(
         groundFootprints,
         sourceModelId,
       ),
       groundSurfaces = validatedBorderGroundSurfaces(
         groundSurfaces,
         sourceModelId,
       ),
       _anchorPx = anchorPx,
       _currentMetrics = currentMetrics {
    _requireNonEmpty(id, 'BorderPrimitiveDraft.id');
    if (cornerTurn != null &&
        (sourceModelId == null || role != BorderPrimitiveRole.lineCorner)) {
      throw const ValidationException('Corner turn requires a spatial corner');
    }
    _validateSpatialBehavior(
      modelId: sourceModelId,
      animationIndex: animationIndex,
      animationLoop: animationLoop,
      animationSpeed: animationSpeed,
      blocksMovement: blocksMovement,
      sequenceIndex: sequenceIndex,
    );
    _validateVisualSource(
      sourceElementId,
      sourceModelId,
      anchorPx,
      anchorWorld,
      currentMetrics,
      null,
      false,
    );
    if (weight < 0 || weight > 1000) {
      throw const ValidationException(
        'BorderPrimitiveDraft.weight must be between 0 and 1000',
      );
    }
  }

  final String id;
  final String? sourceElementId;
  final String? sourceModelId;
  final BorderPrimitiveRole role;
  final BorderPrimitiveOrientation authoredOrientation;
  final int sequenceIndex;
  final BorderCornerTurn? cornerTurn;
  final int weight;
  final BorderPixelPos? _anchorPx;
  final Model3dVector3? anchorWorld;
  final int? animationIndex;
  final bool animationLoop;
  final double animationSpeed;
  final bool blocksMovement;
  final List<BorderGroundFootprint> groundFootprints;
  final List<BorderGroundSurface> groundSurfaces;
  final BorderTransformPolicy transforms;
  final BorderPrimitiveAssetMetrics? _currentMetrics;
  bool get isSpatial => sourceModelId != null;
  BorderVisualKind get visualKind =>
      isSpatial ? BorderVisualKind.model3d : BorderVisualKind.element;
  BorderPixelPos get anchorPx =>
      _anchorPx ??
      (throw const ValidationException(
        'A spatial Border primitive has no pixel anchor',
      ));
  BorderPrimitiveAssetMetrics get currentMetrics =>
      _currentMetrics ??
      (throw const ValidationException(
        'A spatial Border primitive has no pixel metrics',
      ));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPrimitiveDraft &&
          id == other.id &&
          sourceElementId == other.sourceElementId &&
          sourceModelId == other.sourceModelId &&
          role == other.role &&
          authoredOrientation == other.authoredOrientation &&
          sequenceIndex == other.sequenceIndex &&
          cornerTurn == other.cornerTurn &&
          weight == other.weight &&
          _anchorPx == other._anchorPx &&
          anchorWorld == other.anchorWorld &&
          animationIndex == other.animationIndex &&
          animationLoop == other.animationLoop &&
          animationSpeed == other.animationSpeed &&
          blocksMovement == other.blocksMovement &&
          _listsEqual(groundFootprints, other.groundFootprints) &&
          _listsEqual(groundSurfaces, other.groundSurfaces) &&
          transforms == other.transforms &&
          _currentMetrics == other._currentMetrics;

  @override
  int get hashCode => Object.hash(
    id,
    sourceElementId,
    sourceModelId,
    role,
    authoredOrientation,
    sequenceIndex,
    cornerTurn,
    weight,
    _anchorPx,
    anchorWorld,
    animationIndex,
    animationLoop,
    animationSpeed,
    blocksMovement,
    Object.hashAll(groundFootprints),
    Object.hashAll(groundSurfaces),
    transforms,
    _currentMetrics,
  );
}

/// Immutable published primitive referencing a content-addressed snapshot.
@immutable
final class BorderPublishedPrimitive {
  BorderPublishedPrimitive({
    required this.id,
    this.sourceElementId,
    this.sourceModelId,
    String? visualSnapshotId,
    required this.role,
    this.authoredOrientation = BorderPrimitiveOrientation.legacyAxis,
    this.sequenceIndex = 0,
    this.cornerTurn,
    required this.weight,
    BorderPixelPos? anchorPx,
    this.anchorWorld,
    this.animationIndex,
    this.animationLoop = true,
    this.animationSpeed = 1,
    this.blocksMovement = true,
    List<BorderGroundFootprint> groundFootprints = const [],
    List<BorderGroundSurface> groundSurfaces = const [],
    required this.transforms,
    BorderPrimitiveAssetMetrics? publishedMetrics,
  }) : groundFootprints = validatedBorderGroundFootprints(
         groundFootprints,
         sourceModelId,
       ),
       groundSurfaces = validatedBorderGroundSurfaces(
         groundSurfaces,
         sourceModelId,
       ),
       _anchorPx = anchorPx,
       _publishedMetrics = publishedMetrics,
       _visualSnapshotId = visualSnapshotId {
    _requireNonEmpty(id, 'BorderPublishedPrimitive.id');
    if (cornerTurn != null &&
        (sourceModelId == null || role != BorderPrimitiveRole.lineCorner)) {
      throw const ValidationException('Corner turn requires a spatial corner');
    }
    _validateSpatialBehavior(
      modelId: sourceModelId,
      animationIndex: animationIndex,
      animationLoop: animationLoop,
      animationSpeed: animationSpeed,
      blocksMovement: blocksMovement,
      sequenceIndex: sequenceIndex,
    );
    _validateVisualSource(
      sourceElementId,
      sourceModelId,
      anchorPx,
      anchorWorld,
      publishedMetrics,
      visualSnapshotId,
      true,
    );
    if (weight < 1 || weight > 1000) {
      throw const ValidationException(
        'BorderPublishedPrimitive.weight must be between 1 and 1000',
      );
    }
  }

  final String id;
  final String? sourceElementId;
  final String? sourceModelId;
  final String? _visualSnapshotId;
  final BorderPrimitiveRole role;
  final BorderPrimitiveOrientation authoredOrientation;
  final int sequenceIndex;
  final BorderCornerTurn? cornerTurn;
  final int weight;
  final BorderPixelPos? _anchorPx;
  final Model3dVector3? anchorWorld;
  final int? animationIndex;
  final bool animationLoop;
  final double animationSpeed;
  final bool blocksMovement;
  final List<BorderGroundFootprint> groundFootprints;
  final List<BorderGroundSurface> groundSurfaces;
  final BorderTransformPolicy transforms;
  final BorderPrimitiveAssetMetrics? _publishedMetrics;
  bool get isSpatial => sourceModelId != null;
  BorderVisualKind get visualKind =>
      isSpatial ? BorderVisualKind.model3d : BorderVisualKind.element;
  BorderPixelPos get anchorPx =>
      _anchorPx ??
      (throw const ValidationException(
        'A spatial Border primitive has no pixel anchor',
      ));
  BorderPrimitiveAssetMetrics get publishedMetrics =>
      _publishedMetrics ??
      (throw const ValidationException(
        'A spatial Border primitive has no pixel metrics',
      ));
  String get visualSnapshotId =>
      _visualSnapshotId ??
      (throw const ValidationException(
        'A spatial Border primitive uses a live model',
      ));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublishedPrimitive &&
          id == other.id &&
          sourceElementId == other.sourceElementId &&
          sourceModelId == other.sourceModelId &&
          _visualSnapshotId == other._visualSnapshotId &&
          role == other.role &&
          authoredOrientation == other.authoredOrientation &&
          sequenceIndex == other.sequenceIndex &&
          cornerTurn == other.cornerTurn &&
          weight == other.weight &&
          _anchorPx == other._anchorPx &&
          anchorWorld == other.anchorWorld &&
          animationIndex == other.animationIndex &&
          animationLoop == other.animationLoop &&
          animationSpeed == other.animationSpeed &&
          blocksMovement == other.blocksMovement &&
          _listsEqual(groundFootprints, other.groundFootprints) &&
          _listsEqual(groundSurfaces, other.groundSurfaces) &&
          transforms == other.transforms &&
          _publishedMetrics == other._publishedMetrics;

  @override
  int get hashCode => Object.hash(
    id,
    sourceElementId,
    sourceModelId,
    _visualSnapshotId,
    role,
    authoredOrientation,
    sequenceIndex,
    cornerTurn,
    weight,
    _anchorPx,
    anchorWorld,
    animationIndex,
    animationLoop,
    animationSpeed,
    blocksMovement,
    Object.hashAll(groundFootprints),
    Object.hashAll(groundSurfaces),
    transforms,
    _publishedMetrics,
  );
}

/// Optional editable Smart Tile ground band.
@immutable
final class BorderGroundDraft {
  BorderGroundDraft({
    required this.sourceSmartTilePresetId,
    required this.edgeBandCells,
  }) {
    _requireNonEmpty(
      sourceSmartTilePresetId,
      'BorderGroundDraft.sourceSmartTilePresetId',
    );
    _requirePositiveEdgeBand(edgeBandCells, 'BorderGroundDraft');
  }

  final String sourceSmartTilePresetId;
  final int edgeBandCells;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderGroundDraft &&
          sourceSmartTilePresetId == other.sourceSmartTilePresetId &&
          edgeBandCells == other.edgeBandCells;

  @override
  int get hashCode => Object.hash(sourceSmartTilePresetId, edgeBandCells);
}

/// Immutable published Smart Tile ground band with resolved visual snapshots.
@immutable
final class BorderPublishedGround {
  BorderPublishedGround({
    required this.sourceSmartTilePresetId,
    required this.edgeBandCells,
    required Map<BorderGroundVariantRole, String> visualSnapshotIdsByRole,
  }) : _visualSnapshotIdsByRole = _copyPublishedGroundSnapshots(
         visualSnapshotIdsByRole,
       ) {
    _requireNonEmpty(
      sourceSmartTilePresetId,
      'BorderPublishedGround.sourceSmartTilePresetId',
    );
    _requirePositiveEdgeBand(edgeBandCells, 'BorderPublishedGround');
  }

  final String sourceSmartTilePresetId;
  final int edgeBandCells;
  final Map<BorderGroundVariantRole, String> _visualSnapshotIdsByRole;

  Map<BorderGroundVariantRole, String> get visualSnapshotIdsByRole =>
      _visualSnapshotIdsByRole;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublishedGround &&
          sourceSmartTilePresetId == other.sourceSmartTilePresetId &&
          edgeBandCells == other.edgeBandCells &&
          _mapsEqual(_visualSnapshotIdsByRole, other._visualSnapshotIdsByRole);

  @override
  int get hashCode => Object.hash(
    sourceSmartTilePresetId,
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
    this.straightOnly = false,
    this.sequenceLength = 1,
    this.followContourDirection = false,
    this.replacesGround = false,
    this.masksGroundCells = false,
    this.groundBaseOffset = 0,
    required List<TPrimitive> primitives,
    required this.defaults,
    this.ground,
    this.categoryId,
    required this.sortOrder,
    this.jumpBehavior,
  }) : _primitives = List<TPrimitive>.unmodifiable(primitives) {
    _requireNonEmpty(name, 'BorderBlueprintDefinition.name');
    final category = categoryId;
    if (category != null) {
      _requireNonEmpty(category, 'BorderBlueprintDefinition.categoryId');
    }
    final kinds = _primitives
        .map(
          (primitive) => switch (primitive) {
            BorderPrimitiveDraft() => primitive.visualKind,
            BorderPublishedPrimitive() => primitive.visualKind,
            _ => throw const ValidationException(
              'Unknown Border primitive type',
            ),
          },
        )
        .toSet();
    if (kinds.length > 1 ||
        (kinds.contains(BorderVisualKind.model3d) && ground != null)) {
      throw const ValidationException(
        'A Border blueprint must use one visual dimension, without sprite ground in 3D',
      );
    }
    if (_primitives.any(
          (primitive) => switch (primitive) {
            BorderPrimitiveDraft() => primitive.groundFootprints.isNotEmpty,
            BorderPublishedPrimitive() => primitive.groundFootprints.isNotEmpty,
            _ => false,
          },
        ) &&
        !replacesGround) {
      throw const ValidationException(
        'Ground footprints require ground replacement',
      );
    }
    if (template == BorderBlueprintTemplate.horizontalFacade &&
        kinds.contains(BorderVisualKind.model3d)) {
      throw const ValidationException(
        'Horizontal facades require 2D element sources',
      );
    }
    if (straightOnly &&
        (template != BorderBlueprintTemplate.connectedLine ||
            !kinds.contains(BorderVisualKind.model3d))) {
      throw const ValidationException(
        'Straight-only Borders require a spatial connectedLine blueprint',
      );
    }
    if (sequenceLength < 1 ||
        sequenceLength > 9007199254740991 ||
        (sequenceLength > 1 &&
            (!straightOnly || !kinds.contains(BorderVisualKind.model3d)))) {
      throw const ValidationException(
        'Border sequences require a positive portable length and a spatial straight-only blueprint',
      );
    }
    for (final primitive in _primitives) {
      final index = switch (primitive) {
        BorderPrimitiveDraft() => primitive.sequenceIndex,
        BorderPublishedPrimitive() => primitive.sequenceIndex,
        _ => 0,
      };
      if (index >= sequenceLength) {
        throw const ValidationException(
          'Border sequence index exceeds its length',
        );
      }
    }
    if (followContourDirection &&
        (template != BorderBlueprintTemplate.connectedLine ||
            !kinds.contains(BorderVisualKind.model3d))) {
      throw const ValidationException(
        'Directed contours require a spatial connectedLine blueprint',
      );
    }
    if (replacesGround &&
        (template != BorderBlueprintTemplate.connectedLine ||
            !kinds.contains(BorderVisualKind.model3d))) {
      throw const ValidationException(
        'Ground replacement requires a spatial connectedLine blueprint',
      );
    }
    if (!groundBaseOffset.isFinite ||
        groundBaseOffset > 0 ||
        (groundBaseOffset != 0 && !replacesGround)) {
      throw const ValidationException(
        'Ground base offset must be finite, non-positive and require ground replacement',
      );
    }
    if (masksGroundCells &&
        (replacesGround ||
            template != BorderBlueprintTemplate.connectedLine ||
            !kinds.contains(BorderVisualKind.model3d))) {
      throw const ValidationException(
        'Cell ground masking requires a spatial connectedLine blueprint without ground lowering',
      );
    }
  }

  final String name;
  final BorderSignedInt64 previewSeed;
  final BorderBlueprintTemplate template;
  final bool straightOnly;
  final int sequenceLength;
  final bool followContourDirection;
  final bool replacesGround;
  final bool masksGroundCells;
  final double groundBaseOffset;
  final List<TPrimitive> _primitives;
  final BorderGenerationParams defaults;
  final TGround? ground;
  final String? categoryId;
  final int sortOrder;
  final BorderJumpBehavior? jumpBehavior;

  List<TPrimitive> get primitives => _primitives;
  bool get isSpatial => _primitives.any(
    (primitive) => switch (primitive) {
      BorderPrimitiveDraft() => primitive.isSpatial,
      BorderPublishedPrimitive() => primitive.isSpatial,
      _ => false,
    },
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderBlueprintDefinition &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          previewSeed == other.previewSeed &&
          template == other.template &&
          straightOnly == other.straightOnly &&
          sequenceLength == other.sequenceLength &&
          followContourDirection == other.followContourDirection &&
          replacesGround == other.replacesGround &&
          masksGroundCells == other.masksGroundCells &&
          groundBaseOffset == other.groundBaseOffset &&
          _listsEqual(_primitives, other._primitives) &&
          defaults == other.defaults &&
          ground == other.ground &&
          categoryId == other.categoryId &&
          sortOrder == other.sortOrder &&
          jumpBehavior == other.jumpBehavior;

  @override
  int get hashCode => Object.hash(
    runtimeType,
    name,
    previewSeed,
    template,
    straightOnly,
    sequenceLength,
    followContourDirection,
    replacesGround,
    masksGroundCells,
    groundBaseOffset,
    Object.hashAll(_primitives),
    defaults,
    ground,
    categoryId,
    sortOrder,
    jumpBehavior,
  );
}

typedef BorderBlueprintDraftDefinition =
    BorderBlueprintDefinition<BorderPrimitiveDraft, BorderGroundDraft>;
typedef BorderBlueprintPublishedDefinition =
    BorderBlueprintDefinition<BorderPublishedPrimitive, BorderPublishedGround>;

/// Editable state retained by every blueprint record.
@immutable
final class BorderBlueprintDraft {
  BorderBlueprintDraft({required this.baseRevision, required this.definition}) {
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
  BorderBlueprintRevision({required this.revision, required this.definition}) {
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

Map<BorderGroundVariantRole, String> _copyPublishedGroundSnapshots(
  Map<BorderGroundVariantRole, String> snapshots,
) {
  final result = Map<BorderGroundVariantRole, String>.from(snapshots);
  for (final role in standardBorderGroundVariantRoleOrder) {
    final snapshotId = result[role];
    if (snapshotId == null || snapshotId.isEmpty) {
      throw ValidationException(
        'BorderPublishedGround.visualSnapshotIdsByRole must contain '
        '${role.name}',
      );
    }
  }
  return Map<BorderGroundVariantRole, String>.unmodifiable(result);
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
