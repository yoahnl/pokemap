import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import 'border_value_objects.dart';
import 'geometry.dart';
import 'surface.dart';

final RegExp _snapshotIdPattern = RegExp(
  r'border-snapshot-sha256:[0-9a-f]{64}',
);
final RegExp _sha256FingerprintPattern = RegExp(r'sha256:[0-9a-f]{64}');

/// Pixel-art transform persisted for one resolved Border placement.
@immutable
final class BorderSpriteTransform {
  BorderSpriteTransform({required this.quarterTurns, required this.flipX}) {
    if (quarterTurns < 0 || quarterTurns > 3) {
      throw const ValidationException(
        'BorderSpriteTransform.quarterTurns must be between 0 and 3',
      );
    }
  }

  final int quarterTurns;
  final bool flipX;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderSpriteTransform &&
          quarterTurns == other.quarterTurns &&
          flipX == other.flipX;

  @override
  int get hashCode => Object.hash(quarterTurns, flipX);
}

/// Fixed V1 draw bands for resolved Border placements.
enum BorderDrawBand {
  outerAccent,
  structure,
  innerFinish,
  accent,
}

/// Explicit persisted V1 ordering. This deliberately does not use enum index.
const List<BorderDrawBand> borderDrawBandV1Order = <BorderDrawBand>[
  BorderDrawBand.outerAccent,
  BorderDrawBand.structure,
  BorderDrawBand.innerFinish,
  BorderDrawBand.accent,
];

/// Returns the stable persisted V1 index for [band].
int borderDrawBandV1Index(BorderDrawBand band) => switch (band) {
      BorderDrawBand.outerAccent => 0,
      BorderDrawBand.structure => 1,
      BorderDrawBand.innerFinish => 2,
      BorderDrawBand.accent => 3,
    };

extension BorderDrawBandStableV1Index on BorderDrawBand {
  /// Stable persisted V1 index independent of enum declaration mechanics.
  int get stableV1Index => borderDrawBandV1Index(this);
}

/// Complete structured ordering key persisted with a resolved placement.
@immutable
final class BorderStableOrderKey implements Comparable<BorderStableOrderKey> {
  BorderStableOrderKey({
    required this.drawBandIndex,
    required this.anchorRowMajor,
    required this.passIndex,
    required this.rank,
    required this.ordinalLocal,
    required this.slotKey,
  }) {
    _requireNonNegative(
      drawBandIndex,
      'BorderStableOrderKey.drawBandIndex',
    );
    _requireNonNegative(
      anchorRowMajor,
      'BorderStableOrderKey.anchorRowMajor',
    );
    _requireNonNegative(passIndex, 'BorderStableOrderKey.passIndex');
    _requireNonNegative(rank, 'BorderStableOrderKey.rank');
    _requireNonNegative(ordinalLocal, 'BorderStableOrderKey.ordinalLocal');
    _requireStableId(slotKey, 'BorderStableOrderKey.slotKey');
  }

  final int drawBandIndex;
  final int anchorRowMajor;
  final int passIndex;
  final int rank;
  final int ordinalLocal;
  final String slotKey;

  @override
  int compareTo(BorderStableOrderKey other) {
    var result = drawBandIndex.compareTo(other.drawBandIndex);
    if (result != 0) {
      return result;
    }
    result = anchorRowMajor.compareTo(other.anchorRowMajor);
    if (result != 0) {
      return result;
    }
    result = passIndex.compareTo(other.passIndex);
    if (result != 0) {
      return result;
    }
    result = rank.compareTo(other.rank);
    if (result != 0) {
      return result;
    }
    result = ordinalLocal.compareTo(other.ordinalLocal);
    if (result != 0) {
      return result;
    }
    return slotKey.compareTo(other.slotKey);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderStableOrderKey &&
          drawBandIndex == other.drawBandIndex &&
          anchorRowMajor == other.anchorRowMajor &&
          passIndex == other.passIndex &&
          rank == other.rank &&
          ordinalLocal == other.ordinalLocal &&
          slotKey == other.slotKey;

  @override
  int get hashCode => Object.hash(
        drawBandIndex,
        anchorRowMajor,
        passIndex,
        rank,
        ordinalLocal,
        slotKey,
      );
}

/// One final immutable visual placement consumed by editor and runtime.
@immutable
final class BorderResolvedPlacement {
  BorderResolvedPlacement({
    required this.id,
    required this.slotKey,
    required this.primitiveId,
    required this.visualSnapshotId,
    required GridPos anchorCell,
    required this.topLeftWorldPx,
    required this.opaqueWorldBoundsPx,
    required this.transform,
    required this.drawBand,
    required this.stableOrderKey,
  }) : anchorCell = GridPos(x: anchorCell.x, y: anchorCell.y) {
    _requireStableId(id, 'BorderResolvedPlacement.id');
    _requireStableId(slotKey, 'BorderResolvedPlacement.slotKey');
    _requireStableId(primitiveId, 'BorderResolvedPlacement.primitiveId');
    _requireSnapshotId(
      visualSnapshotId,
      'BorderResolvedPlacement.visualSnapshotId',
    );
    _validatePlacementInternals(this);
  }

  final String id;
  final String slotKey;
  final String primitiveId;
  final String visualSnapshotId;
  final GridPos anchorCell;
  final BorderPixelPos topLeftWorldPx;
  final BorderPixelRect opaqueWorldBoundsPx;
  final BorderSpriteTransform transform;
  final BorderDrawBand drawBand;
  final BorderStableOrderKey stableOrderKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderResolvedPlacement &&
          id == other.id &&
          slotKey == other.slotKey &&
          primitiveId == other.primitiveId &&
          visualSnapshotId == other.visualSnapshotId &&
          anchorCell == other.anchorCell &&
          topLeftWorldPx == other.topLeftWorldPx &&
          opaqueWorldBoundsPx == other.opaqueWorldBoundsPx &&
          transform == other.transform &&
          drawBand == other.drawBand &&
          stableOrderKey == other.stableOrderKey;

  @override
  int get hashCode => Object.hash(
        id,
        slotKey,
        primitiveId,
        visualSnapshotId,
        anchorCell,
        topLeftWorldPx,
        opaqueWorldBoundsPx,
        transform,
        drawBand,
        stableOrderKey,
      );
}

/// One final Surface cell consumed from persisted Border materialization.
@immutable
final class BorderResolvedGroundCell {
  BorderResolvedGroundCell({
    required this.x,
    required this.y,
    required this.visualSnapshotId,
    required this.resolvedRole,
  }) {
    _requireSnapshotId(
      visualSnapshotId,
      'BorderResolvedGroundCell.visualSnapshotId',
    );
  }

  final int x;
  final int y;
  final String visualSnapshotId;
  final SurfaceVariantRole resolvedRole;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderResolvedGroundCell &&
          x == other.x &&
          y == other.y &&
          visualSnapshotId == other.visualSnapshotId &&
          resolvedRole == other.resolvedRole;

  @override
  int get hashCode => Object.hash(x, y, visualSnapshotId, resolvedRole);
}

/// Canonical hashes for each independently assessable resolution input.
@immutable
final class BorderInputFingerprints {
  BorderInputFingerprints({
    required this.blueprint,
    required this.geometryAndSeed,
    required this.parameters,
    required this.overrides,
    required this.keepOutRegions,
    required this.mapContext,
    required this.visualSnapshots,
  }) {
    _requireSha256(blueprint, 'BorderInputFingerprints.blueprint');
    _requireSha256(
      geometryAndSeed,
      'BorderInputFingerprints.geometryAndSeed',
    );
    _requireSha256(parameters, 'BorderInputFingerprints.parameters');
    _requireSha256(overrides, 'BorderInputFingerprints.overrides');
    _requireSha256(
      keepOutRegions,
      'BorderInputFingerprints.keepOutRegions',
    );
    _requireSha256(mapContext, 'BorderInputFingerprints.mapContext');
    _requireSha256(
      visualSnapshots,
      'BorderInputFingerprints.visualSnapshots',
    );
  }

  final String blueprint;
  final String geometryAndSeed;
  final String parameters;
  final String overrides;
  final String keepOutRegions;
  final String mapContext;
  final String visualSnapshots;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderInputFingerprints &&
          blueprint == other.blueprint &&
          geometryAndSeed == other.geometryAndSeed &&
          parameters == other.parameters &&
          overrides == other.overrides &&
          keepOutRegions == other.keepOutRegions &&
          mapContext == other.mapContext &&
          visualSnapshots == other.visualSnapshots;

  @override
  int get hashCode => Object.hash(
        blueprint,
        geometryAndSeed,
        parameters,
        overrides,
        keepOutRegions,
        mapContext,
        visualSnapshots,
      );
}

/// Persisted evidence that identifies a resolver run and its exact output.
@immutable
final class BorderResolutionReceipt {
  BorderResolutionReceipt({
    required this.resolverVersion,
    required this.blueprintRevision,
    required this.components,
    required this.inputFingerprint,
    required this.outputFingerprint,
  }) {
    if (resolverVersion < 1) {
      throw const ValidationException(
        'BorderResolutionReceipt.resolverVersion must be >= 1',
      );
    }
    if (blueprintRevision < 1) {
      throw const ValidationException(
        'BorderResolutionReceipt.blueprintRevision must be >= 1',
      );
    }
    _requireSha256(
      inputFingerprint,
      'BorderResolutionReceipt.inputFingerprint',
    );
    _requireSha256(
      outputFingerprint,
      'BorderResolutionReceipt.outputFingerprint',
    );
  }

  final int resolverVersion;
  final int blueprintRevision;
  final BorderInputFingerprints components;
  final String inputFingerprint;
  final String outputFingerprint;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderResolutionReceipt &&
          resolverVersion == other.resolverVersion &&
          blueprintRevision == other.blueprintRevision &&
          components == other.components &&
          inputFingerprint == other.inputFingerprint &&
          outputFingerprint == other.outputFingerprint;

  @override
  int get hashCode => Object.hash(
        resolverVersion,
        blueprintRevision,
        components,
        inputFingerprint,
        outputFingerprint,
      );
}

/// Final persisted outputs. List order is the runtime drawing contract.
@immutable
final class BorderMaterialization {
  BorderMaterialization({
    required this.receipt,
    required List<BorderResolvedGroundCell> ground,
    required List<BorderResolvedPlacement> placements,
  })  : _ground = List<BorderResolvedGroundCell>.unmodifiable(ground),
        _placements = List<BorderResolvedPlacement>.unmodifiable(placements) {
    if (_ground.isEmpty && _placements.isEmpty) {
      throw const ValidationException(
        'BorderMaterialization must contain ground or placements',
      );
    }
    _validateGround(_ground);
    _validatePlacements(_placements);
  }

  final BorderResolutionReceipt receipt;
  final List<BorderResolvedGroundCell> _ground;
  final List<BorderResolvedPlacement> _placements;

  List<BorderResolvedGroundCell> get ground => _ground;

  List<BorderResolvedPlacement> get placements => _placements;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderMaterialization &&
          receipt == other.receipt &&
          _listsEqual(_ground, other._ground) &&
          _listsEqual(_placements, other._placements);

  @override
  int get hashCode => Object.hash(
        receipt,
        Object.hashAll(_ground),
        Object.hashAll(_placements),
      );
}

/// Caller-supplied file and metadata integrity for one immutable snapshot.
@immutable
final class BorderVisualSnapshotIntegrity {
  BorderVisualSnapshotIntegrity({
    required this.snapshotId,
    required this.metadataValid,
    required this.filesPresent,
    required this.contentFingerprintMatches,
  }) {
    _requireSnapshotId(
      snapshotId,
      'BorderVisualSnapshotIntegrity.snapshotId',
    );
  }

  final String snapshotId;
  final bool metadataValid;
  final bool filesPresent;
  final bool contentFingerprintMatches;

  bool get isValid =>
      metadataValid && filesPresent && contentFingerprintMatches;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderVisualSnapshotIntegrity &&
          snapshotId == other.snapshotId &&
          metadataValid == other.metadataValid &&
          filesPresent == other.filesPresent &&
          contentFingerprintMatches == other.contentFingerprintMatches;

  @override
  int get hashCode => Object.hash(
        snapshotId,
        metadataValid,
        filesPresent,
        contentFingerprintMatches,
      );
}

enum BorderMaterializationState {
  fresh,
  stale,
  unmaterialized,
  invalid,
}

enum BorderStalenessReason {
  blueprintNewer,
  blueprintMissing,
  geometryOrSeedChanged,
  parametersChanged,
  overridesChanged,
  keepOutRegionsChanged,
  mapContextChanged,
  resolverNewer,
  visualSnapshotMissingOrCorrupt,
  outputAltered,
}

/// Already-assessed materialization state.
///
/// Computing this state belongs to a later pure operation. This model only
/// rejects combinations that contradict the approved state precedence.
@immutable
final class BorderMaterializationFreshness {
  BorderMaterializationFreshness({
    required this.state,
    required Set<BorderStalenessReason> reasons,
    required this.isRenderable,
    required this.canRegenerate,
  }) : _reasons = Set<BorderStalenessReason>.unmodifiable(reasons) {
    _validateFreshness(this);
  }

  final BorderMaterializationState state;
  final Set<BorderStalenessReason> _reasons;
  final bool isRenderable;
  final bool canRegenerate;

  Set<BorderStalenessReason> get reasons => _reasons;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderMaterializationFreshness &&
          state == other.state &&
          _setsEqual(_reasons, other._reasons) &&
          isRenderable == other.isRenderable &&
          canRegenerate == other.canRegenerate;

  @override
  int get hashCode => Object.hash(
        state,
        Object.hashAllUnordered(_reasons),
        isRenderable,
        canRegenerate,
      );
}

void _validateGround(List<BorderResolvedGroundCell> ground) {
  final coordinates = <(int, int)>{};
  BorderResolvedGroundCell? previous;
  for (final cell in ground) {
    if (!coordinates.add((cell.x, cell.y))) {
      throw ValidationException(
        'BorderMaterialization.ground contains duplicate coordinates: '
        '(${cell.x}, ${cell.y})',
      );
    }
    final earlier = previous;
    if (earlier != null && _compareGroundRowMajor(earlier, cell) > 0) {
      throw const ValidationException(
        'BorderMaterialization.ground must be ordered row-major',
      );
    }
    previous = cell;
  }
}

int _compareGroundRowMajor(
  BorderResolvedGroundCell first,
  BorderResolvedGroundCell second,
) {
  final row = first.y.compareTo(second.y);
  return row != 0 ? row : first.x.compareTo(second.x);
}

void _validatePlacements(List<BorderResolvedPlacement> placements) {
  final ids = <String>{};
  final slotKeys = <String>{};
  BorderStableOrderKey? previousOrderKey;
  for (final placement in placements) {
    _validatePlacementInternals(placement);
    if (!ids.add(placement.id)) {
      throw ValidationException(
        'BorderMaterialization.placements contains duplicate id: '
        '${placement.id}',
      );
    }
    if (!slotKeys.add(placement.slotKey)) {
      throw ValidationException(
        'BorderMaterialization.placements contains duplicate slotKey: '
        '${placement.slotKey}',
      );
    }
    final earlier = previousOrderKey;
    if (earlier != null && earlier.compareTo(placement.stableOrderKey) > 0) {
      throw const ValidationException(
        'BorderMaterialization.placements must be nondecreasing by '
        'stableOrderKey',
      );
    }
    previousOrderKey = placement.stableOrderKey;
  }
}

void _validatePlacementInternals(BorderResolvedPlacement placement) {
  if (placement.slotKey != placement.stableOrderKey.slotKey) {
    throw const ValidationException(
      'BorderResolvedPlacement.slotKey must match stableOrderKey.slotKey',
    );
  }
  if (borderDrawBandV1Index(placement.drawBand) !=
      placement.stableOrderKey.drawBandIndex) {
    throw const ValidationException(
      'BorderResolvedPlacement.drawBand must match stableOrderKey index',
    );
  }
}

void _validateFreshness(BorderMaterializationFreshness freshness) {
  final shouldBeRenderable =
      freshness.state == BorderMaterializationState.fresh ||
          freshness.state == BorderMaterializationState.stale;
  if (freshness.isRenderable != shouldBeRenderable) {
    throw const ValidationException(
      'BorderMaterializationFreshness.isRenderable contradicts state',
    );
  }

  switch (freshness.state) {
    case BorderMaterializationState.fresh:
      if (freshness.reasons.isNotEmpty) {
        throw const ValidationException(
          'Fresh Border materialization must not have staleness reasons',
        );
      }
    case BorderMaterializationState.stale:
      if (freshness.reasons.isEmpty) {
        throw const ValidationException(
          'Stale Border materialization must have a staleness reason',
        );
      }
      if (freshness.reasons.contains(BorderStalenessReason.outputAltered)) {
        throw const ValidationException(
          'Invalidating reasons require invalid materialization state',
        );
      }
      if (freshness.reasons.contains(
            BorderStalenessReason.visualSnapshotMissingOrCorrupt,
          ) &&
          freshness.canRegenerate) {
        throw const ValidationException(
          'Missing current-input snapshots prevent Border regeneration',
        );
      }
    case BorderMaterializationState.unmaterialized:
      if (freshness.reasons.isNotEmpty) {
        throw const ValidationException(
          'Unmaterialized Border state must not have staleness reasons',
        );
      }
    case BorderMaterializationState.invalid:
      break;
  }

  if (freshness.reasons.contains(BorderStalenessReason.blueprintMissing) &&
      freshness.canRegenerate) {
    throw const ValidationException(
      'Missing Border blueprint cannot be regenerated',
    );
  }
}

void _requireNonNegative(int value, String field) {
  if (value < 0) {
    throw ValidationException('$field must be >= 0');
  }
}

void _requireStableId(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
}

void _requireSnapshotId(String value, String field) {
  if (!_hasExactMatch(_snapshotIdPattern, value)) {
    throw ValidationException(
      '$field must use border-snapshot-sha256:<64 lowercase hex>',
    );
  }
}

void _requireSha256(String value, String field) {
  if (!_hasExactMatch(_sha256FingerprintPattern, value)) {
    throw ValidationException('$field must use sha256:<64 lowercase hex>');
  }
}

bool _hasExactMatch(RegExp pattern, String value) {
  final match = pattern.matchAsPrefix(value);
  return match != null && match.end == value.length;
}

bool _listsEqual<T>(List<T> first, List<T> second) {
  if (identical(first, second)) {
    return true;
  }
  if (first.length != second.length) {
    return false;
  }
  for (var index = 0; index < first.length; index += 1) {
    if (first[index] != second[index]) {
      return false;
    }
  }
  return true;
}

bool _setsEqual<T>(Set<T> first, Set<T> second) =>
    first.length == second.length && first.containsAll(second);
