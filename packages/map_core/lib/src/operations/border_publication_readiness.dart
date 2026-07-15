import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';
import '../models/border_blueprint.dart';
import '../models/border_diagnostics.dart';
import '../models/border_materialization.dart';
import '../models/border_value_objects.dart';
import '../models/border_visual_snapshot.dart';
import '../models/project_manifest.dart';
import '../models/surface.dart';
import 'border_coverage.dart';
import 'border_rle_codec.dart';
import 'narrative_event_canonical_json.dart';

const List<int> _requiredQuarterTurns = <int>[0, 1, 2, 3];
final BigInt _maximumPortableJsonInteger = BigInt.parse('9007199254740991');
const List<BorderPrimitiveRole> _structuralRoles = <BorderPrimitiveRole>[
  BorderPrimitiveRole.structureLarge,
  BorderPrimitiveRole.structureMedium,
  BorderPrimitiveRole.filler,
];
final RegExp _candidateFingerprintPattern = RegExp(r'^sha256:[0-9a-f]{64}$');

/// Version of the canonical geometry and evidence-component contract.
const int borderCanonicalGalleryVersion = 1;

/// Stable cases that the editor must render for a publication gallery.
///
/// The accepted subset is template-specific. Keeping this vocabulary closed
/// prevents a caller from substituting arbitrary easy examples for the cases
/// that exercise the selected resolver family.
enum BorderCanonicalGalleryCase {
  longEdge,
  gentleCurve,
  sharpConvexCorner,
  sharpConcaveCorner,
  hole,
  smallIsland,
  sharpCorner,
  endpoint,
  opening,
}

/// Stable coverage components expected from one canonical sample.
enum BorderCanonicalCoverageComponent {
  primary,
  outerLoop,
  innerLoop,
  leadingStroke,
  trailingStroke,
}

String borderCanonicalGalleryCaseV1WireName(
  BorderCanonicalGalleryCase galleryCase,
) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => 'longEdge',
      BorderCanonicalGalleryCase.gentleCurve => 'gentleCurve',
      BorderCanonicalGalleryCase.sharpConvexCorner => 'sharpConvexCorner',
      BorderCanonicalGalleryCase.sharpConcaveCorner => 'sharpConcaveCorner',
      BorderCanonicalGalleryCase.hole => 'hole',
      BorderCanonicalGalleryCase.smallIsland => 'smallIsland',
      BorderCanonicalGalleryCase.sharpCorner => 'sharpCorner',
      BorderCanonicalGalleryCase.endpoint => 'endpoint',
      BorderCanonicalGalleryCase.opening => 'opening',
    };

String borderCanonicalCoverageComponentV1WireName(
  BorderCanonicalCoverageComponent component,
) =>
    switch (component) {
      BorderCanonicalCoverageComponent.primary => 'primary',
      BorderCanonicalCoverageComponent.outerLoop => 'outerLoop',
      BorderCanonicalCoverageComponent.innerLoop => 'innerLoop',
      BorderCanonicalCoverageComponent.leadingStroke => 'leadingStroke',
      BorderCanonicalCoverageComponent.trailingStroke => 'trailingStroke',
    };

/// Scalar coverage evidence produced by one canonical-gallery contour.
@immutable
final class BorderPublicationCoverageCheck {
  BorderPublicationCoverageCheck({
    required this.component,
    required this.longestContiguousGapPx,
    required this.maximumPairwiseOverlapPx,
    required this.gapTolerancePx,
    required this.maxOverlapPx,
  }) {
    if (longestContiguousGapPx < 0 ||
        maximumPairwiseOverlapPx < 0 ||
        gapTolerancePx < 0 ||
        maxOverlapPx < 0) {
      throw const ValidationException(
        'BorderPublicationCoverageCheck metrics must be non-negative',
      );
    }
    _requirePortableInteger(
      longestContiguousGapPx,
      'BorderPublicationCoverageCheck.longestContiguousGapPx',
    );
    _requirePortableInteger(
      maximumPairwiseOverlapPx,
      'BorderPublicationCoverageCheck.maximumPairwiseOverlapPx',
    );
    _requirePortableInteger(
      gapTolerancePx,
      'BorderPublicationCoverageCheck.gapTolerancePx',
    );
    _requirePortableInteger(
      maxOverlapPx,
      'BorderPublicationCoverageCheck.maxOverlapPx',
    );
  }

  factory BorderPublicationCoverageCheck.fromLoopAssessment({
    required BorderCanonicalCoverageComponent component,
    required BorderLoopCoverageAssessment assessment,
  }) =>
      BorderPublicationCoverageCheck(
        component: component,
        longestContiguousGapPx: assessment.longestContiguousGapPx,
        maximumPairwiseOverlapPx: assessment.maximumPairwiseOverlapPx,
        gapTolerancePx: assessment.gapTolerancePx,
        maxOverlapPx: assessment.maxOverlapPx,
      );

  final BorderCanonicalCoverageComponent component;
  final int longestContiguousGapPx;
  final int maximumPairwiseOverlapPx;
  final int gapTolerancePx;
  final int maxOverlapPx;

  bool get hasExcessiveGap => longestContiguousGapPx > gapTolerancePx;
  bool get hasExcessiveOverlap => maximumPairwiseOverlapPx > maxOverlapPx;
  bool get isWithinTolerance => !hasExcessiveGap && !hasExcessiveOverlap;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublicationCoverageCheck &&
          component == other.component &&
          longestContiguousGapPx == other.longestContiguousGapPx &&
          maximumPairwiseOverlapPx == other.maximumPairwiseOverlapPx &&
          gapTolerancePx == other.gapTolerancePx &&
          maxOverlapPx == other.maxOverlapPx;

  @override
  int get hashCode => Object.hash(
        component,
        longestContiguousGapPx,
        maximumPairwiseOverlapPx,
        gapTolerancePx,
        maxOverlapPx,
      );
}

/// One ordered structural sequence from a canonical-gallery pass.
@immutable
final class BorderPublicationStructuralRun {
  BorderPublicationStructuralRun({
    required this.id,
    required this.role,
    required this.quarterTurns,
    required this.passIndex,
    required List<String> primitiveIds,
  }) : _primitiveIds = List<String>.unmodifiable(primitiveIds) {
    _requireStableId(id, 'BorderPublicationStructuralRun.id');
    if (quarterTurns < 0 || quarterTurns > 3) {
      throw const ValidationException(
        'BorderPublicationStructuralRun.quarterTurns must be 0..3',
      );
    }
    if (passIndex < 0) {
      throw const ValidationException(
        'BorderPublicationStructuralRun.passIndex must be >= 0',
      );
    }
    _requirePortableInteger(
      passIndex,
      'BorderPublicationStructuralRun.passIndex',
    );
    for (var index = 0; index < _primitiveIds.length; index += 1) {
      _requireStableId(
        _primitiveIds[index],
        'BorderPublicationStructuralRun.primitiveIds[$index]',
      );
    }
  }

  final String id;
  final BorderPrimitiveRole role;
  final int quarterTurns;
  final int passIndex;
  final List<String> _primitiveIds;

  List<String> get primitiveIds => _primitiveIds;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublicationStructuralRun &&
          id == other.id &&
          role == other.role &&
          quarterTurns == other.quarterTurns &&
          passIndex == other.passIndex &&
          _listsEqual(_primitiveIds, other._primitiveIds);

  @override
  int get hashCode => Object.hash(
        id,
        role,
        quarterTurns,
        passIndex,
        Object.hashAll(_primitiveIds),
      );
}

/// Pure evidence from one neutral canonical-gallery sample.
@immutable
final class BorderPublicationGallerySample {
  BorderPublicationGallerySample({
    required this.galleryCase,
    required List<BorderPublicationCoverageCheck> coverageChecks,
    required List<BorderPublicationStructuralRun> structuralRuns,
  })  : _coverageChecks =
            List<BorderPublicationCoverageCheck>.unmodifiable(coverageChecks),
        _structuralRuns =
            List<BorderPublicationStructuralRun>.unmodifiable(structuralRuns) {
    final coverageComponents = <BorderCanonicalCoverageComponent>{};
    for (final check in _coverageChecks) {
      if (!coverageComponents.add(check.component)) {
        throw ValidationException(
          'BorderPublicationGallerySample.coverageChecks must not contain '
          'duplicate component: '
          '${borderCanonicalCoverageComponentV1WireName(check.component)}',
        );
      }
    }
    _rejectDuplicateIds(
      _structuralRuns.map((run) => run.id),
      'BorderPublicationGallerySample.structuralRuns',
    );
  }

  final BorderCanonicalGalleryCase galleryCase;
  final List<BorderPublicationCoverageCheck> _coverageChecks;
  final List<BorderPublicationStructuralRun> _structuralRuns;

  List<BorderPublicationCoverageCheck> get coverageChecks => _coverageChecks;
  List<BorderPublicationStructuralRun> get structuralRuns => _structuralRuns;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublicationGallerySample &&
          galleryCase == other.galleryCase &&
          _listsEqual(_coverageChecks, other._coverageChecks) &&
          _listsEqual(_structuralRuns, other._structuralRuns);

  @override
  int get hashCode => Object.hash(
        galleryCase,
        Object.hashAll(_coverageChecks),
        Object.hashAll(_structuralRuns),
      );
}

/// Candidate-bound evidence generated from the neutral canonical gallery.
@immutable
final class BorderPublicationGalleryReport {
  BorderPublicationGalleryReport({
    required this.resolverVersion,
    required this.canonicalGalleryVersion,
    required this.candidateFingerprint,
    required List<BorderPublicationGallerySample> samples,
  }) : _samples = List<BorderPublicationGallerySample>.unmodifiable(samples) {
    if (resolverVersion < 1) {
      throw const ValidationException(
        'BorderPublicationGalleryReport.resolverVersion must be >= 1',
      );
    }
    if (canonicalGalleryVersion < 1) {
      throw const ValidationException(
        'BorderPublicationGalleryReport.canonicalGalleryVersion must be >= 1',
      );
    }
    _requirePortableInteger(
      resolverVersion,
      'BorderPublicationGalleryReport.resolverVersion',
    );
    _requirePortableInteger(
      canonicalGalleryVersion,
      'BorderPublicationGalleryReport.canonicalGalleryVersion',
    );
    if (!_candidateFingerprintPattern.hasMatch(candidateFingerprint)) {
      throw const ValidationException(
        'BorderPublicationGalleryReport.candidateFingerprint must be a '
        'sha256-prefixed lowercase hexadecimal digest',
      );
    }
  }

  final int resolverVersion;
  final int canonicalGalleryVersion;
  final String candidateFingerprint;
  final List<BorderPublicationGallerySample> _samples;

  List<BorderPublicationGallerySample> get samples => _samples;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublicationGalleryReport &&
          resolverVersion == other.resolverVersion &&
          canonicalGalleryVersion == other.canonicalGalleryVersion &&
          candidateFingerprint == other.candidateFingerprint &&
          _listsEqual(_samples, other._samples);

  @override
  int get hashCode => Object.hash(
        resolverVersion,
        canonicalGalleryVersion,
        candidateFingerprint,
        Object.hashAll(_samples),
      );
}

/// Computes the exact candidate identity a canonical-gallery report attests.
///
/// Display metadata is included as well as every generative field and source
/// reference. Integer values are represented as decimal strings so the digest
/// stays identical on Dart VM and JavaScript even for signed-64 coordinates.
String computeBorderPublicationCandidateFingerprint({
  required String blueprintId,
  required BorderBlueprintPublishedDefinition definition,
  required int resolverVersion,
  int canonicalGalleryVersion = borderCanonicalGalleryVersion,
}) {
  _requireStableId(blueprintId, 'blueprintId');
  if (resolverVersion < 1 || canonicalGalleryVersion < 1) {
    throw const ValidationException(
      'Publication fingerprint versions must be >= 1',
    );
  }
  _requirePortableInteger(resolverVersion, 'resolverVersion');
  _requirePortableInteger(
    canonicalGalleryVersion,
    'canonicalGalleryVersion',
  );
  return 'sha256:${narrativeEventCanonicalSha256(
    _publicationCandidateProjection(
      blueprintId,
      definition,
      resolverVersion: resolverVersion,
      canonicalGalleryVersion: canonicalGalleryVersion,
    ),
  )}';
}

/// Deterministic publication gate for one candidate blueprint definition.
@immutable
final class BorderPublicationReadinessResult {
  const BorderPublicationReadinessResult._({
    required this.diagnosticReport,
  });

  final BorderDiagnosticsReport diagnosticReport;

  bool get canPublish => !diagnosticReport.hasErrors;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorderPublicationReadinessResult &&
          diagnosticReport == other.diagnosticReport;

  @override
  int get hashCode => diagnosticReport.hashCode;
}

/// Validates all pure-core requirements for publishing a Border revision.
///
/// File existence and content hashing remain caller supplied through
/// [snapshotIntegrity]. Perspective, lighting, contrast, and scale heuristics
/// deliberately remain editor-only and never affect this blocking gate.
BorderPublicationReadinessResult assessBorderPublicationReadiness({
  required String blueprintId,
  required BorderBlueprintPublishedDefinition definition,
  required int resolverVersion,
  required ProjectManifest project,
  required List<BorderVisualSnapshot> visualSnapshots,
  required Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
  required BorderPublicationGalleryReport canonicalGalleryReport,
}) {
  _requireStableId(blueprintId, 'blueprintId');
  if (resolverVersion < 1) {
    throw const ValidationException('resolverVersion must be >= 1');
  }
  _requirePortableInteger(resolverVersion, 'resolverVersion');
  final diagnostics = <BorderDiagnostic>[];

  _diagnoseDuplicatePrimitiveIds(blueprintId, definition, diagnostics);
  _diagnoseTemplatePrimitiveRoles(blueprintId, definition, diagnostics);
  _diagnoseTemplateGround(blueprintId, definition, diagnostics);
  _diagnoseProjectReferences(
    blueprintId,
    definition,
    project,
    diagnostics,
  );
  _diagnoseRequiredRolesAndOrientations(
    blueprintId,
    definition,
    diagnostics,
  );
  _diagnosePrimitiveMetrics(blueprintId, definition, diagnostics);
  _diagnoseSnapshotReferences(
    blueprintId,
    definition,
    visualSnapshots,
    snapshotIntegrity,
    diagnostics,
  );
  _diagnoseGroundCompleteness(
    blueprintId,
    definition,
    project,
    diagnostics,
  );
  _diagnoseCanonicalGallery(
    blueprintId,
    definition,
    resolverVersion,
    canonicalGalleryReport,
    diagnostics,
  );

  return BorderPublicationReadinessResult._(
    diagnosticReport: BorderDiagnosticsReport(diagnostics: diagnostics),
  );
}

void _diagnoseTemplatePrimitiveRoles(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  List<BorderDiagnostic> diagnostics,
) {
  final allowedRoles = borderAllowedPrimitiveRolesForTemplate(
    definition.template,
  );
  for (final primitive in definition.primitives) {
    if (allowedRoles.contains(primitive.role)) continue;
    diagnostics.add(_diagnostic(
      code: 'border.publication.role_not_supported_by_template',
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'primitiveId': primitive.id,
        'role': borderPrimitiveRoleV1WireName(primitive.role),
        'template': _templateV1WireName(definition.template),
      },
      action: 'border.action.remove_incompatible_role',
    ));
  }
}

/// Keeps publication capability aligned with the V1 resolver families.
///
/// A Surface ground band is defined by organic region geometry. Linear
/// resolvers deliberately have no equivalent ground contract, so allowing it
/// through publication would create a revision that cannot be resolved.
void _diagnoseTemplateGround(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  List<BorderDiagnostic> diagnostics,
) {
  if (definition.ground == null) return;
  switch (definition.template) {
    case BorderBlueprintTemplate.organicEdge:
      return;
    case BorderBlueprintTemplate.masonryLine:
    case BorderBlueprintTemplate.postAndRailLine:
      diagnostics.add(_diagnostic(
        code: 'border.publication.linear_ground_not_supported',
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: blueprintId,
        parameters: <String, Object?>{
          'template': _templateV1WireName(definition.template),
        },
        action: 'border.action.remove_ground_from_linear_blueprint',
      ));
  }
}

/// Returns the exact immutable primitive-role contract for [template].
///
/// Editor pickers and publication validation must share this matrix so a role
/// offered during authoring can never become invalid only at publication.
Set<BorderPrimitiveRole> borderAllowedPrimitiveRolesForTemplate(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => const <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
          BorderPrimitiveRole.filler,
          BorderPrimitiveRole.accent,
          BorderPrimitiveRole.surfacePatch,
          BorderPrimitiveRole.outerAccent,
        },
      BorderBlueprintTemplate.masonryLine => const <BorderPrimitiveRole>{
          BorderPrimitiveRole.structureLarge,
          BorderPrimitiveRole.structureMedium,
          BorderPrimitiveRole.filler,
          BorderPrimitiveRole.post,
          BorderPrimitiveRole.accent,
          BorderPrimitiveRole.surfacePatch,
        },
      BorderBlueprintTemplate.postAndRailLine => const <BorderPrimitiveRole>{
          BorderPrimitiveRole.post,
          BorderPrimitiveRole.span,
          BorderPrimitiveRole.accent,
          BorderPrimitiveRole.surfacePatch,
        },
    };

void _diagnoseProjectReferences(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  ProjectManifest project,
  List<BorderDiagnostic> diagnostics,
) {
  final elementIds = <String>{
    for (final element in project.elements) element.id,
  };
  for (final primitive in definition.primitives) {
    if (elementIds.contains(primitive.sourceElementId)) continue;
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.source_element_missing',
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'primitiveId': primitive.id,
        'sourceElementId': primitive.sourceElementId,
      },
      action: 'border.action.select_existing_source_element',
    ));
  }
  final ground = definition.ground;
  if (ground != null &&
      project.surfaceCatalog.presetById(ground.sourceSurfacePresetId) == null) {
    diagnostics.add(_diagnostic(
      code: 'border.blueprint.source_surface_preset_missing',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'sourceSurfacePresetId': ground.sourceSurfacePresetId,
      },
      action: 'border.action.select_existing_surface_preset',
    ));
  }
}

void _diagnoseDuplicatePrimitiveIds(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  List<BorderDiagnostic> diagnostics,
) {
  final seen = <String>{};
  final reported = <String>{};
  for (final primitive in definition.primitives) {
    if (!seen.add(primitive.id) && reported.add(primitive.id)) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.duplicate_primitive_id',
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.assign_unique_primitive_ids',
      ));
    }
  }
}

void _diagnoseRequiredRolesAndOrientations(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  List<BorderDiagnostic> diagnostics,
) {
  switch (definition.template) {
    case BorderBlueprintTemplate.organicEdge:
    case BorderBlueprintTemplate.masonryLine:
      final eligible = definition.primitives
          .where((primitive) => _structuralRoles.contains(primitive.role))
          .toList(growable: false);
      if (eligible.isEmpty) {
        diagnostics.add(_diagnostic(
          code: 'border.publication.required_role_missing',
          scope: BorderDiagnosticScope.blueprint,
          blueprintId: blueprintId,
          parameters: <String, Object?>{
            'roles': <String>[
              for (final role in _structuralRoles)
                borderPrimitiveRoleV1WireName(role),
            ],
          },
          action: 'border.action.add_required_structural_primitive',
        ));
      } else {
        _diagnoseOrientationGroup(
          blueprintId: blueprintId,
          groupName: 'structure',
          primitives: eligible,
          diagnostics: diagnostics,
        );
      }
    case BorderBlueprintTemplate.postAndRailLine:
      for (final role in <BorderPrimitiveRole>[
        BorderPrimitiveRole.post,
        BorderPrimitiveRole.span,
      ]) {
        final eligible = definition.primitives
            .where((primitive) => primitive.role == role)
            .toList(growable: false);
        if (eligible.isEmpty) {
          diagnostics.add(_diagnostic(
            code: 'border.publication.required_role_missing',
            scope: BorderDiagnosticScope.blueprint,
            blueprintId: blueprintId,
            parameters: <String, Object?>{
              'roles': <String>[borderPrimitiveRoleV1WireName(role)],
            },
            action: 'border.action.add_required_line_primitive',
          ));
        } else {
          _diagnoseOrientationGroup(
            blueprintId: blueprintId,
            groupName: borderPrimitiveRoleV1WireName(role),
            primitives: eligible,
            diagnostics: diagnostics,
          );
        }
      }
  }
}

void _diagnoseOrientationGroup({
  required String blueprintId,
  required String groupName,
  required List<BorderPublishedPrimitive> primitives,
  required List<BorderDiagnostic> diagnostics,
}) {
  final available = <int>{
    for (final primitive in primitives)
      ...primitive.transforms.allowedQuarterTurns,
  };
  for (final quarterTurns in _requiredQuarterTurns) {
    if (available.contains(quarterTurns)) continue;
    diagnostics.add(_diagnostic(
      code: 'border.publication.orientation_missing',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'orientation': borderCardinalDirectionV1WireName(
          _directionForQuarterTurns(quarterTurns),
        ),
        'quarterTurns': quarterTurns,
        'roleGroup': groupName,
      },
      action: 'border.action.add_or_authorize_required_orientation',
    ));
  }
}

BorderCardinalDirection _directionForQuarterTurns(int quarterTurns) =>
    switch (quarterTurns) {
      0 => BorderCardinalDirection.east,
      1 => BorderCardinalDirection.south,
      2 => BorderCardinalDirection.west,
      3 => BorderCardinalDirection.north,
      _ => throw const ValidationException(
          'Publication orientation quarterTurns must be 0..3',
        ),
    };

void _diagnosePrimitiveMetrics(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  List<BorderDiagnostic> diagnostics,
) {
  for (final primitive in definition.primitives) {
    final metrics = primitive.publishedMetrics;
    if (!_insideAsset(primitive.anchorPx, metrics) ||
        !_insideAsset(metrics.defaultAnchorPx, metrics)) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.anchor_outside_asset',
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.place_anchor_inside_asset',
      ));
    }

    bool? hasStructuralOccupancy;
    try {
      final expectedLength = checkedBorderRleCellCount(
        width: metrics.pixelSize.width,
        height: metrics.pixelSize.height,
        path: r'$.publishedMetrics.pixelSize',
      );
      hasStructuralOccupancy = borderRleMaskHasTrue(
        metrics.occupancyMaskRle,
        expectedLength: expectedLength,
        path: r'$.publishedMetrics.occupancyMaskRle',
      );
    } on FormatException {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.occupancy_mask_invalid',
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.reanalyze_asset_occupancy',
      ));
    }
    if (hasStructuralOccupancy == false) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.occupancy_mask_empty',
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'primitiveId': primitive.id},
        action: 'border.action.choose_nonempty_asset',
      ));
    }
  }
}

void _diagnoseSnapshotReferences(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  List<BorderVisualSnapshot> visualSnapshots,
  Map<String, BorderVisualSnapshotIntegrity> snapshotIntegrity,
  List<BorderDiagnostic> diagnostics,
) {
  final snapshotIdCounts = <String, int>{};
  for (final snapshot in visualSnapshots) {
    snapshotIdCounts.update(
      snapshot.id,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  final duplicateSnapshotIds = snapshotIdCounts.entries
      .where((entry) => entry.value > 1)
      .map((entry) => entry.key)
      .toList(growable: false)
    ..sort(compareNarrativeEventUtf16);
  final duplicateSnapshotIdSet = duplicateSnapshotIds.toSet();
  if (duplicateSnapshotIds.isNotEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.duplicate_visual_snapshot_id',
      scope: BorderDiagnosticScope.visualSnapshot,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'snapshotIds': duplicateSnapshotIds,
      },
      action: 'border.action.remove_duplicate_visual_snapshots',
    ));
  }
  final snapshotsById = <String, BorderVisualSnapshot>{};
  for (final snapshot in visualSnapshots) {
    if (!duplicateSnapshotIdSet.contains(snapshot.id)) {
      snapshotsById[snapshot.id] = snapshot;
    }
  }
  final referencedIds = <String>{
    for (final primitive in definition.primitives) primitive.visualSnapshotId,
    if (definition.ground case final ground?)
      ...ground.visualSnapshotIdsByRole.values,
  }.toList(growable: false)
    ..sort(compareNarrativeEventUtf16);
  for (final snapshotId in referencedIds) {
    if (duplicateSnapshotIdSet.contains(snapshotId)) continue;
    final snapshot = snapshotsById[snapshotId];
    if (snapshot == null) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.visual_snapshot_missing',
        scope: BorderDiagnosticScope.visualSnapshot,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'snapshotId': snapshotId},
        action: 'border.action.restore_or_republish_snapshot',
      ));
      continue;
    }
    final integrity = snapshotIntegrity[snapshotId];
    if (integrity == null ||
        integrity.snapshotId != snapshotId ||
        !integrity.isValid) {
      diagnostics.add(_diagnostic(
        code: 'border.blueprint.visual_snapshot_invalid',
        scope: BorderDiagnosticScope.visualSnapshot,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'snapshotId': snapshotId},
        action: 'border.action.restore_or_republish_snapshot',
      ));
    }
  }

  for (final primitive in definition.primitives) {
    if (duplicateSnapshotIdSet.contains(primitive.visualSnapshotId)) continue;
    final snapshot = snapshotsById[primitive.visualSnapshotId];
    if (snapshot == null) continue;
    final frameSize = snapshot.frames.first.sourceRectPx;
    final metricsSize = primitive.publishedMetrics.pixelSize;
    if (frameSize.width != metricsSize.width ||
        frameSize.height != metricsSize.height) {
      diagnostics.add(_diagnostic(
        code: 'border.publication.snapshot_metrics_mismatch',
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{
          'primitiveId': primitive.id,
          'snapshotId': primitive.visualSnapshotId,
          'metricsWidth': metricsSize.width,
          'metricsHeight': metricsSize.height,
          'snapshotWidth': frameSize.width,
          'snapshotHeight': frameSize.height,
        },
        action: 'border.action.reanalyze_and_snapshot_asset',
      ));
    }
  }
}

void _diagnoseGroundCompleteness(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  ProjectManifest project,
  List<BorderDiagnostic> diagnostics,
) {
  final ground = definition.ground;
  if (ground == null) return;
  final missing = <String>[
    for (final role in standardSurfaceVariantRoleOrder)
      if (ground.visualSnapshotIdsByRole[role]?.isNotEmpty != true)
        _surfaceRoleV1WireName(role),
  ];
  if (missing.isNotEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.ground_surface_roles_incomplete',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'roles': missing},
      action: 'border.action.resolve_all_surface_role_snapshots',
    ));
  }

  final preset =
      project.surfaceCatalog.presetById(ground.sourceSurfacePresetId);
  if (preset == null) return;
  final unresolvedRoles = <String>[];
  final missingAnimationIds = <String>{};
  for (final role in standardSurfaceVariantRoleOrder) {
    final animationId = _resolveGroundSurfaceAnimationId(preset, role);
    if (animationId == null) {
      unresolvedRoles.add(_surfaceRoleV1WireName(role));
      continue;
    }
    if (project.surfaceCatalog.animationById(animationId) == null) {
      unresolvedRoles.add(_surfaceRoleV1WireName(role));
      missingAnimationIds.add(animationId);
    }
  }
  if (unresolvedRoles.isEmpty) return;
  final sortedAnimationIds = missingAnimationIds.toList(growable: false)
    ..sort(compareNarrativeEventUtf16);
  diagnostics.add(_diagnostic(
    code: 'border.publication.ground_surface_unresolvable',
    scope: BorderDiagnosticScope.blueprint,
    blueprintId: blueprintId,
    parameters: <String, Object?>{
      'sourceSurfacePresetId': ground.sourceSurfacePresetId,
      'roles': unresolvedRoles,
      'missingAnimationIds': sortedAnimationIds,
    },
    action: 'border.action.resolve_surface_role_animations',
  ));
}

String? _resolveGroundSurfaceAnimationId(
  ProjectSurfacePreset preset,
  SurfaceVariantRole role,
) {
  final exact = preset.animationIdForRole(role)?.trim();
  if (exact != null && exact.isNotEmpty) return exact;

  final isolated =
      preset.animationIdForRole(SurfaceVariantRole.isolated)?.trim();
  if (isolated != null && isolated.isNotEmpty) return isolated;

  for (final ref in preset.variantAnimations.refs) {
    final animationId = ref.animationId.trim();
    if (animationId.isNotEmpty) return animationId;
  }
  return null;
}

void _diagnoseCanonicalGallery(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition,
  int resolverVersion,
  BorderPublicationGalleryReport report,
  List<BorderDiagnostic> diagnostics,
) {
  if (report.resolverVersion != resolverVersion ||
      report.canonicalGalleryVersion != borderCanonicalGalleryVersion) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.canonical_gallery_version_mismatch',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'expectedResolverVersion': resolverVersion,
        'galleryResolverVersion': report.resolverVersion,
        'expectedCanonicalGalleryVersion': borderCanonicalGalleryVersion,
        'galleryCanonicalGalleryVersion': report.canonicalGalleryVersion,
      },
      action: 'border.action.regenerate_canonical_gallery',
    ));
  }
  final expectedFingerprint = computeBorderPublicationCandidateFingerprint(
    blueprintId: blueprintId,
    definition: definition,
    resolverVersion: resolverVersion,
  );
  if (report.candidateFingerprint != expectedFingerprint) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.canonical_gallery_stale',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'candidateFingerprint': expectedFingerprint,
        'galleryCandidateFingerprint': report.candidateFingerprint,
      },
      action: 'border.action.regenerate_canonical_gallery',
    ));
  }

  if (report.samples.isEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.canonical_gallery_missing',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      action: 'border.action.generate_canonical_gallery',
    ));
    return;
  }
  final samples = List<BorderPublicationGallerySample>.of(report.samples)
    ..sort(
      (left, right) => _galleryCaseRank(left.galleryCase).compareTo(
        _galleryCaseRank(right.galleryCase),
      ),
    );
  final expectedCases = borderCanonicalGalleryCasesForTemplate(
    definition.template,
  );
  final expectedCaseSet = expectedCases.toSet();
  final caseCounts = <BorderCanonicalGalleryCase, int>{};
  for (final sample in samples) {
    caseCounts.update(
      sample.galleryCase,
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  final duplicateCases = <String>[
    for (final galleryCase in BorderCanonicalGalleryCase.values)
      if ((caseCounts[galleryCase] ?? 0) > 1)
        borderCanonicalGalleryCaseV1WireName(galleryCase),
  ];
  if (duplicateCases.isNotEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.canonical_gallery_case_duplicate',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{'cases': duplicateCases},
      action: 'border.action.regenerate_canonical_gallery',
    ));
  }
  final missingCases = <String>[
    for (final galleryCase in expectedCases)
      if (!caseCounts.containsKey(galleryCase))
        borderCanonicalGalleryCaseV1WireName(galleryCase),
  ];
  final unexpectedCases = <String>[
    for (final galleryCase in BorderCanonicalGalleryCase.values)
      if (caseCounts.containsKey(galleryCase) &&
          !expectedCaseSet.contains(galleryCase))
        borderCanonicalGalleryCaseV1WireName(galleryCase),
  ];
  if (missingCases.isNotEmpty || unexpectedCases.isNotEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.canonical_gallery_incomplete',
      scope: BorderDiagnosticScope.blueprint,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'missingCases': missingCases,
        'unexpectedCases': unexpectedCases,
      },
      action: 'border.action.regenerate_canonical_gallery',
    ));
  }

  for (final sample in samples) {
    final sampleId = borderCanonicalGalleryCaseV1WireName(sample.galleryCase);
    if (!expectedCaseSet.contains(sample.galleryCase)) continue;
    final coverage = List<BorderPublicationCoverageCheck>.of(
      sample.coverageChecks,
    )..sort(
        (left, right) => _coverageComponentRank(left.component).compareTo(
          _coverageComponentRank(right.component),
        ),
      );
    if (coverage.isEmpty) {
      diagnostics.add(_diagnostic(
        code: 'border.publication.canonical_sample_coverage_missing',
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: blueprintId,
        parameters: <String, Object?>{'sampleId': sampleId},
        action: 'border.action.regenerate_canonical_sample',
      ));
    }
    final expectedCoverage = borderCanonicalCoverageComponentsForCase(
      template: definition.template,
      galleryCase: sample.galleryCase,
    );
    final actualCoverage = <BorderCanonicalCoverageComponent>{
      for (final check in coverage) check.component,
    };
    final expectedCoverageSet = expectedCoverage.toSet();
    final missingCoverage = <String>[
      for (final component in expectedCoverage)
        if (!actualCoverage.contains(component))
          borderCanonicalCoverageComponentV1WireName(component),
    ];
    final unexpectedCoverage = <String>[
      for (final component in BorderCanonicalCoverageComponent.values)
        if (actualCoverage.contains(component) &&
            !expectedCoverageSet.contains(component))
          borderCanonicalCoverageComponentV1WireName(component),
    ];
    if (missingCoverage.isNotEmpty || unexpectedCoverage.isNotEmpty) {
      diagnostics.add(_diagnostic(
        code: 'border.publication.canonical_sample_coverage_incomplete',
        scope: BorderDiagnosticScope.blueprint,
        blueprintId: blueprintId,
        parameters: <String, Object?>{
          'sampleId': sampleId,
          'missingComponents': missingCoverage,
          'unexpectedComponents': unexpectedCoverage,
        },
        action: 'border.action.regenerate_canonical_sample',
      ));
    }
    for (final check in coverage) {
      final coverageComponent =
          borderCanonicalCoverageComponentV1WireName(check.component);
      final expectedGapTolerance = definition.defaults.gapTolerancePx;
      final expectedMaxOverlap = definition.defaults.maxOverlapPx;
      if (check.gapTolerancePx != expectedGapTolerance ||
          check.maxOverlapPx != expectedMaxOverlap) {
        diagnostics.add(_diagnostic(
          code: 'border.publication.canonical_coverage_parameters_mismatch',
          scope: BorderDiagnosticScope.blueprint,
          blueprintId: blueprintId,
          parameters: <String, Object?>{
            'sampleId': sampleId,
            'coverageComponent': coverageComponent,
            'assessedGapTolerancePx': check.gapTolerancePx,
            'expectedGapTolerancePx': expectedGapTolerance,
            'assessedMaxOverlapPx': check.maxOverlapPx,
            'expectedMaxOverlapPx': expectedMaxOverlap,
          },
          action: 'border.action.regenerate_canonical_gallery',
        ));
      }
      if (check.longestContiguousGapPx > expectedGapTolerance) {
        diagnostics.add(_diagnostic(
          code: 'border.publication.coverage_gap_exceeded',
          scope: BorderDiagnosticScope.blueprint,
          blueprintId: blueprintId,
          parameters: <String, Object?>{
            'sampleId': sampleId,
            'coverageComponent': coverageComponent,
            'longestContiguousGapPx': check.longestContiguousGapPx,
            'gapTolerancePx': expectedGapTolerance,
          },
          action: 'border.action.fix_canonical_coverage_gap',
        ));
      }
      if (check.maximumPairwiseOverlapPx > expectedMaxOverlap) {
        diagnostics.add(_diagnostic(
          code: 'border.publication.coverage_overlap_exceeded',
          severity: BorderDiagnosticSeverity.warning,
          scope: BorderDiagnosticScope.blueprint,
          blueprintId: blueprintId,
          parameters: <String, Object?>{
            'sampleId': sampleId,
            'coverageComponent': coverageComponent,
            'maximumPairwiseOverlapPx': check.maximumPairwiseOverlapPx,
            'maxOverlapPx': expectedMaxOverlap,
          },
          action: 'border.action.review_canonical_overlap',
        ));
      }
    }

    final runs = List<BorderPublicationStructuralRun>.of(sample.structuralRuns)
      ..sort((left, right) => compareNarrativeEventUtf16(left.id, right.id));
    for (final run in runs) {
      _diagnoseStructuralRun(
        blueprintId: blueprintId,
        sampleId: sampleId,
        run: run,
        definition: definition,
        diagnostics: diagnostics,
      );
    }
  }
}

void _diagnoseStructuralRun({
  required String blueprintId,
  required String sampleId,
  required BorderPublicationStructuralRun run,
  required BorderBlueprintPublishedDefinition definition,
  required List<BorderDiagnostic> diagnostics,
}) {
  final expectedPassIndex = _structuralPassIndex(
    definition.template,
    run.role,
  );
  if (expectedPassIndex == null || run.passIndex != expectedPassIndex) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.gallery_run_contract_invalid',
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'sampleId': sampleId,
        'runId': run.id,
        'role': borderPrimitiveRoleV1WireName(run.role),
        'quarterTurns': run.quarterTurns,
        'passIndex': run.passIndex,
        'expectedPassIndex': expectedPassIndex,
      },
      action: 'border.action.regenerate_canonical_gallery',
    ));
    return;
  }
  final runEligiblePrimitiveIds = <String>{
    for (final primitive in definition.primitives)
      if (primitive.role == run.role &&
          primitive.transforms.allowedQuarterTurns.contains(run.quarterTurns))
        primitive.id,
  };
  if (runEligiblePrimitiveIds.isEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.gallery_run_eligibility_empty',
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'sampleId': sampleId,
        'runId': run.id,
        'role': borderPrimitiveRoleV1WireName(run.role),
        'quarterTurns': run.quarterTurns,
      },
      action: 'border.action.regenerate_canonical_gallery',
    ));
    return;
  }
  final unknown = run.primitiveIds
      .where((id) => !runEligiblePrimitiveIds.contains(id))
      .toSet()
      .toList(growable: false)
    ..sort(compareNarrativeEventUtf16);
  if (unknown.isNotEmpty) {
    diagnostics.add(_diagnostic(
      code: 'border.publication.gallery_primitive_unknown',
      scope: BorderDiagnosticScope.primitive,
      blueprintId: blueprintId,
      parameters: <String, Object?>{
        'sampleId': sampleId,
        'runId': run.id,
        'primitiveIds': unknown,
      },
      action: 'border.action.regenerate_canonical_gallery',
    ));
    return;
  }

  if (runEligiblePrimitiveIds.length >= 2) {
    final repeatStart = _firstRepeatedRunStart(run.primitiveIds, 4);
    if (repeatStart != null) {
      diagnostics.add(_diagnostic(
        code: 'border.publication.repetition_run',
        severity: BorderDiagnosticSeverity.warning,
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{
          'sampleId': sampleId,
          'runId': run.id,
          'startIndex': repeatStart,
          'length': 4,
          'primitiveId': run.primitiveIds[repeatStart],
        },
        action: 'border.action.review_structural_repetition',
      ));
    }
  }
  if (runEligiblePrimitiveIds.length >= 3) {
    final lowVarietyStart = _firstLowVarietyWindowStart(
      run.primitiveIds,
      windowLength: 12,
      minimumDistinct: 3,
    );
    if (lowVarietyStart != null) {
      diagnostics.add(_diagnostic(
        code: 'border.publication.repetition_variety',
        severity: BorderDiagnosticSeverity.warning,
        scope: BorderDiagnosticScope.primitive,
        blueprintId: blueprintId,
        parameters: <String, Object?>{
          'sampleId': sampleId,
          'runId': run.id,
          'startIndex': lowVarietyStart,
          'windowLength': 12,
          'minimumDistinct': 3,
        },
        action: 'border.action.review_structural_variety',
      ));
    }
  }
}

int? _firstRepeatedRunStart(List<String> values, int length) {
  if (values.length < length) return null;
  var start = 0;
  for (var index = 1; index < values.length; index += 1) {
    if (values[index] != values[index - 1]) start = index;
    if (index - start + 1 >= length) return start;
  }
  return null;
}

int? _firstLowVarietyWindowStart(
  List<String> values, {
  required int windowLength,
  required int minimumDistinct,
}) {
  for (var start = 0; start + windowLength <= values.length; start += 1) {
    final distinct = <String>{};
    for (var index = start; index < start + windowLength; index += 1) {
      distinct.add(values[index]);
    }
    if (distinct.length < minimumDistinct) return start;
  }
  return null;
}

bool _insideAsset(
  BorderPixelPos point,
  BorderPrimitiveAssetMetrics metrics,
) =>
    point.x >= 0 &&
    point.y >= 0 &&
    point.x < metrics.pixelSize.width &&
    point.y < metrics.pixelSize.height;

/// Returns the immutable, exact canonical evidence set for [template].
List<BorderCanonicalGalleryCase> borderCanonicalGalleryCasesForTemplate(
  BorderBlueprintTemplate template,
) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.gentleCurve,
          BorderCanonicalGalleryCase.sharpConvexCorner,
          BorderCanonicalGalleryCase.sharpConcaveCorner,
          BorderCanonicalGalleryCase.hole,
          BorderCanonicalGalleryCase.smallIsland,
        ],
      BorderBlueprintTemplate.masonryLine => const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.sharpCorner,
          BorderCanonicalGalleryCase.endpoint,
        ],
      BorderBlueprintTemplate.postAndRailLine =>
        const <BorderCanonicalGalleryCase>[
          BorderCanonicalGalleryCase.longEdge,
          BorderCanonicalGalleryCase.sharpCorner,
          BorderCanonicalGalleryCase.endpoint,
          BorderCanonicalGalleryCase.opening,
        ],
    };

/// Returns the exact immutable coverage components required for one sample.
///
/// [galleryCase] must belong to the canonical set for [template].
List<BorderCanonicalCoverageComponent>
    borderCanonicalCoverageComponentsForCase({
  required BorderBlueprintTemplate template,
  required BorderCanonicalGalleryCase galleryCase,
}) {
  if (!borderCanonicalGalleryCasesForTemplate(template).contains(galleryCase)) {
    throw const ValidationException(
      'Canonical gallery case does not belong to the selected template',
    );
  }
  return switch (galleryCase) {
    BorderCanonicalGalleryCase.hole => const <BorderCanonicalCoverageComponent>[
        BorderCanonicalCoverageComponent.outerLoop,
        BorderCanonicalCoverageComponent.innerLoop,
      ],
    BorderCanonicalGalleryCase.opening =>
      const <BorderCanonicalCoverageComponent>[
        BorderCanonicalCoverageComponent.leadingStroke,
        BorderCanonicalCoverageComponent.trailingStroke,
      ],
    _ => const <BorderCanonicalCoverageComponent>[
        BorderCanonicalCoverageComponent.primary,
      ],
  };
}

int _galleryCaseRank(BorderCanonicalGalleryCase galleryCase) =>
    switch (galleryCase) {
      BorderCanonicalGalleryCase.longEdge => 0,
      BorderCanonicalGalleryCase.gentleCurve => 1,
      BorderCanonicalGalleryCase.sharpConvexCorner => 2,
      BorderCanonicalGalleryCase.sharpConcaveCorner => 3,
      BorderCanonicalGalleryCase.hole => 4,
      BorderCanonicalGalleryCase.smallIsland => 5,
      BorderCanonicalGalleryCase.sharpCorner => 6,
      BorderCanonicalGalleryCase.endpoint => 7,
      BorderCanonicalGalleryCase.opening => 8,
    };

int _coverageComponentRank(BorderCanonicalCoverageComponent component) =>
    switch (component) {
      BorderCanonicalCoverageComponent.primary => 0,
      BorderCanonicalCoverageComponent.outerLoop => 1,
      BorderCanonicalCoverageComponent.innerLoop => 2,
      BorderCanonicalCoverageComponent.leadingStroke => 3,
      BorderCanonicalCoverageComponent.trailingStroke => 4,
    };

int? _structuralPassIndex(
  BorderBlueprintTemplate template,
  BorderPrimitiveRole role,
) =>
    switch ((template, role)) {
      (
        BorderBlueprintTemplate.organicEdge ||
            BorderBlueprintTemplate.masonryLine,
        BorderPrimitiveRole.structureLarge,
      ) =>
        0,
      (
        BorderBlueprintTemplate.organicEdge ||
            BorderBlueprintTemplate.masonryLine,
        BorderPrimitiveRole.structureMedium,
      ) =>
        1,
      (
        BorderBlueprintTemplate.organicEdge ||
            BorderBlueprintTemplate.masonryLine,
        BorderPrimitiveRole.filler,
      ) =>
        2,
      (BorderBlueprintTemplate.postAndRailLine, BorderPrimitiveRole.span) => 0,
      (BorderBlueprintTemplate.postAndRailLine, BorderPrimitiveRole.post) => 1,
      _ => null,
    };

Object _publicationCandidateProjection(
  String blueprintId,
  BorderBlueprintPublishedDefinition definition, {
  required int resolverVersion,
  required int canonicalGalleryVersion,
}) {
  final primitives = <Map<String, Object?>>[
    for (final primitive in definition.primitives)
      _publishedPrimitiveProjection(primitive),
  ]..sort(
      (left, right) => compareNarrativeEventUtf16(
        canonicalizeNarrativeEventJson(left),
        canonicalizeNarrativeEventJson(right),
      ),
    );
  final ground = definition.ground;
  return <String, Object?>{
    'contract': 'border-publication-candidate-v1',
    'resolverVersion': resolverVersion.toString(),
    'canonicalGalleryVersion': canonicalGalleryVersion.toString(),
    'blueprintId': blueprintId,
    'name': definition.name,
    'categoryId': definition.categoryId,
    'sortOrder': definition.sortOrder.toString(),
    'previewSeed': definition.previewSeed.toString(),
    'template': _templateV1WireName(definition.template),
    'defaults': <String, Object?>{
      'irregularityPermille':
          definition.defaults.irregularityPermille.toString(),
      'detailDensityPermille':
          definition.defaults.detailDensityPermille.toString(),
      'variationPermille': definition.defaults.variationPermille.toString(),
      'maxOverlapPx': definition.defaults.maxOverlapPx.toString(),
      'gapTolerancePx': definition.defaults.gapTolerancePx.toString(),
      'depthRows': definition.defaults.depthRows.toString(),
    },
    'primitives': primitives,
    'ground': ground == null
        ? null
        : <String, Object?>{
            'sourceSurfacePresetId': ground.sourceSurfacePresetId,
            'edgeBandCells': ground.edgeBandCells.toString(),
            'visualSnapshotIdsByRole': <String, Object?>{
              for (final role in standardSurfaceVariantRoleOrder)
                _surfaceRoleV1WireName(role):
                    ground.visualSnapshotIdsByRole[role],
            },
          },
  };
}

Map<String, Object?> _publishedPrimitiveProjection(
  BorderPublishedPrimitive primitive,
) {
  final metrics = primitive.publishedMetrics;
  return <String, Object?>{
    'id': primitive.id,
    'sourceElementId': primitive.sourceElementId,
    'visualSnapshotId': primitive.visualSnapshotId,
    'role': borderPrimitiveRoleV1WireName(primitive.role),
    'weight': primitive.weight.toString(),
    'anchorPx': <String, Object?>{
      'x': primitive.anchorPx.x.toString(),
      'y': primitive.anchorPx.y.toString(),
    },
    'transforms': <String, Object?>{
      'allowFlipX': primitive.transforms.allowFlipX,
      'allowedQuarterTurns': primitive.transforms.allowedQuarterTurns,
    },
    'publishedMetrics': <String, Object?>{
      'assetFingerprint': metrics.assetFingerprint,
      'pixelSize': <String, Object?>{
        'width': metrics.pixelSize.width.toString(),
        'height': metrics.pixelSize.height.toString(),
      },
      'opaqueBounds': <String, Object?>{
        'x': metrics.opaqueBounds.x.toString(),
        'y': metrics.opaqueBounds.y.toString(),
        'width': metrics.opaqueBounds.width.toString(),
        'height': metrics.opaqueBounds.height.toString(),
      },
      'defaultAnchorPx': <String, Object?>{
        'x': metrics.defaultAnchorPx.x.toString(),
        'y': metrics.defaultAnchorPx.y.toString(),
      },
      'occupancyMaskRle': metrics.occupancyMaskRle,
    },
  };
}

String _templateV1WireName(BorderBlueprintTemplate template) =>
    switch (template) {
      BorderBlueprintTemplate.organicEdge => 'organicEdge',
      BorderBlueprintTemplate.masonryLine => 'masonryLine',
      BorderBlueprintTemplate.postAndRailLine => 'postAndRailLine',
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

BorderDiagnostic _diagnostic({
  required String code,
  BorderDiagnosticSeverity severity = BorderDiagnosticSeverity.error,
  required BorderDiagnosticScope scope,
  required String blueprintId,
  Map<String, Object?> parameters = const <String, Object?>{},
  required String action,
}) =>
    BorderDiagnostic(
      code: code,
      severity: severity,
      phase: BorderDiagnosticPhase.publication,
      scope: scope,
      blueprintId: blueprintId,
      parameters: parameters,
      suggestedAction: action,
    );

void _requireStableId(String value, String field) {
  if (value.trim().isEmpty || value != value.trim()) {
    throw ValidationException('$field must be nonblank and already trimmed');
  }
}

void _requirePortableInteger(int value, String field) {
  if (BigInt.from(value).abs() > _maximumPortableJsonInteger) {
    throw ValidationException(
        '$field must fit the portable JSON integer range');
  }
}

void _rejectDuplicateIds(Iterable<String> values, String field) {
  final seen = <String>{};
  for (final value in values) {
    if (!seen.add(value)) {
      throw ValidationException('$field must not contain duplicate id: $value');
    }
  }
}

bool _listsEqual<T>(List<T> left, List<T> right) {
  if (identical(left, right)) return true;
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
